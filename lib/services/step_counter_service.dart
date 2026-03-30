import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device step counter for **patients** (Android / iOS). Not supported on web.
///
/// The OS keeps updating the hardware step counter while the app is closed.
/// This service reconnects on resume and can run a periodic Android task to
/// sync [users/{uid}/daily_steps].
class StepCounterService {
  StepCounterService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _prefsDay = 'step_counter_calendar_day';
  static const _prefsBaseline = 'step_counter_baseline_steps';

  StreamSubscription<StepCount>? _subscription;
  Timer? _syncDebounce;
  String? _uid;

  /// Latest step count for today (best effort; resets when the calendar day changes).
  final ValueNotifier<int> todaySteps = ValueNotifier<int>(0);

  /// `null` = OK; non-null = user-facing hint (permission, unsupported, error).
  final ValueNotifier<String?> statusMessage = ValueNotifier<String?>(null);

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Call when auth is known so we can sync to `users/{uid}/daily_steps/{date}`.
  void setUserId(String? uid) {
    _uid = uid;
  }

  Future<bool> _ensureActivityPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final result = await Permission.activityRecognition.request();
      return result.isGranted;
    }
    return true;
  }

  /// Updates prefs from raw device steps; optionally writes Firestore immediately
  /// (used by background sync). Returns today's delta for the UI.
  static Future<int> ingestRawSteps(
    int rawSteps,
    String? uid, {
    bool syncFirestoreNow = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final storedDay = prefs.getString(_prefsDay);
    var baseline = prefs.getInt(_prefsBaseline) ?? 0;

    if (storedDay != day) {
      baseline = rawSteps;
      await prefs.setString(_prefsDay, day);
      await prefs.setInt(_prefsBaseline, baseline);
    }

    final delta = rawSteps - baseline;
    final steps = delta < 0 ? 0 : delta;

    if (syncFirestoreNow && uid != null && uid.isNotEmpty) {
      await _writeFirestore(uid, day, steps);
    }
    return steps;
  }

  static Future<void> _writeFirestore(String uid, String day, int steps) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_steps')
          .doc(day)
          .set(
        {
          'steps': steps,
          'date': day,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  /// Called from Android [Workmanager] while the app process may be in the background.
  /// Reads one sample from the step sensor and syncs Firestore (needs signed-in user).
  static Future<void> backgroundIngestForUid(String uid) async {
    if (!isSupported || uid.isEmpty) return;
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.status;
      if (!status.isGranted) return;
    }

    final completer = Completer<int>();
    StreamSubscription<StepCount>? sub;
    sub = Pedometer.stepCountStream.listen(
      (e) {
        if (!completer.isCompleted) completer.complete(e.steps);
      },
      onError: (Object e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    try {
      final raw = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => -1,
      );
      if (raw < 0) return;
      await ingestRawSteps(raw, uid, syncFirestoreNow: true);
    } catch (_) {
      // Permission/sensor errors in background — skip.
    } finally {
      await sub.cancel();
    }
  }

  Future<void> start() async {
    stop();
    if (!isSupported) {
      statusMessage.value =
          'Step counting is available on the Android and iOS apps.';
      todaySteps.value = 0;
      return;
    }
    final ok = await _ensureActivityPermission();
    if (!ok) {
      statusMessage.value =
          'Activity permission is off. Enable it in system settings to see steps.';
      todaySteps.value = 0;
      return;
    }
    statusMessage.value = null;

    try {
      _subscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (Object e) {
          statusMessage.value = 'Could not read steps: $e';
        },
      );
    } catch (e) {
      statusMessage.value = 'Steps unavailable: $e';
    }
  }

  /// Re-subscribe so the next sensor reading includes steps taken while the app was away.
  Future<void> refresh() async {
    stop();
    await start();
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _syncDebounce?.cancel();
    _syncDebounce = null;
  }

  void dispose() {
    stop();
    todaySteps.dispose();
    statusMessage.dispose();
  }

  String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _onStepCount(StepCount event) async {
    final delta = await ingestRawSteps(event.steps, _uid, syncFirestoreNow: false);
    todaySteps.value = delta;
    _scheduleFirestoreSync();
  }

  void _scheduleFirestoreSync() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;

    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 2), () async {
      final day = _todayKey();
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('daily_steps')
            .doc(day)
            .set(
          {
            'steps': todaySteps.value,
            'date': day,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    });
  }
}

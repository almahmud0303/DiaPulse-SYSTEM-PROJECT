import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
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
  static final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  static const _prefsDay = 'step_counter_calendar_day';
  static const _prefsBaseline = 'step_counter_baseline_steps';
  static const _prefsFirstReadingDone = 'step_counter_first_reading_done';

  StreamSubscription<StepCount>? _subscription;
  Timer? _syncDebounce;
  String? _uid;
  bool _firstReadingDone = false;

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

  /// Updates prefs from raw device steps; optionally syncs cloud stores immediately
  /// (used by background sync). Returns today's delta for the UI.
  static Future<int> ingestRawSteps(
    int rawSteps,
    String? uid, {
    bool syncNow = false,
    int knownTodaySteps = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final storedDay = prefs.getString(_prefsDay);
    final hadFirstReading = prefs.getBool(_prefsFirstReadingDone) ?? false;
    var baseline = prefs.getInt(_prefsBaseline) ?? 0;

    if (storedDay != day) {
      final adjustedBaseline = rawSteps - (knownTodaySteps < 0 ? 0 : knownTodaySteps);
      baseline = adjustedBaseline < 0 ? 0 : adjustedBaseline;
      await prefs.setString(_prefsDay, day);
      await prefs.setInt(_prefsBaseline, baseline);
      await prefs.setBool(_prefsFirstReadingDone, false);
    } else if (!hadFirstReading) {
      baseline = rawSteps;
      await prefs.setInt(_prefsBaseline, baseline);
      await prefs.setBool(_prefsFirstReadingDone, true);
    }

    final delta = rawSteps - baseline;
    final steps = delta < 0 ? 0 : delta;

    if (syncNow && uid != null && uid.isNotEmpty) {
      await _writeCloud(uid, day, steps);
    }
    return steps;
  }

  static Future<void> _writeCloud(String uid, String day, int steps) async {
    await Future.wait<void>([
      _writeFirestore(uid, day, steps),
      _writeRealtimeDatabase(uid, day, steps),
    ]);
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

  static Future<void> _writeRealtimeDatabase(String uid, String day, int steps) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _realtimeDb.ref('users/$uid/daily_steps/$day');
      await ref.update({
        'steps': steps,
        'date': day,
        'updatedAt': ts,
      });
    } catch (_) {}
  }

  static Future<int> _readTodayStepsFromCloud(String uid) async {
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final snap = await _realtimeDb.ref('users/$uid/daily_steps/$day/steps').get();
      final value = snap.value;
      if (value is num) return value.toInt();
    } catch (_) {}

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_steps')
          .doc(day)
          .get();
      final data = doc.data();
      final value = data?['steps'];
      if (value is num) return value.toInt();
    } catch (_) {}

    return 0;
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
      final knownTodaySteps = await _readTodayStepsFromCloud(uid);
      await ingestRawSteps(
        raw,
        uid,
        syncNow: true,
        knownTodaySteps: knownTodaySteps,
      );
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
    statusMessage.value = 'Initializing step counter...';

    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      final cloudSteps = await _readTodayStepsFromCloud(uid);
      if (cloudSteps > todaySteps.value) {
        todaySteps.value = cloudSteps;
      }
    }

    try {
      _subscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (Object e) {
          statusMessage.value = 'Could not read steps: $e';
        },
      );
      statusMessage.value = null;
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
    final knownValue = _firstReadingDone ? todaySteps.value : 0;
    final delta = await ingestRawSteps(
      event.steps,
      _uid,
      syncNow: false,
      knownTodaySteps: knownValue,
    );
    _firstReadingDone = true;
    todaySteps.value = delta;
    _scheduleCloudSync();
  }

  void _scheduleCloudSync() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;

    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 2), () async {
      final day = _todayKey();
      print('[StepCounter] Syncing $todaySteps.value steps to cloud for day $day');
      
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
        print('[StepCounter] Firestore write success');
      } catch (e) {
        print('[StepCounter] Firestore write failed: $e');
      }

      try {
        final ts = DateTime.now().millisecondsSinceEpoch;
        await _realtimeDb.ref('users/$uid/daily_steps/$day').set({
          'steps': todaySteps.value,
          'date': day,
          'updatedAt': ts,
        });
        print('[StepCounter] Realtime DB write success');
      } catch (e) {
        print('[StepCounter] Realtime DB write failed: $e');
      }
    });
  }
}

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb, debugPrint;
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepCounterService {
  StepCounterService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  static const _prefsDay = 'step_counter_calendar_day';
  static const _prefsBaseline = 'step_counter_baseline_steps';
  static const _prefsFirstReadingDone = 'step_counter_first_reading_done';
  static const _prefsTodayDelta = 'step_counter_today_delta';

  // In-memory guard so concurrent pedometer callbacks can't each re-anchor
  // the baseline before the prefs write from the first call completes.
  static bool _firstReadingDoneInMemory = false;
  static String _lastDayInMemory = '';

  StreamSubscription<StepCount>? _subscription;
  Timer? _syncDebounce;
  String? _uid;

  final ValueNotifier<int> todaySteps = ValueNotifier<int>(0);
  final ValueNotifier<String?> statusMessage = ValueNotifier<String?>(null);

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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

  /// Ingests raw cumulative OS step count and returns today's delta.
  ///
  /// On the first reading of a new day the baseline is anchored to
  /// `rawSteps - knownTodaySteps` so any cloud-restored value is preserved.
  static Future<int> ingestRawSteps(
    int rawSteps,
    String? uid, {
    bool syncNow = false,
    int knownTodaySteps = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final storedDay = prefs.getString(_prefsDay);

    // Reset in-memory guard when the calendar day rolls over.
    if (_lastDayInMemory != day) {
      _firstReadingDoneInMemory = false;
      _lastDayInMemory = day;
    }

    // Combine in-memory flag (set synchronously) with persisted flag so
    // concurrent async calls all agree after the first one claims the anchor.
    final hadFirstReading =
        _firstReadingDoneInMemory || (prefs.getBool(_prefsFirstReadingDone) ?? false);
    var baseline = prefs.getInt(_prefsBaseline) ?? 0;

    if (storedDay != day) {
      // New calendar day — anchor baseline so existing cloud steps are preserved.
      final carry = knownTodaySteps < 0 ? 0 : knownTodaySteps;
      baseline = (rawSteps - carry).clamp(0, rawSteps);
      _firstReadingDoneInMemory = false;
      _lastDayInMemory = day;
      await prefs.setString(_prefsDay, day);
      await prefs.setInt(_prefsBaseline, baseline);
      await prefs.setBool(_prefsFirstReadingDone, false);
    } else if (!hadFirstReading) {
      // First sensor reading of this day — claim the anchor synchronously
      // before the first await so no concurrent call can re-anchor.
      _firstReadingDoneInMemory = true;
      final carry = knownTodaySteps < 0 ? 0 : knownTodaySteps;
      baseline = (rawSteps - carry).clamp(0, rawSteps);
      await prefs.setInt(_prefsBaseline, baseline);
      await prefs.setBool(_prefsFirstReadingDone, true);
    }

    final steps = (rawSteps - baseline).clamp(0, 1000000);

    // Cache so start() can display steps before the pedometer fires.
    await prefs.setInt(_prefsTodayDelta, steps);

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
        {'steps': steps, 'date': day, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  static Future<void> _writeRealtimeDatabase(
      String uid, String day, int steps) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      await _realtimeDb.ref('users/$uid/daily_steps/$day').update(
        {'steps': steps, 'date': day, 'updatedAt': ts},
      );
    } catch (_) {}
  }

  static Future<int> _readTodayStepsFromCloud(String uid) async {
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final snap =
          await _realtimeDb.ref('users/$uid/daily_steps/$day/steps').get();
      if (snap.value is num) return (snap.value as num).toInt();
    } catch (_) {}
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_steps')
          .doc(day)
          .get();
      final value = doc.data()?['steps'];
      if (value is num) return value.toInt();
    } catch (_) {}
    return 0;
  }

  /// Fetches up to [days] entries from Firestore for the step history screen.
  static Future<Map<String, int>> getStepHistory(String uid,
      {int days = 30}) async {
    final result = <String, int>{};
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_steps')
          .orderBy('date', descending: true)
          .limit(days)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final date = data['date'];
        final steps = data['steps'];
        if (date is String && steps is num) {
          result[date] = steps.toInt();
        }
      }
    } catch (_) {}

    // Fallback: read entire Realtime DB subtree in one request.
    if (result.isEmpty) {
      try {
        final snap =
            await _realtimeDb.ref('users/$uid/daily_steps').get();
        final raw = snap.value;
        if (raw is Map) {
          raw.forEach((key, value) {
            if (key is String && value is Map) {
              final s = value['steps'];
              if (s is num) result[key] = s.toInt();
            }
          });
        }
      } catch (_) {}
    }
    return result;
  }

  /// Called from WorkManager while the app is in the background.
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
      final raw = await completer.future
          .timeout(const Duration(seconds: 10), onTimeout: () => -1);
      if (raw < 0) return;
      final knownTodaySteps = await _readTodayStepsFromCloud(uid);
      await ingestRawSteps(raw, uid,
          syncNow: true, knownTodaySteps: knownTodaySteps);
    } catch (_) {
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

    // 1. Immediately restore last cached delta so the UI shows something fast.
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDay = prefs.getString(_prefsDay);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (storedDay == today) {
        final cached = prefs.getInt(_prefsTodayDelta) ?? 0;
        if (cached > todaySteps.value) todaySteps.value = cached;
      }
    } catch (_) {}

    // 2. Try cloud — may be higher than local cache (e.g., after background sync).
    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final cloudSteps = await _readTodayStepsFromCloud(uid);
        if (cloudSteps > todaySteps.value) todaySteps.value = cloudSteps;
      } catch (_) {}
    }

    // 3. Subscribe to live sensor stream.
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
    // Always pass current todaySteps so the baseline is anchored correctly
    // even when cloud-restored steps are already showing.
    final delta = await ingestRawSteps(
      event.steps,
      _uid,
      syncNow: false,
      knownTodaySteps: todaySteps.value,
    );
    todaySteps.value = delta;
    _scheduleCloudSync();
  }

  void _scheduleCloudSync() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 2), () async {
      final day = _todayKey();
      final steps = todaySteps.value;
      debugPrint('[StepCounter] Syncing $steps steps for $day');
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('daily_steps')
            .doc(day)
            .set(
          {'steps': steps, 'date': day, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        debugPrint('[StepCounter] Firestore write success');
      } catch (e) {
        debugPrint('[StepCounter] Firestore write failed: $e');
      }
      try {
        final ts = DateTime.now().millisecondsSinceEpoch;
        await _realtimeDb.ref('users/$uid/daily_steps/$day').update(
          {'steps': steps, 'date': day, 'updatedAt': ts},
        );
        debugPrint('[StepCounter] Realtime DB write success');
      } catch (e) {
        debugPrint('[StepCounter] Realtime DB write failed: $e');
      }
    });
  }
}
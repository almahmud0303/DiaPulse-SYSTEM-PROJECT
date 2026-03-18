import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/models/reminder_repeat_mode.dart';
import 'package:dia_plus/models/reminder_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderNotificationService {
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'diapulse_reminders_channel',
        'DiaPulse Reminders',
        description: 'Reminder notifications for DiaPulse users',
        importance: Importance.high,
      );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _timezoneInitialized = false;
  bool _initialized = false;

  /// Android setup note:
  /// Ensure a channel is created and Android 13+ notification permission is requested.
  /// If exact alarms are used later, add require5 exact alarm permissions in AndroidManifest.
  /// iOS setup note:
  /// Ensure notification permissions are requested from the user.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (!_timezoneInitialized) {
      tz.initializeTimeZones();
      await _configureLocalTimezone();
      _timezoneInitialized = true;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(_androidChannel);
    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      debugPrint('[ReminderSchedule] timezone configured: ${tz.local.name}');
    } catch (_) {
      // Do not force UTC. If timezone lookup fails, keeping the existing
      // default avoids shifting reminders by several hours.
      debugPrint(
        '[ReminderSchedule] timezone lookup failed; using default: ${tz.local.name}',
      );
    }
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final androidGranted = await androidImpl?.requestNotificationsPermission();
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {
      // Keep reminder flow working even if exact-alarm permission API is unavailable.
    }
    final iosGranted = await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<Reminder> scheduleReminder(Reminder reminder) async {
    await initialize();

    if (!reminder.isEnabled) {
      return reminder.copyWith(notificationIds: const []);
    }

    final ids = <int>[];
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    Future<void> scheduleAt({
      required int id,
      required tz.TZDateTime scheduled,
      DateTimeComponents? match,
    }) async {
      Future<void> doSchedule(AndroidScheduleMode mode) =>
          _plugin.zonedSchedule(
            id,
            reminder.title,
            reminder.description.isEmpty
                ? reminder.reminderType.label
                : reminder.description,
            scheduled,
            notificationDetails,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: reminder.id,
            androidScheduleMode: mode,
            matchDateTimeComponents: match,
          );

      try {
        await doSchedule(AndroidScheduleMode.exactAllowWhileIdle);
      } on PlatformException catch (e) {
        if (e.code == 'exact_alarms_not_permitted') {
          try {
            await doSchedule(AndroidScheduleMode.alarmClock);
          } on PlatformException {
            await doSchedule(AndroidScheduleMode.inexactAllowWhileIdle);
          }
        } else {
          rethrow;
        }
      }
      debugPrint(
        '[ReminderSchedule] id=$id title=${reminder.title} scheduled=${scheduled.toLocal()} tz=${tz.local.name} repeat=${reminder.repeatMode.name}',
      );
      ids.add(id);
    }

    switch (reminder.repeatMode) {
      case ReminderRepeatMode.once:
        final oneTime = _firstOneTime(reminder);
        if (oneTime != null) {
          await scheduleAt(
            id: _buildNotificationId(reminder.id, 0),
            scheduled: oneTime,
          );
        }
        break;
      case ReminderRepeatMode.daily:
        await scheduleAt(
          id: _buildNotificationId(reminder.id, 0),
          scheduled: _nextDaily(reminder),
          match: DateTimeComponents.time,
        );
        break;
      case ReminderRepeatMode.weekly:
        await scheduleAt(
          id: _buildNotificationId(reminder.id, 0),
          scheduled: _nextWeekly(reminder, reminder.date.weekday),
          match: DateTimeComponents.dayOfWeekAndTime,
        );
        break;
      case ReminderRepeatMode.selectedWeekdays:
        final weekdays = reminder.selectedWeekdays.toSet().toList()..sort();
        for (var i = 0; i < weekdays.length; i++) {
          final weekday = weekdays[i];
          if (weekday < DateTime.monday || weekday > DateTime.sunday) {
            continue;
          }
          await scheduleAt(
            id: _buildNotificationId(reminder.id, i),
            scheduled: _nextWeekly(reminder, weekday),
            match: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;
    }

    if (ids.isEmpty) {
      throw Exception(
        'No valid future trigger time was generated for this reminder.',
      );
    }

    return reminder.copyWith(notificationIds: ids);
  }

  Future<Reminder> rescheduleReminder(Reminder reminder) async {
    await initialize();
    await cancelReminderNotifications(reminder.notificationIds);
    return scheduleReminder(reminder.copyWith(notificationIds: const []));
  }

  Future<void> cancelReminderNotifications(List<int> notificationIds) async {
    await initialize();
    for (final id in notificationIds) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelAllScheduled() async {
    await initialize();
    await _plugin.cancelAll();
  }

  /// Returns the list of pending notification requests from the OS.
  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    return await _plugin.pendingNotificationRequests();
  }

  Future<void> showTestNotification() async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'diapulse_reminders_channel',
        'DiaPulse Reminders',
        channelDescription: 'Reminder notifications for DiaPulse users',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      0,
      'DiaPulse Reminder',
      'This is a test reminder notification.',
      details,
    );
  }

  static const String _scheduledMedicineIdsKey = 'scheduled_medicine_notification_ids';

  /// Schedules a daily notification at each medicine's time. Call when medicine list loads or changes.
  /// Cancels previously scheduled medicine notifications first.
  Future<void> scheduleMedicineReminders(List<Medicine> medicines) async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final previousIds = prefs.getStringList(_scheduledMedicineIdsKey);
    if (previousIds != null) {
      for (final idStr in previousIds) {
        final id = int.tryParse(idStr);
        if (id != null) await _plugin.cancel(id);
      }
      await prefs.remove(_scheduledMedicineIdsKey);
    }

    if (medicines.isEmpty) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'diapulse_reminders_channel',
        'DiaPulse Reminders',
        channelDescription: 'Reminder notifications for DiaPulse users',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = DateTime.now();
    final scheduledIds = <int>[];

    for (final m in medicines) {
      final times = m.effectiveTimes;
      for (var i = 0; i < times.length; i++) {
        final (hour, minute) = Medicine.reminderTimeFrom(times[i]);

        final todayAt = DateTime(now.year, now.month, now.day, hour, minute);
        final next = todayAt.isAfter(now)
            ? todayAt
            : todayAt.add(const Duration(days: 1));
        final tzScheduled = tz.TZDateTime.from(next, tz.local);

        final id = _medicineNotificationId(m.id, i);
        try {
          await _plugin.zonedSchedule(
            id,
            'Time to take medicine',
            '${m.name}${m.dosage.isNotEmpty ? ' · ${m.dosage}' : ''}',
            tzScheduled,
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'medicine_${m.id}_dose_$i',
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          scheduledIds.add(id);
        } on PlatformException catch (e) {
          if (e.code == 'exact_alarms_not_permitted') {
            try {
              await _plugin.zonedSchedule(
                id,
                'Time to take medicine',
                '${m.name}${m.dosage.isNotEmpty ? ' · ${m.dosage}' : ''}',
                tzScheduled,
                details,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                payload: 'medicine_${m.id}_dose_$i',
                androidScheduleMode: AndroidScheduleMode.alarmClock,
                matchDateTimeComponents: DateTimeComponents.time,
              );
              scheduledIds.add(id);
            } on PlatformException {
              await _plugin.zonedSchedule(
                id,
                'Time to take medicine',
                '${m.name}${m.dosage.isNotEmpty ? ' · ${m.dosage}' : ''}',
                tzScheduled,
                details,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                payload: 'medicine_${m.id}_dose_$i',
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                matchDateTimeComponents: DateTimeComponents.time,
              );
              scheduledIds.add(id);
            }
          } else {
            rethrow;
          }
        }
      }
    }

    await prefs.setStringList(
      _scheduledMedicineIdsKey,
      scheduledIds.map((e) => e.toString()).toList(),
    );
    debugPrint('[MedicineReminders] scheduled ${scheduledIds.length} medicine reminders');
  }

  /// Cancels all scheduled medicine-time notifications.
  Future<void> cancelMedicineReminders() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_scheduledMedicineIdsKey);
    if (ids != null) {
      for (final idStr in ids) {
        final id = int.tryParse(idStr);
        if (id != null) await _plugin.cancel(id);
      }
      await prefs.remove(_scheduledMedicineIdsKey);
    }
  }

  int _medicineNotificationId(String medicineId, int doseIndex) {
    final base = medicineId.hashCode.abs() % 9000; // keep room for per-dose suffix
    final suffix = doseIndex.clamp(0, 9);
    return 400000 + (base * 10) + suffix;
  }

  int _buildNotificationId(String reminderId, int suffix) {
    var hash = 17;
    for (final codeUnit in reminderId.codeUnits) {
      hash = 31 * hash + codeUnit;
    }
    hash = hash.abs() % 2147480000;
    return hash + suffix;
  }

  DateTime _combineDateTime(Reminder reminder) {
    return DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
      reminder.time.second,
      reminder.time.millisecond,
      reminder.time.microsecond,
    );
  }

  tz.TZDateTime? _firstOneTime(Reminder reminder) {
    final combined = _combineDateTime(reminder);
    if (combined.isBefore(DateTime.now())) {
      return null;
    }
    return tz.TZDateTime.from(combined, tz.local);
  }

  tz.TZDateTime _nextDaily(Reminder reminder) {
    final now = DateTime.now();
    final todayAtTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminder.time.hour,
      reminder.time.minute,
    );
    final next = todayAtTime.isAfter(now)
        ? todayAtTime
        : todayAtTime.add(const Duration(days: 1));
    return tz.TZDateTime.from(next, tz.local);
  }

  tz.TZDateTime _nextWeekly(Reminder reminder, int targetWeekday) {
    final now = DateTime.now();
    var daysAhead = (targetWeekday - now.weekday) % 7;
    if (daysAhead < 0) {
      daysAhead += 7;
    }

    var next = DateTime(
      now.year,
      now.month,
      now.day,
      reminder.time.hour,
      reminder.time.minute,
    ).add(Duration(days: daysAhead));

    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 7));
    }

    return tz.TZDateTime.from(next, tz.local);
  }
}

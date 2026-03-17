import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/models/reminder_repeat_mode.dart';
import 'package:dia_plus/models/reminder_type.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Android setup note:
  /// Ensure a channel is created and Android 13+ notification permission is requested.
  /// If exact alarms are used later, add required exact alarm permissions in AndroidManifest.
  /// iOS setup note:
  /// Ensure notification permissions are requested from the user.
  Future<void> initialize() async {
    if (!_timezoneInitialized) {
      tz.initializeTimeZones();
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
  }

  Future<bool> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final androidGranted = await androidImpl?.requestNotificationsPermission();
    final iosGranted = await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<Reminder> scheduleReminder(Reminder reminder) async {
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
      await _plugin.zonedSchedule(
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: match,
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

    return reminder.copyWith(notificationIds: ids);
  }

  Future<Reminder> rescheduleReminder(Reminder reminder) async {
    await cancelReminderNotifications(reminder.notificationIds);
    return scheduleReminder(reminder.copyWith(notificationIds: const []));
  }

  Future<void> cancelReminderNotifications(List<int> notificationIds) async {
    for (final id in notificationIds) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelAllScheduled() async {
    await _plugin.cancelAll();
  }

  /// Returns the list of pending notification requests from the OS.
  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    return await _plugin.pendingNotificationRequests();
  }

  Future<void> showTestNotification() async {
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

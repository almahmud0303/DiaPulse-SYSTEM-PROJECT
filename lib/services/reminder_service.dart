import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/models/reminder_repeat_mode.dart';
import 'package:dia_plus/models/reminder_settings.dart';
import 'package:dia_plus/models/reminder_type.dart';
import 'package:dia_plus/services/reminder_notification_service.dart';
import 'package:dia_plus/services/reminder_storage_service.dart';

class ReminderService {
  ReminderService({
    ReminderStorageService? storageService,
    ReminderNotificationService? notificationService,
  }) : _storageService = storageService ?? ReminderStorageService(),
       _notificationService =
           notificationService ?? ReminderNotificationService();

  final ReminderStorageService _storageService;
  final ReminderNotificationService _notificationService;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _notificationService.initialize();
    await _reconcileSchedulesWithStorage();
    _initialized = true;
  }

  Future<List<Reminder>> getAllReminders() async {
    final reminders = await _storageService.getReminders();
    reminders.sort(_compareByNextOccurrence);
    return reminders;
  }

  Future<void> saveReminder(Reminder reminder) async {
    final settings = await getSettings();
    _validateReminder(reminder);

    if (reminder.isEnabled &&
        !_isReminderAllowedBySettings(reminder, settings)) {
      throw Exception(
        'This reminder is disabled by Reminder Settings. Enable this category first.',
      );
    }

    final effective = reminder;

    final stored = effective.isEnabled
        ? await _notificationService.scheduleReminder(effective)
        : effective.copyWith(notificationIds: const []);

    await _storageService.upsertReminder(stored);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final settings = await getSettings();
    _validateReminder(reminder);

    if (reminder.isEnabled &&
        !_isReminderAllowedBySettings(reminder, settings)) {
      throw Exception(
        'This reminder is disabled by Reminder Settings. Enable this category first.',
      );
    }

    final previous = await _storageService.getReminderById(reminder.id);
    if (previous != null && previous.notificationIds.isNotEmpty) {
      await _notificationService.cancelReminderNotifications(
        previous.notificationIds,
      );
    }

    final effective = reminder;

    final updated = effective.isEnabled
        ? await _notificationService.scheduleReminder(effective)
        : effective.copyWith(notificationIds: const []);

    await _storageService.upsertReminder(updated);
  }

  Future<void> deleteReminder(Reminder reminder) async {
    await _notificationService.cancelReminderNotifications(
      reminder.notificationIds,
    );
    await _storageService.deleteReminder(reminder.id);
  }

  Future<void> toggleReminder(Reminder reminder, bool enabled) async {
    final settings = await getSettings();
    final shouldEnable =
        enabled && _isReminderAllowedBySettings(reminder, settings);

    if (enabled && !shouldEnable) {
      throw Exception('This reminder type is disabled in Reminder Settings.');
    }

    if (shouldEnable) {
      final scheduled = await _notificationService.rescheduleReminder(
        reminder.copyWith(isEnabled: true),
      );
      await _storageService.upsertReminder(scheduled);
      return;
    }

    await _notificationService.cancelReminderNotifications(
      reminder.notificationIds,
    );
    await _storageService.upsertReminder(
      reminder.copyWith(isEnabled: false, notificationIds: const []),
    );
  }

  Future<ReminderSettings> getSettings() {
    return _storageService.getSettings();
  }

  Future<void> updateSettings(ReminderSettings settings) async {
    await _storageService.saveSettings(settings);

    final reminders = await _storageService.getReminders();
    final updated = <Reminder>[];

    for (final reminder in reminders) {
      final allowed = _isReminderAllowedBySettings(reminder, settings);
      if (!allowed) {
        if (reminder.notificationIds.isNotEmpty) {
          await _notificationService.cancelReminderNotifications(
            reminder.notificationIds,
          );
        }
        updated.add(
          reminder.copyWith(isEnabled: false, notificationIds: const []),
        );
      } else if (reminder.isEnabled) {
        final rescheduled = await _notificationService.rescheduleReminder(
          reminder,
        );
        updated.add(rescheduled);
      } else {
        updated.add(reminder);
      }
    }

    await _storageService.saveReminders(updated);

    if (!settings.allRemindersEnabled) {
      await _notificationService.cancelAllScheduled();
    }
  }

  Future<bool> requestNotificationPermissions() {
    return _notificationService.requestPermissions();
  }

  Future<void> sendTestNotification() {
    return _notificationService.showTestNotification();
  }

  Future<String> buildSchedulingDiagnosticsReport() async {
    await initialize();

    final reminders = await _storageService.getReminders();
    final pending = await _notificationService.getPendingRequests();
    final pendingIds = pending.map((p) => p.id).toSet();

    final lines = <String>[
      'Reminder Scheduling Diagnostics',
      'Generated: ${DateTime.now().toIso8601String()}',
      'Saved reminders: ${reminders.length}',
      'Pending notifications in OS: ${pending.length}',
      '',
      'Pending Notification Requests:',
    ];

    if (pending.isEmpty) {
      lines.add('- None');
    } else {
      for (final p in pending) {
        lines.add(
          '- id=${p.id}, title="${p.title}", payload="${p.payload ?? ''}"',
        );
      }
    }

    lines.add('');
    lines.add('Saved Reminders:');

    if (reminders.isEmpty) {
      lines.add('- None');
    } else {
      for (final r in reminders) {
        final next = getNextTriggerTime(r);
        final missingIds = r.notificationIds
            .where((id) => !pendingIds.contains(id))
            .toList();

        lines.add(
          '- ${r.title} [id=${r.id}] enabled=${r.isEnabled} repeat=${r.repeatMode.name}',
        );
        lines.add('  nextTrigger=${next?.toIso8601String() ?? 'none'}');
        lines.add('  notificationIds=${r.notificationIds}');
        if (missingIds.isNotEmpty) {
          lines.add('  missingInPending=$missingIds');
        }
      }
    }

    return lines.join('\n');
  }

  Future<void> _reconcileSchedulesWithStorage() async {
    final reminders = await _storageService.getReminders();
    final pending = await _notificationService.getPendingRequests();
    final pendingIds = pending.map((p) => p.id).toSet();
    var changed = false;

    for (var i = 0; i < reminders.length; i++) {
      final reminder = reminders[i];

      if (!reminder.isEnabled) {
        continue;
      }

      if (reminder.repeatMode == ReminderRepeatMode.once &&
          getNextTriggerTime(reminder) == null) {
        reminders[i] = reminder.copyWith(
          isEnabled: false,
          notificationIds: const [],
        );
        changed = true;
        continue;
      }

      final hasAnyPending = reminder.notificationIds.any(pendingIds.contains);
      if (hasAnyPending) {
        continue;
      }

      final rescheduled = await _notificationService.scheduleReminder(
        reminder.copyWith(notificationIds: const []),
      );
      reminders[i] = rescheduled;
      changed = true;
    }

    if (changed) {
      await _storageService.saveReminders(reminders);
    }
  }

  DateTime? getNextTriggerTime(Reminder reminder, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final scheduled = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
      reminder.time.second,
      reminder.time.millisecond,
      reminder.time.microsecond,
    );

    switch (reminder.repeatMode) {
      case ReminderRepeatMode.once:
        return scheduled.isBefore(now) ? null : scheduled;
      case ReminderRepeatMode.daily:
        final today = DateTime(
          now.year,
          now.month,
          now.day,
          reminder.time.hour,
          reminder.time.minute,
        );
        return today.isAfter(now) ? today : today.add(const Duration(days: 1));
      case ReminderRepeatMode.weekly:
        return _nextByWeekday(now, reminder.time, reminder.date.weekday);
      case ReminderRepeatMode.selectedWeekdays:
        if (reminder.selectedWeekdays.isEmpty) {
          return null;
        }
        DateTime? earliest;
        for (final weekday in reminder.selectedWeekdays) {
          final candidate = _nextByWeekday(now, reminder.time, weekday);
          if (earliest == null || candidate.isBefore(earliest)) {
            earliest = candidate;
          }
        }
        return earliest;
    }
  }

  Future<List<Reminder>> getUpcomingEnabledReminders() async {
    final reminders = await getAllReminders();
    return reminders
        .where((r) => r.isEnabled)
        .where((r) => getNextTriggerTime(r) != null)
        .toList()
      ..sort(_compareByNextOccurrence);
  }

  Future<Reminder?> getNextReminder({ReminderType? type}) async {
    final reminders = await getUpcomingEnabledReminders();
    for (final reminder in reminders) {
      if (type == null || reminder.reminderType == type) {
        return reminder;
      }
    }
    return null;
  }

  void _validateReminder(Reminder reminder) {
    if (reminder.title.trim().isEmpty) {
      throw Exception('Reminder title is required.');
    }

    if (reminder.repeatMode == ReminderRepeatMode.selectedWeekdays &&
        reminder.selectedWeekdays.isEmpty) {
      throw Exception('Select at least one weekday for weekday reminders.');
    }

    if (reminder.repeatMode == ReminderRepeatMode.once &&
        getNextTriggerTime(reminder) == null) {
      throw Exception('One-time reminder cannot be scheduled in the past.');
    }
  }

  bool _isReminderAllowedBySettings(
    Reminder reminder,
    ReminderSettings settings,
  ) {
    if (!settings.allRemindersEnabled) {
      return false;
    }

    switch (reminder.reminderType) {
      case ReminderType.medicine:
        return settings.medicineRemindersEnabled;
      case ReminderType.glucoseTest:
        return settings.glucoseRemindersEnabled;
      case ReminderType.exercise:
        return settings.exerciseRemindersEnabled;
      case ReminderType.appointment:
        return settings.appointmentRemindersEnabled;
    }
  }

  int _compareByNextOccurrence(Reminder a, Reminder b) {
    final nextA = getNextTriggerTime(a);
    final nextB = getNextTriggerTime(b);

    if (nextA == null && nextB == null) {
      return a.createdAt.compareTo(b.createdAt);
    }
    if (nextA == null) return 1;
    if (nextB == null) return -1;
    return nextA.compareTo(nextB);
  }

  DateTime _nextByWeekday(
    DateTime now,
    DateTime timeSource,
    int targetWeekday,
  ) {
    var daysAhead = (targetWeekday - now.weekday) % 7;
    if (daysAhead < 0) {
      daysAhead += 7;
    }

    var next = DateTime(
      now.year,
      now.month,
      now.day,
      timeSource.hour,
      timeSource.minute,
    ).add(Duration(days: daysAhead));

    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 7));
    }

    return next;
  }
}

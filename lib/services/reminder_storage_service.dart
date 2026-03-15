import 'dart:convert';

import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/models/reminder_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderStorageService {
  static const String _remindersKey = 'smart_reminders_records';
  static const String _settingsKey = 'smart_reminders_settings';

  Future<List<Reminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_remindersKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => Reminder.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = reminders.map((r) => r.toMap()).toList();
    await prefs.setString(_remindersKey, jsonEncode(payload));
  }

  Future<void> upsertReminder(Reminder reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) {
      reminders.add(reminder);
    } else {
      reminders[index] = reminder;
    }
    await saveReminders(reminders);
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == reminderId);
    await saveReminders(reminders);
  }

  Future<Reminder?> getReminderById(String reminderId) async {
    final reminders = await getReminders();
    for (final reminder in reminders) {
      if (reminder.id == reminderId) {
        return reminder;
      }
    }
    return null;
  }

  Future<ReminderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return const ReminderSettings();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return ReminderSettings.fromMap(decoded);
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toMap()));
  }

  Future<void> clearAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindersKey);
  }
}

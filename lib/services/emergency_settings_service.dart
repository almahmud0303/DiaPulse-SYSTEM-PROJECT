import 'dart:convert';

import 'package:dia_plus/models/emergency_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencySettingsService {
  static const String _settingsKey = 'emergency_alert_settings';

  Future<EmergencySettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);

    if (raw == null || raw.isEmpty) {
      return const EmergencySettings();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return EmergencySettings.fromMap(decoded);
  }

  Future<void> saveSettings(EmergencySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toMap()));
  }

  Future<void> resetToDefaults() async {
    const defaults = EmergencySettings();
    await saveSettings(defaults);
  }
}

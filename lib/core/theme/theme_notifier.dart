import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app theme mode (light/dark). Persists preference and notifies listeners.
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier._();
  static ThemeNotifier? _instance;
  static ThemeNotifier get instance => _instance ??= ThemeNotifier._();

  static const _keyDarkMode = 'darkModeEnabled';

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDarkMode => _mode == ThemeMode.dark;

  /// Initialize by loading from SharedPreferences. Call once at app start.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_keyDarkMode) ?? false;
    instance._mode = dark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle dark mode. Saves preference and notifies listeners.
  Future<void> setDarkMode(bool enabled) async {
    if (_mode == (enabled ? ThemeMode.dark : ThemeMode.light)) return;
    _mode = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
    notifyListeners();
  }
}

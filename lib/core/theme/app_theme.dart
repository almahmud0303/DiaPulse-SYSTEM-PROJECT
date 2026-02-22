import 'package:flutter/material.dart';

/// App-wide theme configuration.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    );
  }
}

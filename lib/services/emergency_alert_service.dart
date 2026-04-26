import 'dart:convert';

import 'package:dia_plus/models/emergency_alert.dart';
import 'package:dia_plus/models/emergency_alert_type.dart';
import 'package:dia_plus/models/emergency_settings.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/services/emergency_notification_service.dart';
import 'package:dia_plus/services/emergency_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyAlertService {
  EmergencyAlertService({
    EmergencySettingsService? settingsService,
    EmergencyNotificationService? notificationService,
  }) : _settingsService = settingsService ?? EmergencySettingsService(),
       _notificationService =
           notificationService ?? EmergencyNotificationService();

  static const String _alertsHistoryKey = 'emergency_alert_history';
  static const int _maxHistoryRecords = 200;
  static const int _duplicateCooldownMinutes = 2;

  final EmergencySettingsService _settingsService;
  final EmergencyNotificationService _notificationService;

  Future<EmergencyAlert?> checkReadingForEmergency(
    GlucoseReading reading, {
    bool triggerNotification = true,
  }) async {
    final settings = await _settingsService.getSettings();

    if (!settings.isEmergencyAlertsEnabled) {
      return null;
    }

    final type = getEmergencyTypeForValue(
      reading.glucoseLevel,
      settings: settings,
    );

    if (type == null) {
      return null;
    }

    final candidate = buildEmergencyAlert(
      reading: reading,
      alertType: type,
      settings: settings,
    );

    final isDuplicateSpam = await _isDuplicateWithinCooldown(candidate);
    if (isDuplicateSpam) {
      return null;
    }

    final enriched = candidate;

    await saveAlertRecord(enriched);
    if (triggerNotification) {
      await _notificationService.showEmergencyAlertNotification(
        enriched,
        soundEnabled: settings.soundEnabled,
        vibrationEnabled: settings.vibrationEnabled,
      );
    }

    return enriched;
  }

  Future<EmergencySettings> getSettings() {
    return _settingsService.getSettings();
  }

  bool isCriticalLow(double value, {EmergencySettings? settings}) {
    final effective = settings ?? const EmergencySettings();
    return value < effective.lowThreshold;
  }

  bool isCriticalHigh(double value, {EmergencySettings? settings}) {
    final effective = settings ?? const EmergencySettings();
    return value > effective.highThreshold;
  }

  EmergencyAlertType? getEmergencyTypeForValue(
    double value, {
    EmergencySettings? settings,
  }) {
    final effective = settings ?? const EmergencySettings();
    return _resolveEmergencyType(
      value,
      lowThreshold: effective.lowThreshold,
      highThreshold: effective.highThreshold,
    );
  }

  EmergencyAlert buildEmergencyAlert({
    required GlucoseReading reading,
    required EmergencyAlertType alertType,
    required EmergencySettings settings,
  }) {
    final now = DateTime.now();
    final title = alertType == EmergencyAlertType.criticalLow
        ? 'Critical Low Glucose Detected'
        : 'Critical High Glucose Detected';

    final fallbackMessage = alertType == EmergencyAlertType.criticalLow
        ? 'Glucose is ${reading.glucoseLevel.toStringAsFixed(0)} mg/dL. Immediate action is required to raise blood sugar safely.'
        : 'Glucose is ${reading.glucoseLevel.toStringAsFixed(0)} mg/dL. Immediate action is required to lower blood sugar safely.';

    final templateMessage = settings.emergencyMessageTemplate.trim();
    final message = templateMessage.isEmpty
        ? fallbackMessage
        : templateMessage
              .replaceAll('{glucose}', reading.glucoseLevel.toStringAsFixed(0))
              .replaceAll('{type}', alertType.label);

    return EmergencyAlert(
      id: '${reading.userId}_${reading.id}_${now.millisecondsSinceEpoch}',
      glucoseValue: reading.glucoseLevel,
      alertType: alertType,
      title: title,
      message: message,
      timestamp: now,
      readingId: reading.id,
      severityLabel: alertType.severityLabel,
      recommendedActions: _buildRecommendedActions(alertType),
      wasAcknowledged: false,
      emergencyContactNotified: false,
      doctorNotified: false,
      createdAt: now,
    );
  }

  Future<void> saveAlertRecord(EmergencyAlert alert) async {
    final alerts = await getAlertHistory();
    alerts.insert(0, alert);

    if (alerts.length > _maxHistoryRecords) {
      alerts.removeRange(_maxHistoryRecords, alerts.length);
    }

    await _persistAlerts(alerts);
  }

  Future<List<EmergencyAlert>> getAlertHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alertsHistoryKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final alerts = decoded
          .whereType<Map>()
          .map(
            (item) => EmergencyAlert.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();

      alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alerts;
    } catch (_) {
      // Corrupted or unreadable stored data — reset and return empty.
      await prefs.remove(_alertsHistoryKey);
      return [];
    }
  }

  Future<void> markAlertAcknowledged(String alertId) async {
    await _updateAlert(
      alertId,
      (alert) => alert.copyWith(wasAcknowledged: true),
    );
  }

  Future<void> markEmergencyContactNotified(String alertId) async {
    await _updateAlert(
      alertId,
      (alert) => alert.copyWith(emergencyContactNotified: true),
    );
  }

  Future<void> markDoctorNotified(String alertId) async {
    await _updateAlert(
      alertId,
      (alert) => alert.copyWith(doctorNotified: true),
    );
  }

  Future<EmergencyAlert?> getLatestAlert() async {
    final history = await getAlertHistory();
    return history.isEmpty ? null : history.first;
  }

  Future<List<EmergencyAlert>> getUnacknowledgedAlerts() async {
    final history = await getAlertHistory();
    return history.where((alert) => !alert.wasAcknowledged).toList();
  }

  Future<List<EmergencyAlert>> getAlertsByType(EmergencyAlertType type) async {
    final history = await getAlertHistory();
    return history.where((alert) => alert.alertType == type).toList();
  }

  Future<void> clearAlertHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alertsHistoryKey);
  }

  Future<void> notifyEmergencyContactSimulation(EmergencyAlert alert) async {
    await markEmergencyContactNotified(alert.id);
    await _notificationService.showSimulationNotice(
      title: 'Emergency contact notified',
      message:
          'Simulation: emergency contact notified for ${alert.glucoseValue.toStringAsFixed(0)} mg/dL.',
    );
  }

  Future<void> notifyDoctorSimulation(EmergencyAlert alert) async {
    await markDoctorNotified(alert.id);
    await _notificationService.showSimulationNotice(
      title: 'Doctor notified',
      message:
          'Simulation: doctor notified for ${alert.glucoseValue.toStringAsFixed(0)} mg/dL.',
    );
  }

  Future<void> _updateAlert(
    String alertId,
    EmergencyAlert Function(EmergencyAlert alert) updater,
  ) async {
    final alerts = await getAlertHistory();
    final index = alerts.indexWhere((alert) => alert.id == alertId);
    if (index == -1) {
      return;
    }

    alerts[index] = updater(alerts[index]);

    await _persistAlerts(alerts);
  }

  Future<void> _persistAlerts(List<EmergencyAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = alerts.map((a) => a.toMap()).toList();
    await prefs.setString(_alertsHistoryKey, jsonEncode(payload));
  }

  EmergencyAlertType? _resolveEmergencyType(
    double value, {
    required double lowThreshold,
    required double highThreshold,
  }) {
    if (value < lowThreshold) {
      return EmergencyAlertType.criticalLow;
    }

    if (value > highThreshold) {
      return EmergencyAlertType.criticalHigh;
    }

    return null;
  }

  List<String> _buildRecommendedActions(EmergencyAlertType type) {
    if (type == EmergencyAlertType.criticalLow) {
      return const [
        'Eat or drink fast-acting sugar immediately.',
        'Recheck glucose after 15 minutes.',
        'Seek immediate help if symptoms worsen.',
      ];
    }

    return const [
      'Drink water.',
      'Follow prescribed insulin or treatment plan.',
      'Recheck glucose level soon.',
      'Contact doctor if level remains high.',
    ];
  }

  Future<bool> _isDuplicateWithinCooldown(EmergencyAlert candidate) async {
    final history = await getAlertHistory();
    if (history.isEmpty) {
      return false;
    }

    final latest = history.first;
    final sameReading =
        latest.readingId != null && latest.readingId == candidate.readingId;
    final sameType = latest.alertType == candidate.alertType;
    final withinCooldown =
        candidate.createdAt.difference(latest.createdAt).inMinutes.abs() <
        _duplicateCooldownMinutes;

    return sameReading && sameType && withinCooldown;
  }
}

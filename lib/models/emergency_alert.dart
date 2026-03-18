import 'package:dia_plus/models/emergency_alert_type.dart';

/// A persisted emergency event raised from a dangerous glucose reading.
class EmergencyAlert {
  final String id;
  final double glucoseValue;
  final EmergencyAlertType alertType;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? readingId;
  final String severityLabel;
  final List<String> recommendedActions;
  final bool wasAcknowledged;
  final bool emergencyContactNotified;
  final bool doctorNotified;
  final DateTime createdAt;

  const EmergencyAlert({
    required this.id,
    required this.glucoseValue,
    required this.alertType,
    required this.title,
    required this.message,
    required this.timestamp,
    this.readingId,
    required this.severityLabel,
    required this.recommendedActions,
    this.wasAcknowledged = false,
    this.emergencyContactNotified = false,
    this.doctorNotified = false,
    required this.createdAt,
  });

  bool get isCriticalLow => alertType.isCriticalLow;

  bool get isCriticalHigh => alertType.isCriticalHigh;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'glucoseValue': glucoseValue,
      'alertType': alertType.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'readingId': readingId,
      'severityLabel': severityLabel,
      'recommendedActions': recommendedActions,
      'wasAcknowledged': wasAcknowledged,
      'emergencyContactNotified': emergencyContactNotified,
      'doctorNotified': doctorNotified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmergencyAlert.fromMap(Map<String, dynamic> map) {
    final typeName = map['alertType'] as String? ?? EmergencyAlertType.criticalLow.name;
    final alertType = EmergencyAlertType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => EmergencyAlertType.criticalLow,
    );

    return EmergencyAlert(
      id: map['id'] as String,
      glucoseValue: (map['glucoseValue'] as num).toDouble(),
      alertType: alertType,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      readingId: map['readingId'] as String?,
      severityLabel: map['severityLabel'] as String? ?? alertType.severityLabel,
      recommendedActions: (map['recommendedActions'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      wasAcknowledged: map['wasAcknowledged'] as bool? ?? false,
      emergencyContactNotified: map['emergencyContactNotified'] as bool? ?? false,
      doctorNotified: map['doctorNotified'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  EmergencyAlert copyWith({
    String? id,
    double? glucoseValue,
    EmergencyAlertType? alertType,
    String? title,
    String? message,
    DateTime? timestamp,
    String? readingId,
    String? severityLabel,
    List<String>? recommendedActions,
    bool? wasAcknowledged,
    bool? emergencyContactNotified,
    bool? doctorNotified,
    DateTime? createdAt,
  }) {
    return EmergencyAlert(
      id: id ?? this.id,
      glucoseValue: glucoseValue ?? this.glucoseValue,
      alertType: alertType ?? this.alertType,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      readingId: readingId ?? this.readingId,
      severityLabel: severityLabel ?? this.severityLabel,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      wasAcknowledged: wasAcknowledged ?? this.wasAcknowledged,
      emergencyContactNotified:
          emergencyContactNotified ?? this.emergencyContactNotified,
      doctorNotified: doctorNotified ?? this.doctorNotified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Type of emergency alert triggered by dangerous glucose values.
enum EmergencyAlertType {
  criticalLow,
  criticalHigh,
}

extension EmergencyAlertTypeX on EmergencyAlertType {
  /// Human-readable type label for UI.
  String get label {
    switch (this) {
      case EmergencyAlertType.criticalLow:
        return 'Critical Low';
      case EmergencyAlertType.criticalHigh:
        return 'Critical High';
    }
  }

  /// Severity label used across emergency cards/history.
  String get severityLabel {
    switch (this) {
      case EmergencyAlertType.criticalLow:
      case EmergencyAlertType.criticalHigh:
        return 'Critical';
    }
  }

  bool get isCriticalLow => this == EmergencyAlertType.criticalLow;

  bool get isCriticalHigh => this == EmergencyAlertType.criticalHigh;
}
/// Risk level for a patient based on recent glucose and control.
enum RiskLevel {
  low,
  moderate,
  elevated,
  high,
}

/// Computed risk status for display on list and profile.
class PatientRisk {
  const PatientRisk({
    required this.level,
    required this.summary,
    this.averageGlucose,
    this.readingCount = 0,
    this.lowCount = 0,
    this.highCount = 0,
    this.veryHighCount = 0,
  });

  final RiskLevel level;
  final String summary;
  final double? averageGlucose;
  final int readingCount;
  final int lowCount;
  final int highCount;
  final int veryHighCount;

  String get label {
    switch (level) {
      case RiskLevel.low:
        return 'Low risk';
      case RiskLevel.moderate:
        return 'Moderate risk';
      case RiskLevel.elevated:
        return 'Elevated risk';
      case RiskLevel.high:
        return 'High risk';
    }
  }
}

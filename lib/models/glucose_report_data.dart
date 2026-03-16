import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/glucose_report_stats.dart';

/// Data transfer object containing everything needed to render a glucose report PDF.
class GlucoseReportData {
  const GlucoseReportData({
    required this.patientName,
    this.patientAge,
    this.patientWeight,
    this.patientHeight,
    this.diabetesType,
    required this.rangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
    required this.generatedAt,
    required this.readings,
    required this.stats,
    required this.trendSummary,
  });

  /// Display name of the patient.
  final String patientName;

  /// Age in years. Null if not set on profile.
  final int? patientAge;

  /// Weight in kg. Null if not set on profile.
  final double? patientWeight;

  /// Height in cm. Null if not set on profile.
  final double? patientHeight;

  /// Human-readable diabetes type label. Null if not set on profile.
  final String? diabetesType;

  /// Human-readable label for the selected date range (e.g. "Last 7 Days").
  final String rangeLabel;

  /// Inclusive start of the report period (normalised to midnight).
  final DateTime rangeStart;

  /// Inclusive end of the report period (normalised to 23:59:59).
  final DateTime rangeEnd;

  /// Timestamp when the report was generated.
  final DateTime generatedAt;

  /// Glucose readings included in the report, sorted descending by date.
  final List<GlucoseReading> readings;

  /// Aggregate statistics computed from [readings].
  final GlucoseReportStats stats;

  /// One-sentence rule-based trend description.
  final String trendSummary;
}

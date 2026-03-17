import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/glucose_report_stats.dart';

/// Container for report range, computed stats, and optional patient/readings for PDF.
class GlucoseReportData {
  const GlucoseReportData({
    required this.rangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
    required this.stats,
    required this.trendSummary,
    this.patientName,
    this.patientAge,
    this.patientWeight,
    this.patientHeight,
    this.diabetesType,
    DateTime? generatedAt,
    List<GlucoseReading>? readings,
  })  : generatedAt = generatedAt ?? rangeEnd,
        readings = readings ?? const [];

  final String rangeLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final GlucoseReportStats stats;
  final String trendSummary;

  /// Display name for PDF header. Null if not set.
  final String? patientName;

  final int? patientAge;
  final double? patientWeight;
  final double? patientHeight;
  final String? diabetesType;

  /// Timestamp when the report was generated (defaults to rangeEnd).
  final DateTime generatedAt;

  /// Readings for PDF detail table; may be empty.
  final List<GlucoseReading> readings;
}

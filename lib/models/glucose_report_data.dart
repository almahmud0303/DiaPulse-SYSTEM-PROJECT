/// Statistics for a glucose report period.
class GlucoseReportStats {
  const GlucoseReportStats({
    required this.totalReadings,
    required this.averageGlucose,
    required this.highestGlucose,
    required this.lowestGlucose,
    required this.lowCount,
    required this.normalCount,
    required this.highCount,
    required this.veryHighCount,
  });

  final int totalReadings;
  final double averageGlucose;
  final double highestGlucose;
  final double lowestGlucose;
  final int lowCount;
  final int normalCount;
  final int highCount;
  final int veryHighCount;

  bool get hasData => totalReadings > 0;
}

/// Container for report range and computed stats.
class GlucoseReportData {
  const GlucoseReportData({
    required this.rangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
    required this.stats,
    required this.trendSummary,
  });

  final String rangeLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final GlucoseReportStats stats;
  final String trendSummary;
}

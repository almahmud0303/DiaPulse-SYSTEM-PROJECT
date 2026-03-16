/// Aggregate statistics computed from a filtered set of glucose readings.
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

  /// Number of readings with status "Low" (glucose < 70 mg/dL).
  final int lowCount;

  /// Number of readings with status "Normal" (70–140 mg/dL).
  final int normalCount;

  /// Number of readings with status "High" (141–200 mg/dL).
  final int highCount;

  /// Number of readings with status "Very High" (> 200 mg/dL).
  final int veryHighCount;

  bool get hasData => totalReadings > 0;

  factory GlucoseReportStats.empty() {
    return const GlucoseReportStats(
      totalReadings: 0,
      averageGlucose: 0,
      highestGlucose: 0,
      lowestGlucose: 0,
      lowCount: 0,
      normalCount: 0,
      highCount: 0,
      veryHighCount: 0,
    );
  }
}

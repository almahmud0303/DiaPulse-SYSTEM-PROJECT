/// Chart point derived from grouped glucose readings.
class GlucoseTrendPoint {
  const GlucoseTrendPoint({
    required this.axisValue,
    required this.label,
    required this.averageGlucose,
    required this.readingCount,
  });

  final double axisValue;
  final String label;
  final double averageGlucose;
  final int readingCount;
}

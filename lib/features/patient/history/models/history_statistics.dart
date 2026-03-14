/// Aggregate values shown in the history statistics cards.
class HistoryStatistics {
  const HistoryStatistics({
    required this.averageGlucose,
    required this.highestGlucose,
    required this.lowestGlucose,
    required this.totalReadings,
  });

  final double averageGlucose;
  final double highestGlucose;
  final double lowestGlucose;
  final int totalReadings;

  factory HistoryStatistics.empty() {
    return const HistoryStatistics(
      averageGlucose: 0,
      highestGlucose: 0,
      lowestGlucose: 0,
      totalReadings: 0,
    );
  }

  bool get hasData => totalReadings > 0;
}

/// Period for health score calculation.
enum HealthScorePeriod {
  today,
  last7Days,
  last30Days,
}

/// Single row in the health score breakdown.
class HealthScoreBreakdownItem {
  const HealthScoreBreakdownItem({
    required this.category,
    required this.score,
    required this.maxScore,
    this.note = '',
  });

  final String category;
  final double score;
  final double maxScore;
  final String note;
}

/// Health score result for a period.
class HealthScore {
  const HealthScore({
    required this.period,
    required this.totalScore,
    required this.status,
    required this.trend,
    required this.summary,
    required this.periodLabel,
    required this.breakdown,
    this.insights = const [],
  });

  final HealthScorePeriod period;
  final double totalScore;
  final String status;
  final String trend;
  final String summary;
  final String periodLabel;
  final List<HealthScoreBreakdownItem> breakdown;
  final List<String> insights;
}

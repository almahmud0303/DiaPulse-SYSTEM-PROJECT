import 'package:dia_plus/models/health_score.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';

/// Calculates health scores from glucose readings.
class HealthScoreService {
  final GlucoseReadingService _readingService = GlucoseReadingService();

  Future<HealthScore?> calculateHealthScore(
    String userId, {
    required HealthScorePeriod period,
  }) async {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    String periodLabel;

    switch (period) {
      case HealthScorePeriod.today:
        start = DateTime(now.year, now.month, now.day);
        end = now;
        periodLabel = 'Today';
        break;
      case HealthScorePeriod.last7Days:
        start = now.subtract(const Duration(days: 7));
        end = now;
        periodLabel = 'Last 7 days';
        break;
      case HealthScorePeriod.last30Days:
        start = now.subtract(const Duration(days: 30));
        end = now;
        periodLabel = 'Last 30 days';
        break;
    }

    final readings = await _readingService.getReadingsByDateRange(
      userId,
      start,
      end,
    );

    if (readings.isEmpty) {
      return null;
    }

    final avg = readings.map((r) => r.glucoseLevel).reduce((a, b) => a + b) / readings.length;
    final levels = readings.map((r) => r.glucoseLevel).toList();
    final lowest = levels.reduce((a, b) => a < b ? a : b);

    // Simple score 0–100: best 70–140, penalize outside
    double score = 100;
    for (final v in levels) {
      if (v < 70 || v > 140) {
        final dist = v < 70 ? (70 - v) : (v - 140);
        score -= (dist / 3).clamp(0, 25);
      }
    }
    score = score.clamp(0, 100);

    String status;
    if (score >= 80) {
      status = 'Excellent';
    } else if (score >= 60) {
      status = 'Good';
    } else if (score >= 40) {
      status = 'Fair';
    } else {
      status = 'Poor';
    }

    final breakdown = <HealthScoreBreakdownItem>[
      HealthScoreBreakdownItem(
        category: 'Glucose control',
        score: score,
        maxScore: 100,
        note: 'Average ${avg.toStringAsFixed(0)} mg/dL',
      ),
      HealthScoreBreakdownItem(
        category: 'Readings',
        score: readings.length.toDouble(),
        maxScore: period == HealthScorePeriod.today ? 10 : (period == HealthScorePeriod.last7Days ? 21 : 90),
        note: '${readings.length} in period',
      ),
    ];

    final insights = <String>[];
    if (avg > 140) {
      insights.add('Average glucose is above target. Consider diet and medication review.');
    }
    if (lowest < 70) {
      insights.add('You had low glucose readings. Monitor for hypoglycemia.');
    }
    if (readings.length < 3 && period != HealthScorePeriod.today) {
      insights.add('Log more readings for a more accurate score.');
    }

    return HealthScore(
      period: period,
      totalScore: score,
      status: status,
      trend: 'Stable',
      summary: 'Based on ${readings.length} readings. Average ${avg.toStringAsFixed(0)} mg/dL.',
      periodLabel: periodLabel,
      breakdown: breakdown,
      insights: insights,
    );
  }

}

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
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    DateTime start;
    DateTime end;
    String periodLabel;

    switch (period) {
      case HealthScorePeriod.today:
        start = todayStart;
        end = todayEnd;
        periodLabel = 'Today';
        break;
      case HealthScorePeriod.last7Days:
        // Inclusive 7-day window: today + previous 6 days.
        start = todayStart.subtract(const Duration(days: 6));
        end = todayEnd;
        periodLabel = 'Last 7 days';
        break;
      case HealthScorePeriod.last30Days:
        // Inclusive 30-day window: today + previous 29 days.
        start = todayStart.subtract(const Duration(days: 29));
        end = todayEnd;
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

    // Score 0–100: best range 70–140. Use average penalty so score does not
    // become unfairly lower just because the user logged more readings.
    final penalties = levels.map((v) {
      if (v >= 70 && v <= 140) return 0.0;
      final dist = v < 70 ? (70 - v) : (v - 140);
      return (dist / 3).clamp(0, 25).toDouble();
    }).toList();
    final avgPenalty = penalties.reduce((a, b) => a + b) / penalties.length;
    double score = (100 - avgPenalty).clamp(0, 100).toDouble();

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

    final readingMax = period == HealthScorePeriod.today
        ? 10.0
        : (period == HealthScorePeriod.last7Days ? 21.0 : 90.0);
    final readingScore =
      readings.length.toDouble().clamp(0, readingMax).toDouble();

    final breakdown = <HealthScoreBreakdownItem>[
      HealthScoreBreakdownItem(
        category: 'Glucose control',
        score: score,
        maxScore: 100,
        note: 'Average ${avg.toStringAsFixed(0)} mg/dL',
      ),
      HealthScoreBreakdownItem(
        category: 'Readings',
        score: readingScore,
        maxScore: readingMax,
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
    final minReadings = switch (period) {
      HealthScorePeriod.today => 1,
      HealthScorePeriod.last7Days => 7,
      HealthScorePeriod.last30Days => 15,
    };
    if (readings.length < minReadings && period != HealthScorePeriod.today) {
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

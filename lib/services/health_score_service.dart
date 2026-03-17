import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/health_score.dart';
import 'package:dia_plus/models/health_score_breakdown.dart';
import 'package:dia_plus/services/activity_service.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:dia_plus/services/meal_service.dart';
import 'package:dia_plus/services/medicine_service.dart';

enum HealthScorePeriod { today, last7Days, last30Days }

class HealthScoreService {
  HealthScoreService({
    GlucoseReadingService? glucoseReadingService,
    MedicineService? medicineService,
    ActivityService? activityService,
    MealService? mealService,
  }) : _glucoseReadingService = glucoseReadingService ?? GlucoseReadingService(),
       _medicineService = medicineService ?? MedicineService(),
       _activityService = activityService ?? ActivityService(),
       _mealService = mealService ?? MealService();

  static const int _maxGlucoseScore = 40;
  static const int _maxMedicationScore = 25;
  static const int _maxExerciseScore = 20;
  static const int _maxMealScore = 15;

  final GlucoseReadingService _glucoseReadingService;
  final MedicineService _medicineService;
  final ActivityService _activityService;
  final MealService _mealService;

  Future<HealthScore> calculateHealthScore(
    String userId, {
    HealthScorePeriod period = HealthScorePeriod.last7Days,
    bool includeTrend = true,
  }) async {
    final range = _resolvePeriodRange(period);

    final glucose = await _computeGlucoseScore(
      userId: userId,
      start: range.start,
      end: range.end,
    );
    final medication = await _computeMedicationScore(
      userId: userId,
      start: range.start,
      end: range.end,
      period: period,
    );
    final exercise = await _computeExerciseScore(
      userId: userId,
      start: range.start,
      end: range.end,
      period: period,
    );
    final meal = await _computeMealScore(
      userId: userId,
      start: range.start,
      end: range.end,
      period: period,
    );

    final total = (glucose.score + medication.score + exercise.score + meal.score)
        .clamp(0, 100)
        .toInt();

    final breakdown = [
      HealthScoreBreakdown(
        category: 'Glucose Control',
        score: glucose.score,
        maxScore: _maxGlucoseScore,
        note: glucose.note,
      ),
      HealthScoreBreakdown(
        category: 'Medication Adherence',
        score: medication.score,
        maxScore: _maxMedicationScore,
        note: medication.note,
      ),
      HealthScoreBreakdown(
        category: 'Exercise Consistency',
        score: exercise.score,
        maxScore: _maxExerciseScore,
        note: exercise.note,
      ),
      HealthScoreBreakdown(
        category: 'Meal Logging',
        score: meal.score,
        maxScore: _maxMealScore,
        note: meal.note,
      ),
    ];

    final insights = _buildInsights(
      glucose: glucose,
      medication: medication,
      exercise: exercise,
      meal: meal,
      totalScore: total,
    );

    final trend = includeTrend
        ? await _buildTrend(userId: userId, period: period, currentScore: total)
        : 'Not enough data';

    return HealthScore(
      totalScore: total,
      status: _statusFromScore(total),
      trend: trend,
      calculatedAt: DateTime.now(),
      periodLabel: range.label,
      breakdown: breakdown,
      insights: insights,
      summary: _buildSummary(total, breakdown),
    );
  }

  Future<_CategoryScoreResult> _computeGlucoseScore({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final readings = await _glucoseReadingService.getReadingsByDateRange(
        userId,
        start,
        end,
      );

      if (readings.isEmpty) {
        return const _CategoryScoreResult(
          score: 12,
          maxScore: _maxGlucoseScore,
          note: 'Not enough glucose data in selected period.',
          hasEnoughData: false,
        );
      }

      final total = readings.length;
      final normal = readings.where(_isNormalReading).length;
      final high = readings.where((r) => r.glucoseLevel > 140).length;
      final low = readings.where((r) => r.glucoseLevel < 70).length;

      final normalRatio = normal / total;
      final highRatio = high / total;
      final lowRatio = low / total;

      final base = (normalRatio * _maxGlucoseScore);
      final penalty = (highRatio * 8) + (lowRatio * 12);
      var score = (base - penalty).round();

      if (total < 3) {
        score = score.clamp(0, 28).toInt();
      }

      return _CategoryScoreResult(
        score: score.clamp(0, _maxGlucoseScore).toInt(),
        maxScore: _maxGlucoseScore,
        note:
            'Normal: $normal/$total, High: $high/$total, Low: $low/$total.',
        hasEnoughData: total >= 3,
      );
    } catch (_) {
      return const _CategoryScoreResult(
        score: 14,
        maxScore: _maxGlucoseScore,
        note: 'Glucose data unavailable. Applied fallback score.',
        hasEnoughData: false,
      );
    }
  }

  Future<_CategoryScoreResult> _computeMedicationScore({
    required String userId,
    required DateTime start,
    required DateTime end,
    required HealthScorePeriod period,
  }) async {
    try {
      final medicines = await _medicineService.getMedicines(userId);
      final entries = await _medicineService.getEntries(
        userId,
        fromDate: _formatDate(start),
        toDate: _formatDate(end),
      );

      if (medicines.isEmpty) {
        return const _CategoryScoreResult(
          score: 16,
          maxScore: _maxMedicationScore,
          note: 'No medicines configured. Neutral score applied.',
          hasEnoughData: false,
        );
      }

      if (entries.isEmpty) {
        return const _CategoryScoreResult(
          score: 10,
          maxScore: _maxMedicationScore,
          note: 'No medicine intake logs found in selected period.',
          hasEnoughData: false,
        );
      }

      final takenCount = entries.where((e) => e.taken).length;
      final adherenceRatio = takenCount / entries.length;

      final score = _scoreByRatio(
        ratio: adherenceRatio,
        max: _maxMedicationScore,
        excellentThreshold: 1.0,
        goodThreshold: 0.85,
        fairThreshold: 0.70,
        lowThreshold: 0.50,
      );

      return _CategoryScoreResult(
        score: score,
        maxScore: _maxMedicationScore,
        note:
            'Taken entries: $takenCount/${entries.length} (${(adherenceRatio * 100).round()}%).',
        hasEnoughData: entries.length >= _minimumDataPoints(period),
      );
    } catch (_) {
      return const _CategoryScoreResult(
        score: 12,
        maxScore: _maxMedicationScore,
        note: 'Medication data unavailable. Applied fallback score.',
        hasEnoughData: false,
      );
    }
  }

  Future<_CategoryScoreResult> _computeExerciseScore({
    required String userId,
    required DateTime start,
    required DateTime end,
    required HealthScorePeriod period,
  }) async {
    try {
      final activities = await _activityService.getActivities(
        userId: userId,
        fromDate: _formatDate(start),
        toDate: _formatDate(end),
      );

      if (activities.isEmpty) {
        return const _CategoryScoreResult(
          score: 4,
          maxScore: _maxExerciseScore,
          note: 'No exercise logs found in selected period.',
          hasEnoughData: false,
        );
      }

      final activeDays = activities.map((a) => a.date).toSet().length;
      final targetDays = _targetActiveDays(period);
      final ratio = (activeDays / targetDays).clamp(0.0, 1.0);
      final score = (ratio * _maxExerciseScore).round();

      return _CategoryScoreResult(
        score: score,
        maxScore: _maxExerciseScore,
        note: 'Active days: $activeDays / target $targetDays.',
        hasEnoughData: activeDays >= (targetDays / 2).ceil(),
      );
    } catch (_) {
      return const _CategoryScoreResult(
        score: 8,
        maxScore: _maxExerciseScore,
        note: 'Exercise data unavailable. Applied fallback score.',
        hasEnoughData: false,
      );
    }
  }

  Future<_CategoryScoreResult> _computeMealScore({
    required String userId,
    required DateTime start,
    required DateTime end,
    required HealthScorePeriod period,
  }) async {
    try {
      final meals = await _mealService.getMeals(
        userId: userId,
        fromDate: _formatDate(start),
        toDate: _formatDate(end),
      );

      if (meals.isEmpty) {
        return const _CategoryScoreResult(
          score: 3,
          maxScore: _maxMealScore,
          note: 'No meal logs found in selected period.',
          hasEnoughData: false,
        );
      }

      final mealDays = meals.map((m) => m.date).toSet().length;
      final targetDays = _targetMealDays(period);
      final ratio = (mealDays / targetDays).clamp(0.0, 1.0);
      final score = (ratio * _maxMealScore).round();

      return _CategoryScoreResult(
        score: score,
        maxScore: _maxMealScore,
        note: 'Meal-logged days: $mealDays / target $targetDays.',
        hasEnoughData: mealDays >= (targetDays / 2).ceil(),
      );
    } catch (_) {
      return const _CategoryScoreResult(
        score: 7,
        maxScore: _maxMealScore,
        note: 'Meal data unavailable. Applied fallback score.',
        hasEnoughData: false,
      );
    }
  }

  Future<String> _buildTrend({
    required String userId,
    required HealthScorePeriod period,
    required int currentScore,
  }) async {
    final previousRange = _resolvePreviousPeriodRange(period);
    if (previousRange == null) {
      return 'Not enough data';
    }

    try {
      final previous = await _calculateTotalForCustomRange(
        userId: userId,
        start: previousRange.start,
        end: previousRange.end,
        period: period,
      );

      if (!previous.hasEnoughData) {
        return 'Not enough data';
      }

      final delta = currentScore - previous.total;
      if (delta >= 5) {
        return 'Improving';
      }
      if (delta <= -5) {
        return 'Declining';
      }
      return 'Stable';
    } catch (_) {
      return 'Not enough data';
    }
  }

  Future<_ScoreSnapshot> _calculateTotalForCustomRange({
    required String userId,
    required DateTime start,
    required DateTime end,
    required HealthScorePeriod period,
  }) async {
    final glucose = await _computeGlucoseScore(
      userId: userId,
      start: start,
      end: end,
    );
    final medication = await _computeMedicationScore(
      userId: userId,
      start: start,
      end: end,
      period: period,
    );
    final exercise = await _computeExerciseScore(
      userId: userId,
      start: start,
      end: end,
      period: period,
    );
    final meal = await _computeMealScore(
      userId: userId,
      start: start,
      end: end,
      period: period,
    );

    final total = (glucose.score + medication.score + exercise.score + meal.score)
        .clamp(0, 100)
        .toInt();

    return _ScoreSnapshot(
      total: total,
      hasEnoughData: glucose.hasEnoughData,
    );
  }

  List<String> _buildInsights({
    required _CategoryScoreResult glucose,
    required _CategoryScoreResult medication,
    required _CategoryScoreResult exercise,
    required _CategoryScoreResult meal,
    required int totalScore,
  }) {
    final insights = <String>[];

    if (glucose.score >= 32) {
      insights.add('Most glucose readings are within the target range. Keep it up.');
    } else if (glucose.score < 20) {
      insights.add('Frequent out-of-range glucose readings were observed.');
    }

    if (medication.score < 15) {
      insights.add('Medication adherence could be improved for better stability.');
    }

    if (exercise.score < 10) {
      insights.add('Consider adding regular exercise logs during the week.');
    }

    if (meal.score < 8) {
      insights.add('Meal tracking consistency is low in the selected period.');
    }

    if (insights.isEmpty) {
      if (totalScore >= 85) {
        insights.add('Excellent consistency across your recent health habits.');
      } else {
        insights.add('Steady progress. Continue logging regularly for better insights.');
      }
    }

    return insights;
  }

  String _buildSummary(int totalScore, List<HealthScoreBreakdown> breakdown) {
    final sorted = List<HealthScoreBreakdown>.from(breakdown)
      ..sort((a, b) {
        final aRatio = a.maxScore == 0 ? 0 : a.score / a.maxScore;
        final bRatio = b.maxScore == 0 ? 0 : b.score / b.maxScore;
        return aRatio.compareTo(bRatio);
      });

    final weakest = sorted.first;
    return '${_statusFromScore(totalScore)} health score. Focus on ${weakest.category.toLowerCase()} to improve further.';
  }

  String _statusFromScore(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }

  int _scoreByRatio({
    required double ratio,
    required int max,
    required double excellentThreshold,
    required double goodThreshold,
    required double fairThreshold,
    required double lowThreshold,
  }) {
    if (ratio >= excellentThreshold) return max;
    if (ratio >= goodThreshold) return (max * 0.88).round();
    if (ratio >= fairThreshold) return (max * 0.72).round();
    if (ratio >= lowThreshold) return (max * 0.52).round();
    return (max * 0.28).round();
  }

  _PeriodRange _resolvePeriodRange(HealthScorePeriod period) {
    final now = DateTime.now();
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
      999,
    );

    switch (period) {
      case HealthScorePeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        return _PeriodRange(start: start, end: end, label: 'Today');
      case HealthScorePeriod.last7Days:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return _PeriodRange(start: start, end: end, label: 'Last 7 days');
      case HealthScorePeriod.last30Days:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        return _PeriodRange(start: start, end: end, label: 'Last 30 days');
    }
  }

  _PeriodRange? _resolvePreviousPeriodRange(HealthScorePeriod period) {
    final current = _resolvePeriodRange(period);

    switch (period) {
      case HealthScorePeriod.today:
        return null;
      case HealthScorePeriod.last7Days:
        final previousEnd = current.start.subtract(const Duration(microseconds: 1));
        final previousStart = DateTime(
          previousEnd.year,
          previousEnd.month,
          previousEnd.day,
        ).subtract(const Duration(days: 6));
        return _PeriodRange(
          start: previousStart,
          end: previousEnd,
          label: 'Previous 7 days',
        );
      case HealthScorePeriod.last30Days:
        final previousEnd = current.start.subtract(const Duration(microseconds: 1));
        final previousStart = DateTime(
          previousEnd.year,
          previousEnd.month,
          previousEnd.day,
        ).subtract(const Duration(days: 29));
        return _PeriodRange(
          start: previousStart,
          end: previousEnd,
          label: 'Previous 30 days',
        );
    }
  }

  bool _isNormalReading(GlucoseReading reading) {
    return reading.glucoseLevel >= 70 && reading.glucoseLevel <= 140;
  }

  int _targetActiveDays(HealthScorePeriod period) {
    switch (period) {
      case HealthScorePeriod.today:
        return 1;
      case HealthScorePeriod.last7Days:
        return 4;
      case HealthScorePeriod.last30Days:
        return 12;
    }
  }

  int _targetMealDays(HealthScorePeriod period) {
    switch (period) {
      case HealthScorePeriod.today:
        return 1;
      case HealthScorePeriod.last7Days:
        return 5;
      case HealthScorePeriod.last30Days:
        return 18;
    }
  }

  int _minimumDataPoints(HealthScorePeriod period) {
    switch (period) {
      case HealthScorePeriod.today:
        return 1;
      case HealthScorePeriod.last7Days:
        return 3;
      case HealthScorePeriod.last30Days:
        return 8;
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _CategoryScoreResult {
  const _CategoryScoreResult({
    required this.score,
    required this.maxScore,
    required this.note,
    required this.hasEnoughData,
  });

  final int score;
  final int maxScore;
  final String note;
  final bool hasEnoughData;
}

class _PeriodRange {
  const _PeriodRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

class _ScoreSnapshot {
  const _ScoreSnapshot({required this.total, required this.hasEnoughData});

  final int total;
  final bool hasEnoughData;
}

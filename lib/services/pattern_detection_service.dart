import 'dart:math';

import 'package:dia_plus/models/activity.dart';
import 'package:dia_plus/models/glucose_pattern_insight.dart';
import 'package:dia_plus/models/glucose_pattern_type.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/insight_severity.dart';
import 'package:dia_plus/models/meal.dart';
import 'package:dia_plus/services/activity_service.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:dia_plus/services/meal_service.dart';
import 'package:intl/intl.dart';

/// Detects explainable, rule-based glucose patterns for Smart Insights.
class PatternDetectionService {
  PatternDetectionService({
    GlucoseReadingService? glucoseReadingService,
    MealService? mealService,
    ActivityService? activityService,
  }) : _glucoseReadingService = glucoseReadingService ?? GlucoseReadingService(),
       _mealService = mealService,
       _activityService = activityService;

  final GlucoseReadingService _glucoseReadingService;
  final MealService? _mealService;
  final ActivityService? _activityService;

  static const double _lowThreshold = 70;
  static const double _targetUpperThreshold = 140;
  static const double _highThreshold = 140;
  static const double _afterMealSpikeThreshold = 180;

  static const int _morningHighCountThreshold = 3;
  static const int _afterMealSpikeCountThreshold = 3;
  static const int _lowEpisodeThreshold = 2;
  static const int _minimumReadingsForVariability = 5;
  static const int _minimumReadingsForTrend = 4;
  static const int _minimumReadingsForGoodControl = 5;

  static const double _variabilityStdDevThreshold = 40;
  static const double _variabilityRangeThreshold = 120;
  static const double _goodControlRatioThreshold = 0.70;
  static const double _trendAvgImprovementThreshold = 10;
  static const double _trendRatioChangeThreshold = 0.10;

  Future<List<GlucosePatternInsight>> detectInsightsForLast7Days(
    String userId,
  ) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    return detectInsightsForRange(userId, start, end);
  }

  Future<List<GlucosePatternInsight>> detectInsightsForLast30Days(
    String userId,
  ) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    return detectInsightsForRange(userId, start, end);
  }

  Future<List<GlucosePatternInsight>> detectInsightsForRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final normalized = _normalizeRange(start, end);
    final rangeStart = normalized.$1;
    final rangeEnd = normalized.$2;
    final periodLabel = _periodLabel(rangeStart, rangeEnd);

    final readings = await _glucoseReadingService.getReadingsByDateRange(
      userId,
      rangeStart,
      rangeEnd,
    );

    if (readings.isEmpty) {
      return const [];
    }

    final sortedReadings = [...readings]..sort((a, b) => a.date.compareTo(b.date));
    final previousRange = _previousRange(rangeStart, rangeEnd);
    final previousReadings = await _glucoseReadingService.getReadingsByDateRange(
      userId,
      previousRange.$1,
      previousRange.$2,
    );

    final insights = <GlucosePatternInsight>[];

    final morningHigh = detectMorningHighPattern(sortedReadings, periodLabel);
    if (morningHigh != null) {
      insights.add(morningHigh);
    }

    final afterMeal = detectAfterMealSpikes(sortedReadings, periodLabel);
    if (afterMeal != null) {
      insights.add(afterMeal);
    }

    final frequentLow = detectFrequentLowPattern(sortedReadings, periodLabel);
    if (frequentLow != null) {
      insights.add(frequentLow);
    }

    final unstable = detectVariability(sortedReadings, periodLabel);
    if (unstable != null) {
      insights.add(unstable);
    }

    final trend = detectTrendComparison(
      currentReadings: sortedReadings,
      previousReadings: previousReadings,
      periodLabel: periodLabel,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    if (trend != null) {
      insights.add(trend);
    }

    final goodControl = detectGoodControl(sortedReadings, periodLabel);
    if (goodControl != null) {
      insights.add(goodControl);
    }

    final missedMonitoring = detectMissedMonitoringPattern(
      sortedReadings,
      rangeStart,
      rangeEnd,
      periodLabel,
    );
    if (missedMonitoring != null) {
      insights.add(missedMonitoring);
    }

    final meals = await _safeFetchMeals(
      userId: userId,
      start: rangeStart,
      end: rangeEnd,
    );
    final activities = await _safeFetchActivities(
      userId: userId,
      start: rangeStart,
      end: rangeEnd,
    );

    final activityInsight = detectExerciseRelatedImprovement(
      readings: sortedReadings,
      activities: activities,
      periodLabel: periodLabel,
    );
    if (activityInsight != null) {
      insights.add(activityInsight);
    }

    final mealInsight = detectMealRelatedSpike(
      readings: sortedReadings,
      meals: meals,
      periodLabel: periodLabel,
    );
    if (mealInsight != null) {
      // Keep the meal-linked spike insight and remove the generic one to avoid duplicates.
      insights.removeWhere(
        (insight) => insight.type == GlucosePatternType.afterMealSpike,
      );
      insights.add(mealInsight);
    }

    // Avoid conflicting signals: suppress positive-control insight when risk insights exist.
    final hasRiskInsight = insights.any(
      (insight) =>
          insight.severity == InsightSeverity.warning ||
          insight.severity == InsightSeverity.critical,
    );
    if (hasRiskInsight) {
      insights.removeWhere(
        (insight) => insight.type == GlucosePatternType.goodControl,
      );
    }

    insights.sort(_compareInsights);
    return insights;
  }

  GlucosePatternInsight? detectMorningHighPattern(
    List<GlucoseReading> readings,
    String periodLabel,
  ) {
    final candidates = readings.where((reading) {
      final hour = reading.date.hour;
      final mealTime = reading.mealTime.toLowerCase();
      final isMorningWindow = hour < 11;
      final isMorningMealTag = mealTime.contains('fasting') ||
          mealTime.contains('morning') ||
          mealTime.contains('breakfast');
      return isMorningWindow || isMorningMealTag;
    }).toList();

    if (candidates.length < _morningHighCountThreshold) {
      return null;
    }

    final matches = readings.where((reading) {
      final hour = reading.date.hour;
      final mealTime = reading.mealTime.toLowerCase();
      final isMorningWindow = hour < 11;
      final isMorningMealTag = mealTime.contains('fasting') ||
          mealTime.contains('morning') ||
          mealTime.contains('breakfast');
      final isHigh = reading.glucoseLevel >= _highThreshold;
      return isHigh && (isMorningWindow || isMorningMealTag);
    }).toList();

    final highRatio = matches.length / candidates.length;
    if (matches.length < _morningHighCountThreshold || highRatio < 0.40) {
      return null;
    }

    return _buildInsight(
      type: GlucosePatternType.morningHigh,
      title: 'Repeated High Morning Readings',
      message:
          'High morning glucose readings were recorded ${matches.length} times (of ${candidates.length} morning checks) in $periodLabel.',
      severity: InsightSeverity.warning,
      periodLabel: periodLabel,
      supportingCount: matches.length,
      relevanceLabel: _relevanceLabel(matches.length),
      recommendedAction:
          'Review bedtime meals and morning routine. Consider discussing fasting targets with your doctor.',
      relatedReadingIds: matches.map((reading) => reading.id).toList(),
      detectedAt: _mostRecentDate(matches),
    );
  }

  GlucosePatternInsight? detectAfterMealSpikes(
    List<GlucoseReading> readings,
    String periodLabel,
  ) {
    final candidates = readings.where((reading) {
      final mealTime = reading.mealTime.toLowerCase();
      return mealTime.contains('after') || mealTime.contains('post');
    }).toList();

    if (candidates.length < _afterMealSpikeCountThreshold) {
      return null;
    }

    final matches = readings.where((reading) {
      final mealTime = reading.mealTime.toLowerCase();
      final isAfterMealTag =
          mealTime.contains('after') || mealTime.contains('post');
      return isAfterMealTag && reading.glucoseLevel >= _afterMealSpikeThreshold;
    }).toList();

    final spikeRatio = matches.length / candidates.length;
    if (matches.length < _afterMealSpikeCountThreshold || spikeRatio < 0.40) {
      return null;
    }

    return _buildInsight(
      type: GlucosePatternType.afterMealSpike,
      title: 'After-Meal Spikes Detected',
      message:
          'Glucose spikes after meals were seen ${matches.length} times (of ${candidates.length} post-meal checks) in $periodLabel.',
      severity: InsightSeverity.warning,
      periodLabel: periodLabel,
      supportingCount: matches.length,
      relevanceLabel: _relevanceLabel(matches.length),
      recommendedAction:
          'Consider meal portion timing and post-meal activity to reduce spikes.',
      relatedReadingIds: matches.map((reading) => reading.id).toList(),
      detectedAt: _mostRecentDate(matches),
    );
  }

  GlucosePatternInsight? detectFrequentLowPattern(
    List<GlucoseReading> readings,
    String periodLabel,
  ) {
    final matches = readings
        .where((reading) => reading.glucoseLevel < _lowThreshold)
        .toList();

    if (matches.length < _lowEpisodeThreshold) {
      return null;
    }

    final severity = matches.length >= 3
        ? InsightSeverity.critical
        : InsightSeverity.warning;

    return _buildInsight(
      type: GlucosePatternType.frequentLow,
      title: 'Frequent Low Readings',
      message:
          '${matches.length} low glucose readings were detected in $periodLabel.',
      severity: severity,
      periodLabel: periodLabel,
      supportingCount: matches.length,
      relevanceLabel: _relevanceLabel(matches.length),
      recommendedAction:
          'Watch for hypoglycemia symptoms and review meal/medicine timing with your care team.',
      relatedReadingIds: matches.map((reading) => reading.id).toList(),
      detectedAt: _mostRecentDate(matches),
    );
  }

  GlucosePatternInsight? detectVariability(
    List<GlucoseReading> readings,
    String periodLabel,
  ) {
    if (readings.length < _minimumReadingsForVariability) {
      return null;
    }

    final values = readings.map((reading) => reading.glucoseLevel).toList();
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = maxValue - minValue;
    final standardDeviation = _standardDeviation(values);

    if (range < _variabilityRangeThreshold &&
        standardDeviation < _variabilityStdDevThreshold) {
      return null;
    }

    final severity = standardDeviation >= 60 || range >= 160
        ? InsightSeverity.critical
        : InsightSeverity.warning;

    return _buildInsight(
      type: GlucosePatternType.unstableReadings,
      title: 'High Glucose Variability',
      message:
          'Readings were unstable in $periodLabel (range ${range.toStringAsFixed(0)} mg/dL).',
      severity: severity,
      periodLabel: periodLabel,
      supportingCount: readings.length,
      relevanceLabel: _relevanceLabel(readings.length),
      recommendedAction:
          'Try keeping meal timing, medication, and testing schedule consistent to improve stability.',
      relatedReadingIds: readings.map((reading) => reading.id).toList(),
      detectedAt: _mostRecentDate(readings),
    );
  }

  GlucosePatternInsight? detectTrendComparison({
    required List<GlucoseReading> currentReadings,
    required List<GlucoseReading> previousReadings,
    required String periodLabel,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (currentReadings.length < _minimumReadingsForTrend ||
        previousReadings.length < _minimumReadingsForTrend) {
      return null;
    }

    final currentAverage = _average(currentReadings);
    final previousAverage = _average(previousReadings);
    final currentNormalRatio = _normalRatio(currentReadings);
    final previousNormalRatio = _normalRatio(previousReadings);

    final avgDelta = previousAverage - currentAverage;
    final ratioDelta = currentNormalRatio - previousNormalRatio;

    final daySpan = rangeEnd.difference(rangeStart).inDays + 1;

    if (avgDelta >= _trendAvgImprovementThreshold ||
        ratioDelta >= _trendRatioChangeThreshold) {
      final type = daySpan <= 8
          ? GlucosePatternType.weeklyImprovement
          : GlucosePatternType.improvingTrend;
      return _buildInsight(
        type: type,
        title: 'Improving Trend',
        message:
            'Readings were more stable than the previous period, with better in-range control.',
        severity: InsightSeverity.success,
        periodLabel: periodLabel,
        supportingCount: currentReadings.length,
        relevanceLabel: _comparisonRelevance(
          currentReadings.length,
          previousReadings.length,
        ),
        recommendedAction:
            'Keep following your current routine and continue regular monitoring.',
        relatedReadingIds: currentReadings.map((reading) => reading.id).toList(),
        detectedAt: _mostRecentDate(currentReadings),
      );
    }

    if (avgDelta <= -_trendAvgImprovementThreshold ||
        ratioDelta <= -_trendRatioChangeThreshold) {
      final type = daySpan <= 8
          ? GlucosePatternType.weeklyDecline
          : GlucosePatternType.worseningTrend;
      return _buildInsight(
        type: type,
        title: 'Worsening Trend',
        message:
            'Recent readings suggest reduced glucose control compared with the previous period.',
        severity: InsightSeverity.warning,
        periodLabel: periodLabel,
        supportingCount: currentReadings.length,
        relevanceLabel: _comparisonRelevance(
          currentReadings.length,
          previousReadings.length,
        ),
        recommendedAction:
            'Review recent food, activity, and medication changes, and consult your doctor if this continues.',
        relatedReadingIds: currentReadings.map((reading) => reading.id).toList(),
        detectedAt: _mostRecentDate(currentReadings),
      );
    }

    return null;
  }

  GlucosePatternInsight? detectGoodControl(
    List<GlucoseReading> readings,
    String periodLabel,
  ) {
    if (readings.length < _minimumReadingsForGoodControl) {
      return null;
    }

    final ratio = _normalRatio(readings);
    if (ratio < _goodControlRatioThreshold) {
      return null;
    }

    final inRangeCount = (ratio * readings.length).round();

    return _buildInsight(
      type: GlucosePatternType.goodControl,
      title: 'Good Glucose Control',
      message:
          'Most recent readings were within target range ($inRangeCount/${readings.length}) in $periodLabel.',
      severity: InsightSeverity.success,
      periodLabel: periodLabel,
      supportingCount: inRangeCount,
      relevanceLabel: _relevanceLabel(inRangeCount),
      recommendedAction:
          'Great progress. Continue your current monitoring and healthy routine.',
      relatedReadingIds: readings.map((reading) => reading.id).toList(),
      detectedAt: _mostRecentDate(readings),
    );
  }

  GlucosePatternInsight? detectMissedMonitoringPattern(
    List<GlucoseReading> readings,
    DateTime start,
    DateTime end,
    String periodLabel,
  ) {
    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 1) {
      return null;
    }

    final daysWithReadings = readings
        .map((reading) => DateTime(reading.date.year, reading.date.month, reading.date.day))
        .toSet();

    final missingDays = <DateTime>[];
    for (int i = 0; i < totalDays; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      if (!daysWithReadings.contains(day)) {
        missingDays.add(day);
      }
    }

    final missingRatio = missingDays.length / totalDays;
    final needsInsight = (totalDays <= 7 && missingDays.length >= 2) ||
        (totalDays > 7 && missingRatio >= 0.30);

    if (!needsInsight) {
      return null;
    }

    return _buildInsight(
      type: GlucosePatternType.missedMonitoringPattern,
      title: 'Inconsistent Monitoring',
      message:
          'Glucose tracking was missed on ${missingDays.length} day(s) in $periodLabel.',
      severity: InsightSeverity.info,
      periodLabel: periodLabel,
      supportingCount: missingDays.length,
      relevanceLabel: _relevanceLabel(missingDays.length),
      recommendedAction:
          'Try setting reminders to log readings consistently each day.',
      detectedAt: readings.isEmpty ? DateTime.now() : _mostRecentDate(readings),
    );
  }

  GlucosePatternInsight? detectExerciseRelatedImprovement({
    required List<GlucoseReading> readings,
    required List<Activity> activities,
    required String periodLabel,
  }) {
    if (activities.isEmpty || readings.length < _minimumReadingsForTrend) {
      return null;
    }

    final activeDays = activities
        .map((activity) => _safeParseSimpleDate(activity.date))
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();

    if (activeDays.isEmpty) {
      return null;
    }

    final activeDayReadings = <GlucoseReading>[];
    final inactiveDayReadings = <GlucoseReading>[];

    for (final reading in readings) {
      final day = DateTime(reading.date.year, reading.date.month, reading.date.day);
      if (activeDays.contains(day)) {
        activeDayReadings.add(reading);
      } else {
        inactiveDayReadings.add(reading);
      }
    }

    if (activeDayReadings.length < 2 || inactiveDayReadings.length < 2) {
      return null;
    }

    final activeRatio = _normalRatio(activeDayReadings);
    final inactiveRatio = _normalRatio(inactiveDayReadings);
    final activeAvg = _average(activeDayReadings);
    final inactiveAvg = _average(inactiveDayReadings);

    final improved = (activeRatio - inactiveRatio) >= 0.15 ||
        (inactiveAvg - activeAvg) >= _trendAvgImprovementThreshold;

    if (!improved) {
      return null;
    }

    return _buildInsight(
      type: GlucosePatternType.exerciseRelatedImprovement,
      title: 'Better Control on Active Days',
      message:
          'Glucose control appears better on days with logged activity in $periodLabel.',
      severity: InsightSeverity.success,
      periodLabel: periodLabel,
      supportingCount: activeDayReadings.length,
      relevanceLabel: _relevanceLabel(activeDayReadings.length),
      recommendedAction:
          'Keep regular physical activity in your routine to support glucose control.',
      relatedReadingIds: activeDayReadings.map((reading) => reading.id).toList(),
      detectedAt: _mostRecentDate(activeDayReadings),
    );
  }

  GlucosePatternInsight? detectMealRelatedSpike({
    required List<GlucoseReading> readings,
    required List<Meal> meals,
    required String periodLabel,
  }) {
    if (meals.isEmpty) {
      return null;
    }

    final mealDays = meals
        .map((meal) => _safeParseSimpleDate(meal.date))
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();

    if (mealDays.isEmpty) {
      return null;
    }

    final spikes = readings.where((reading) {
      final day = DateTime(reading.date.year, reading.date.month, reading.date.day);
      final afterMealTag = _isAfterMealTag(reading.mealTime);
      return mealDays.contains(day) &&
          afterMealTag &&
          reading.glucoseLevel >= _afterMealSpikeThreshold;
    }).toList();

    if (spikes.length < _afterMealSpikeCountThreshold) {
      return null;
    }

    return _buildInsight(
      type: GlucosePatternType.mealRelatedSpike,
      title: 'Meal-Related Spikes',
      message:
          'Post-meal spikes were observed ${spikes.length} times on logged meal days in $periodLabel.',
      severity: InsightSeverity.warning,
      periodLabel: periodLabel,
      supportingCount: spikes.length,
      relevanceLabel: _relevanceLabel(spikes.length),
      recommendedAction:
          'Review meal composition and consider lighter carbohydrate load for meals that trigger spikes.',
      relatedReadingIds: spikes.map((reading) => reading.id).toList(),
      detectedAt: _mostRecentDate(spikes),
    );
  }

  Future<List<Meal>> _safeFetchMeals({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final service = _mealService ?? MealService();
      return await service.getMeals(
        userId: userId,
        fromDate: _simpleDate(start),
        toDate: _simpleDate(end),
      );
    } catch (_) {
      return const [];
    }
  }

  Future<List<Activity>> _safeFetchActivities({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final service = _activityService ?? ActivityService();
      return await service.getActivities(
        userId: userId,
        fromDate: _simpleDate(start),
        toDate: _simpleDate(end),
      );
    } catch (_) {
      return const [];
    }
  }

  int _compareInsights(
    GlucosePatternInsight first,
    GlucosePatternInsight second,
  ) {
    final severityCompare =
        _severityPriority(second.severity).compareTo(_severityPriority(first.severity));
    if (severityCompare != 0) {
      return severityCompare;
    }

    final supportCompare = second.supportingCount.compareTo(first.supportingCount);
    if (supportCompare != 0) {
      return supportCompare;
    }

    return second.detectedAt.compareTo(first.detectedAt);
  }

  int _severityPriority(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.critical:
        return 4;
      case InsightSeverity.warning:
        return 3;
      case InsightSeverity.success:
        return 2;
      case InsightSeverity.info:
        return 1;
    }
  }

  GlucosePatternInsight _buildInsight({
    required GlucosePatternType type,
    required String title,
    required String message,
    required InsightSeverity severity,
    required String periodLabel,
    required int supportingCount,
    required String relevanceLabel,
    required String recommendedAction,
    required DateTime detectedAt,
    List<String> relatedReadingIds = const [],
  }) {
    final createdAt = DateTime.now();
    return GlucosePatternInsight(
      id: _insightId(type, detectedAt, supportingCount),
      type: type,
      title: title,
      message: message,
      severity: severity,
      detectedAt: detectedAt,
      periodLabel: periodLabel,
      supportingCount: supportingCount,
      relevanceLabel: relevanceLabel,
      recommendedAction: recommendedAction,
      relatedReadingIds: relatedReadingIds,
      createdAt: createdAt,
    );
  }

  String _insightId(
    GlucosePatternType type,
    DateTime detectedAt,
    int supportingCount,
  ) {
    return '${type.name}_${detectedAt.millisecondsSinceEpoch}_$supportingCount';
  }

  (DateTime, DateTime) _normalizeRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
    );

    if (normalizedEnd.isBefore(normalizedStart)) {
      final swappedStart = DateTime(end.year, end.month, end.day);
      final swappedEnd = DateTime(
        start.year,
        start.month,
        start.day,
        23,
        59,
        59,
        999,
      );
      return (swappedStart, swappedEnd);
    }
    return (normalizedStart, normalizedEnd);
  }

  (DateTime, DateTime) _previousRange(DateTime start, DateTime end) {
    final daySpan = end.difference(start).inDays + 1;
    final previousEnd = start.subtract(const Duration(milliseconds: 1));
    final previousStart = DateTime(
      previousEnd.year,
      previousEnd.month,
      previousEnd.day,
    ).subtract(Duration(days: daySpan - 1));

    return (previousStart, previousEnd);
  }

  DateTime _mostRecentDate(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return DateTime.now();
    }
    return readings.map((reading) => reading.date).reduce(
      (first, second) => first.isAfter(second) ? first : second,
    );
  }

  double _average(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return 0;
    }
    final total = readings
        .map((reading) => reading.glucoseLevel)
        .reduce((first, second) => first + second);
    return total / readings.length;
  }

  double _normalRatio(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return 0;
    }
    final inRange = readings.where((reading) {
      return reading.glucoseLevel >= _lowThreshold &&
          reading.glucoseLevel <= _targetUpperThreshold;
    }).length;
    return inRange / readings.length;
  }

  double _standardDeviation(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final mean = values.reduce((first, second) => first + second) / values.length;
    final variance = values
            .map((value) => pow(value - mean, 2).toDouble())
            .reduce((first, second) => first + second) /
        values.length;
    return sqrt(variance);
  }

  String _simpleDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  DateTime? _safeParseSimpleDate(String value) {
    return DateTime.tryParse(value);
  }

  String _periodLabel(DateTime start, DateTime end) {
    final formatter = DateFormat('d MMM yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  bool _isAfterMealTag(String mealTime) {
    final tag = mealTime.toLowerCase();
    return tag.contains('after') || tag.contains('post');
  }

  String _relevanceLabel(int supportingCount) {
    if (supportingCount >= 6) {
      return 'High';
    }
    if (supportingCount >= 3) {
      return 'Medium';
    }
    return 'Low';
  }

  String _comparisonRelevance(int currentCount, int previousCount) {
    final total = currentCount + previousCount;
    if (total >= 20) {
      return 'High';
    }
    if (total >= 10) {
      return 'Medium';
    }
    return 'Low';
  }
}

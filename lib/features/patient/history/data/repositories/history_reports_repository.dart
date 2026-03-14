import 'package:dia_plus/features/patient/history/models/glucose_trend_period.dart';
import 'package:dia_plus/features/patient/history/models/glucose_trend_point.dart';
import 'package:dia_plus/features/patient/history/models/history_date_range.dart';
import 'package:dia_plus/features/patient/history/models/history_statistics.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:intl/intl.dart';

/// Repository for fetching and transforming glucose history data.
class HistoryReportsRepository {
  HistoryReportsRepository({GlucoseReadingService? readingService})
    : _readingService = readingService ?? GlucoseReadingService();

  final GlucoseReadingService _readingService;

  Future<List<GlucoseReading>> fetchReadings(
    String userId,
    HistoryDateRange dateRange,
  ) async {
    final readings = await _readingService.getReadingsByDateRange(
      userId,
      dateRange.normalizedStart,
      dateRange.normalizedEnd,
    );
    readings.sort((a, b) => b.date.compareTo(a.date));
    return readings;
  }

  HistoryStatistics buildStatistics(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return HistoryStatistics.empty();
    }

    final levels = readings.map((reading) => reading.glucoseLevel).toList();
    final total = levels.reduce((first, second) => first + second);

    return HistoryStatistics(
      averageGlucose: total / levels.length,
      highestGlucose: levels.reduce(
        (first, second) => first > second ? first : second,
      ),
      lowestGlucose: levels.reduce(
        (first, second) => first < second ? first : second,
      ),
      totalReadings: readings.length,
    );
  }

  List<GlucoseTrendPoint> buildTrendPoints(
    List<GlucoseReading> readings,
    GlucoseTrendPeriod period,
  ) {
    if (readings.isEmpty) {
      return const [];
    }

    final sorted = [...readings]..sort((a, b) => a.date.compareTo(b.date));
    final buckets = <DateTime, List<GlucoseReading>>{};

    for (final reading in sorted) {
      final bucketStart = _bucketStart(reading.date, period);
      buckets.putIfAbsent(bucketStart, () => []).add(reading);
    }

    final orderedEntries = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return orderedEntries.asMap().entries.map((entry) {
      final readingsInBucket = entry.value.value;
      final total = readingsInBucket
          .map((reading) => reading.glucoseLevel)
          .reduce((first, second) => first + second);

      return GlucoseTrendPoint(
        axisValue: entry.key.toDouble(),
        label: _formatBucketLabel(entry.value.key, period),
        averageGlucose: total / readingsInBucket.length,
        readingCount: readingsInBucket.length,
      );
    }).toList();
  }

  Map<DateTime, List<GlucoseReading>> groupReadingsByDay(
    List<GlucoseReading> readings,
  ) {
    final grouped = <DateTime, List<GlucoseReading>>{};

    for (final reading in readings) {
      final day = DateTime(
        reading.date.year,
        reading.date.month,
        reading.date.day,
      );
      grouped.putIfAbsent(day, () => []).add(reading);
    }

    final orderedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return {
      for (final entry in orderedEntries)
        entry.key: entry.value..sort((a, b) => b.date.compareTo(a.date)),
    };
  }

  DateTime _bucketStart(DateTime date, GlucoseTrendPeriod period) {
    switch (period) {
      case GlucoseTrendPeriod.daily:
        return DateTime(date.year, date.month, date.day);
      case GlucoseTrendPeriod.weekly:
        final daysToSubtract = date.weekday - DateTime.monday;
        final monday = date.subtract(Duration(days: daysToSubtract));
        return DateTime(monday.year, monday.month, monday.day);
      case GlucoseTrendPeriod.monthly:
        return DateTime(date.year, date.month);
    }
  }

  String _formatBucketLabel(DateTime bucketStart, GlucoseTrendPeriod period) {
    switch (period) {
      case GlucoseTrendPeriod.daily:
        return DateFormat('d MMM').format(bucketStart);
      case GlucoseTrendPeriod.weekly:
        final weekEnd = bucketStart.add(const Duration(days: 6));
        return '${DateFormat('d MMM').format(bucketStart)}\n${DateFormat('d MMM').format(weekEnd)}';
      case GlucoseTrendPeriod.monthly:
        return DateFormat('MMM yyyy').format(bucketStart);
    }
  }
}

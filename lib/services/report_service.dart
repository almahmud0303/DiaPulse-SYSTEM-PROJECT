import 'package:dia_plus/features/patient/history/models/history_date_range.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/glucose_report_data.dart';
import 'package:dia_plus/models/glucose_report_stats.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';

/// Orchestrates fetching, filtering, and statistical analysis of glucose data
/// to produce a [GlucoseReportData] DTO ready for PDF generation.
class ReportService {
  ReportService({
    GlucoseReadingService? readingService,
    AuthService? authService,
  }) : _readingService = readingService ?? GlucoseReadingService(),
       _authService = authService ?? AuthService();

  final GlucoseReadingService _readingService;
  final AuthService _authService;

  /// Fetches readings for [userId] within [dateRange], computes stats
  /// and trend summary, then returns the fully populated [GlucoseReportData].
  Future<GlucoseReportData> buildReportData(
    String userId,
    HistoryDateRange dateRange,
  ) async {
    final AppUser? user = await _authService.getAppUser();

    final readings = await _readingService.getReadingsByDateRange(
      userId,
      dateRange.normalizedStart,
      dateRange.normalizedEnd,
    );
    readings.sort((a, b) => b.date.compareTo(a.date));

    final stats = _computeStats(readings);
    final trendSummary = _computeTrendSummary(stats);

    int? age;
    double? weight;
    double? height;
    String? diabetesType;

    if (user != null) {
      final extra = user.extra;

      final rawAge = extra['age'];
      if (rawAge is int) {
        age = rawAge;
      } else if (rawAge is num) {
        age = rawAge.toInt();
      } else if (rawAge is String) {
        age = int.tryParse(rawAge);
      }

      final rawWeight = extra['weight'];
      if (rawWeight is double) {
        weight = rawWeight;
      } else if (rawWeight is num) {
        weight = rawWeight.toDouble();
      } else if (rawWeight is String) {
        weight = double.tryParse(rawWeight);
      }

      final rawHeight = extra['height'];
      if (rawHeight is double) {
        height = rawHeight;
      } else if (rawHeight is num) {
        height = rawHeight.toDouble();
      } else if (rawHeight is String) {
        height = double.tryParse(rawHeight);
      }

      final rawDiabetes = extra['diabetesType'];
      if (rawDiabetes is String && rawDiabetes.isNotEmpty) {
        diabetesType = _formatDiabetesType(rawDiabetes);
      }
    }

    return GlucoseReportData(
      patientName: user?.displayName ?? 'Unknown Patient',
      patientAge: age,
      patientWeight: weight,
      patientHeight: height,
      diabetesType: diabetesType,
      rangeLabel: dateRange.label,
      rangeStart: dateRange.normalizedStart,
      rangeEnd: dateRange.normalizedEnd,
      generatedAt: DateTime.now(),
      readings: readings,
      stats: stats,
      trendSummary: trendSummary,
    );
  }

  GlucoseReportStats _computeStats(List<GlucoseReading> readings) {
    if (readings.isEmpty) return GlucoseReportStats.empty();

    final levels = readings.map((r) => r.glucoseLevel).toList();
    final total = levels.fold<double>(0.0, (sum, v) => sum + v);

    int lowCount = 0;
    int normalCount = 0;
    int highCount = 0;
    int veryHighCount = 0;

    for (final r in readings) {
      switch (r.getStatus()) {
        case 'Low':
          lowCount++;
          break;
        case 'Normal':
          normalCount++;
          break;
        case 'High':
          highCount++;
          break;
        default:
          veryHighCount++;
      }
    }

    return GlucoseReportStats(
      totalReadings: readings.length,
      averageGlucose: total / readings.length,
      highestGlucose: levels.reduce((a, b) => a > b ? a : b),
      lowestGlucose: levels.reduce((a, b) => a < b ? a : b),
      lowCount: lowCount,
      normalCount: normalCount,
      highCount: highCount,
      veryHighCount: veryHighCount,
    );
  }

  String _computeTrendSummary(GlucoseReportStats stats) {
    if (!stats.hasData) {
      return 'No readings found in the selected period.';
    }

    final total = stats.totalReadings;
    final highRatio = (stats.highCount + stats.veryHighCount) / total;
    final lowRatio = stats.lowCount / total;
    final normalRatio = stats.normalCount / total;

    if (normalRatio >= 0.75) {
      return 'Overall glucose control appears stable. Most readings were within the normal range.';
    } else if (highRatio >= 0.5) {
      return 'Frequent elevated glucose readings were observed. Consider reviewing meal and medication plans with your doctor.';
    } else if (lowRatio >= 0.3) {
      return 'Several low glucose readings suggest a possible hypoglycemia risk. Please consult your doctor.';
    } else if (highRatio >= 0.3) {
      return 'Several high readings were recorded in this period. Continued monitoring is recommended.';
    } else {
      return 'Glucose levels showed mixed variation in this period. Continue regular monitoring.';
    }
  }

  String _formatDiabetesType(String raw) {
    switch (raw) {
      case 'type1':
        return 'Type 1 Diabetes';
      case 'type2':
        return 'Type 2 Diabetes';
      case 'gestational':
        return 'Gestational Diabetes';
      case 'prediabetes':
        return 'Prediabetes';
      default:
        return raw
            .split('_')
            .map(
              (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ')
            .trim();
    }
  }
}

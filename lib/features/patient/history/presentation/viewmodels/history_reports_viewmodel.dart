import 'package:dia_plus/features/patient/history/data/repositories/history_reports_repository.dart';
import 'package:dia_plus/features/patient/history/models/glucose_trend_period.dart';
import 'package:dia_plus/features/patient/history/models/glucose_trend_point.dart';
import 'package:dia_plus/features/patient/history/models/history_date_range.dart';
import 'package:dia_plus/features/patient/history/models/history_statistics.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:flutter/material.dart';

/// Viewmodel for the history and reports screen.
class HistoryReportsViewModel extends ChangeNotifier {
  HistoryReportsViewModel({required HistoryReportsRepository repository})
    : _repository = repository;

  final HistoryReportsRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  HistoryDateRange _selectedDateRange = HistoryDateRange.last7Days();
  GlucoseTrendPeriod _selectedTrendPeriod = GlucoseTrendPeriod.daily;
  List<GlucoseReading> _readings = const [];
  List<GlucoseTrendPoint> _trendPoints = const [];
  HistoryStatistics _statistics = HistoryStatistics.empty();
  bool _disposed = false;
  int _refreshGeneration = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userId => _userId;
  HistoryDateRange get selectedDateRange => _selectedDateRange;
  GlucoseTrendPeriod get selectedTrendPeriod => _selectedTrendPeriod;
  List<GlucoseReading> get readings => _readings;
  List<GlucoseTrendPoint> get trendPoints => _trendPoints;
  HistoryStatistics get statistics => _statistics;
  bool get hasReadings => _readings.isNotEmpty;

  Map<DateTime, List<GlucoseReading>> get groupedReadings {
    return _repository.groupReadingsByDay(_readings);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> initialize(String? userId) async {
    _userId = userId;
    if (_userId == null) {
      _isLoading = false;
      _errorMessage = null;
      _readings = const [];
      _trendPoints = const [];
      _statistics = HistoryStatistics.empty();
      _safeNotifyListeners();
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    if (_userId == null) return;
    final callGeneration = ++_refreshGeneration;

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final readings = await _repository.fetchReadings(
        _userId!,
        _selectedDateRange,
      );
      if (_disposed || callGeneration != _refreshGeneration) return;
      _readings = readings;
      _statistics = _repository.buildStatistics(readings);
      _trendPoints = _repository.buildTrendPoints(
        readings,
        _selectedTrendPeriod,
      );
    } catch (error) {
      if (_disposed || callGeneration != _refreshGeneration) return;
      _errorMessage = 'Failed to load history data.';
      _readings = const [];
      _trendPoints = const [];
      _statistics = HistoryStatistics.empty();
    } finally {
      if (!_disposed && callGeneration == _refreshGeneration) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> selectDateRange(HistoryDateRange dateRange) async {
    _selectedDateRange = dateRange;
    await refresh();
  }

  Future<void> selectCustomDateRange(DateTimeRange dateRange) async {
    await selectDateRange(HistoryDateRange.custom(dateRange));
  }

  void selectTrendPeriod(GlucoseTrendPeriod trendPeriod) {
    if (_selectedTrendPeriod == trendPeriod) {
      return;
    }

    _selectedTrendPeriod = trendPeriod;
    _trendPoints = _repository.buildTrendPoints(
      _readings,
      _selectedTrendPeriod,
    );
    _safeNotifyListeners();
  }
}

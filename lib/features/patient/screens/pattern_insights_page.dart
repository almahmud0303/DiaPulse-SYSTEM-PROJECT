import 'package:dia_plus/features/patient/widgets/pattern_insight_card.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/glucose_pattern_insight.dart';
import 'package:dia_plus/services/pattern_detection_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatternInsightsPage extends StatefulWidget {
  const PatternInsightsPage({super.key});

  @override
  State<PatternInsightsPage> createState() => _PatternInsightsPageState();
}

enum _InsightsPeriod {
  last7Days,
  last30Days,
  custom,
}

class _PatternInsightsPageState extends State<PatternInsightsPage> {
  final PatternDetectionService _patternDetectionService =
      PatternDetectionService();

  String? _userId;
  bool _loading = true;
  String? _error;
  List<GlucosePatternInsight> _insights = const [];

  _InsightsPeriod _selectedPeriod = _InsightsPeriod.last7Days;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final userId = _userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _insights = const [];
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      late final List<GlucosePatternInsight> detected;
      switch (_selectedPeriod) {
        case _InsightsPeriod.last7Days:
          detected = await _patternDetectionService.detectInsightsForLast7Days(
            userId,
          );
          break;
        case _InsightsPeriod.last30Days:
          detected = await _patternDetectionService.detectInsightsForLast30Days(
            userId,
          );
          break;
        case _InsightsPeriod.custom:
          final range = _customRange ?? _defaultCustomRange();
          detected = await _patternDetectionService.detectInsightsForRange(
            userId,
            range.start,
            range.end,
          );
          break;
      }

      if (!mounted) return;
      setState(() {
        _insights = detected;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load smart insights.';
      });
    }
  }

  Future<void> _selectCustomRange() async {
    final initialRange = _customRange ?? _defaultCustomRange();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
    );

    if (picked == null) return;

    setState(() {
      _customRange = _normalizeRange(picked);
      _selectedPeriod = _InsightsPeriod.custom;
    });

    await _loadInsights();
  }

  DateTimeRange _defaultCustomRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _normalizeRange(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _onPeriodSelected(_InsightsPeriod period) async {
    if (_selectedPeriod == period) {
      if (period == _InsightsPeriod.custom) {
        await _selectCustomRange();
      }
      return;
    }

    if (period == _InsightsPeriod.custom) {
      await _selectCustomRange();
      return;
    }

    setState(() {
      _selectedPeriod = period;
    });
    await _loadInsights();
  }

  String _periodLabel(_InsightsPeriod period) {
    switch (period) {
      case _InsightsPeriod.last7Days:
        return 'Last 7 Days';
      case _InsightsPeriod.last30Days:
        return 'Last 30 Days';
      case _InsightsPeriod.custom:
        return 'Custom Range';
    }
  }

  String _customRangeLabel() {
    final range = _customRange;
    if (range == null) {
      return 'Pick Dates';
    }

    final formatter = DateFormat('d MMM yyyy');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Smart Insights'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadInsights,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInsights,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_userId == null) {
      return _buildNotLoggedInState();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodSelector(),
        if (_selectedPeriod == _InsightsPeriod.custom) ...[
          const SizedBox(height: 10),
          _buildCustomRangeChip(),
        ],
        const SizedBox(height: 14),
        if (_loading)
          _buildLoadingState()
        else if (_error != null)
          _buildErrorState()
        else if (_insights.isEmpty)
          _buildEmptyState()
        else
          ..._insights.map(
            (insight) => PatternInsightCard(
              insight: insight,
              margin: const EdgeInsets.only(bottom: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _InsightsPeriod.values.map((period) {
        final selected = _selectedPeriod == period;
        return ChoiceChip(
          label: Text(_periodLabel(period)),
          selected: selected,
          selectedColor: Colors.teal.shade100,
          onSelected: (_) => _onPeriodSelected(period),
        );
      }).toList(),
    );
  }

  Widget _buildCustomRangeChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: const Icon(Icons.date_range_outlined, size: 18),
        label: Text(_customRangeLabel()),
        backgroundColor: AppTheme.surfaceAltColor(context),
        onPressed: _selectCustomRange,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 44),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadInsights,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final subtitle = _selectedPeriod == _InsightsPeriod.custom
        ? 'No major glucose patterns were detected for the selected custom range.'
        : 'No major glucose patterns were detected for this period.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, color: Colors.teal.shade400, size: 44),
          const SizedBox(height: 10),
          const Text(
            'No Insights Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.person_off, size: 62, color: Colors.grey.shade400),
        const SizedBox(height: 14),
        Text(
          'Please log in to view smart insights.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}

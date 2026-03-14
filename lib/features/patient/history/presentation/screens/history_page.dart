import 'package:dia_plus/features/patient/history/data/repositories/history_reports_repository.dart';
import 'package:dia_plus/features/patient/history/presentation/viewmodels/history_reports_viewmodel.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/glucose_readings_history_list.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/glucose_trend_chart.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_date_filter_bar.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_empty_state.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_header.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_loading_state.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_stats_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final HistoryReportsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HistoryReportsViewModel(
      repository: HistoryReportsRepository(),
    );
    _viewModel.initialize(FirebaseAuth.instance.currentUser?.uid);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateRange() async {
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _viewModel.selectedDateRange.toDateTimeRange(),
    );

    if (selectedRange != null) {
      await _viewModel.selectCustomDateRange(selectedRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            if (_viewModel.userId == null) {
              return _buildNotLoggedInState();
            }

            if (_viewModel.isLoading) {
              return const HistoryLoadingState();
            }

            if (_viewModel.errorMessage != null) {
              return _buildErrorState();
            }

            return RefreshIndicator(
              onRefresh: _viewModel.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: HistoryHeader()),
                  SliverToBoxAdapter(
                    child: HistoryDateFilterBar(
                      selectedRange: _viewModel.selectedDateRange,
                      onRangeSelected: (range) =>
                          _viewModel.selectDateRange(range),
                      onCustomRangePressed: _pickCustomDateRange,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HistoryStatsSection(
                      statistics: _viewModel.statistics,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: GlucoseTrendChart(
                      trendPoints: _viewModel.trendPoints,
                      selectedPeriod: _viewModel.selectedTrendPeriod,
                      onPeriodSelected: _viewModel.selectTrendPeriod,
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _viewModel.hasReadings
                        ? GlucoseReadingsHistoryList(
                            groupedReadings: _viewModel.groupedReadings,
                          )
                        : const HistoryEmptyState(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Please log in to view history reports.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _viewModel.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

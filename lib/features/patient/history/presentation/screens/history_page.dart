import 'package:dia_plus/features/patient/history/data/repositories/history_reports_repository.dart';
import 'package:dia_plus/features/patient/screens/export_report_page.dart';
import 'package:dia_plus/features/patient/history/presentation/viewmodels/history_reports_viewmodel.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/glucose_readings_history_list.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/glucose_trend_chart.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_date_filter_bar.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_empty_state.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_header.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_loading_state.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_stats_section.dart';
import 'package:dia_plus/features/patient/screens/pattern_insights_page.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExportReportPage()),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Export'),
      ),
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
                  SliverToBoxAdapter(child: _buildSmartInsightsEntry()),
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

  Widget _buildSmartInsightsEntry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatternInsightsPage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.insights_outlined,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Insights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Detect glucose patterns and trends from your recent logs.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

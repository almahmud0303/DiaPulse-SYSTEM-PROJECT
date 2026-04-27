import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/services/step_counter_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StepHistoryPage extends StatefulWidget {
  const StepHistoryPage({super.key});

  @override
  State<StepHistoryPage> createState() => _StepHistoryPageState();
}

class _StepHistoryPageState extends State<StepHistoryPage> {
  static const int _goal = 10000;

  bool _loading = true;
  String? _error;
  // date string → step count, sorted descending
  List<MapEntry<String, int>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'Not signed in.';
      });
      return;
    }
    try {
      final history = await StepCounterService.getStepHistory(uid, days: 30);
      final sorted = history.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      if (mounted) {
        setState(() {
          _entries = sorted;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load step history. Pull down to retry.';
          _loading = false;
        });
      }
    }
  }

  // ── Stats ──────────────────────────────────────────────────

  int get _totalDays => _entries.length;

  int get _avgSteps {
    if (_entries.isEmpty) return 0;
    final sum = _entries.fold(0, (s, e) => s + e.value);
    return sum ~/ _entries.length;
  }

  MapEntry<String, int>? get _bestDay {
    if (_entries.isEmpty) return null;
    return _entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  int get _goalMetDays => _entries.where((e) => e.value >= _goal).length;

  // Returns the last 7 entries sorted oldest→newest for the chart.
  List<MapEntry<String, int>> get _last7 {
    final recent = _entries.take(7).toList().reversed.toList();
    return recent;
  }

  // ── Helpers ────────────────────────────────────────────────

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      if (dt.year == today.year &&
          dt.month == today.month &&
          dt.day == today.day) {
        return 'Today';
      }
      if (dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day) {
        return 'Yesterday';
      }
      return DateFormat('EEE, MMM d').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _shortDay(String dateStr) {
    try {
      return DateFormat('EEE').format(DateTime.parse(dateStr));
    } catch (_) {
      return '';
    }
  }

  Color _stepColor(int steps) {
    if (steps >= _goal) return Colors.teal;
    if (steps >= 5000) return Colors.orange;
    return Colors.redAccent;
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Step History'),
        backgroundColor: AppTheme.backgroundColor(context),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null && _entries.isEmpty
                  ? _buildError()
                  : _buildBody(),
            ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSummaryRow(),
        const SizedBox(height: 20),
        if (_last7.isNotEmpty) ...[
          _buildChartCard(),
          const SizedBox(height: 20),
        ],
        _buildHistoryList(),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final best = _bestDay;
    return Row(
      children: [
        _buildStatCard(
          'Daily Avg',
          NumberFormat('#,###').format(_avgSteps),
          Icons.trending_up,
          Colors.blue,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          'Best Day',
          best == null ? '--' : NumberFormat('#,###').format(best.value),
          Icons.emoji_events_outlined,
          Colors.amber,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          'Goal Met',
          '$_goalMetDays / $_totalDays',
          Icons.flag_outlined,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardTintMintColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.secondaryLavender.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final maxVal = _last7.isEmpty
        ? _goal.toDouble()
        : _last7
            .map((e) => e.value.toDouble())
            .reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.25).clamp(_goal.toDouble(), 30000.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardTintMintColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryLavender.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: Colors.teal),
              const SizedBox(width: 8),
              const Text(
                'Last 7 Days',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'Goal: ${NumberFormat('#,###').format(_goal)} steps',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: _last7.asMap().entries.map((entry) {
                  final steps = entry.value.value.toDouble();
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: steps > 0 ? steps : 0.01,
                        color: _stepColor(entry.value.value),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _goal.toDouble(),
                      color: Colors.teal.withValues(alpha: 0.5),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.teal,
                        ),
                        labelResolver: (_) => '10k goal',
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= _last7.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _shortDay(_last7[i].key),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Column(
            children: [
              Icon(Icons.directions_walk_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No step data yet.\nStart walking with the app open.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Records',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 10),
        ...(_entries.map((entry) => _buildDayRow(entry.key, entry.value))),
      ],
    );
  }

  Widget _buildDayRow(String dateStr, int steps) {
    final color = _stepColor(steps);
    final pct = (steps / _goal).clamp(0.0, 1.0);
    final goalMet = steps >= _goal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardTintMintColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: goalMet
              ? Colors.teal.withValues(alpha: 0.4)
              : AppTheme.secondaryLavender.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.directions_walk_rounded,
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(dateStr),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goalMet ? 'Goal reached!' : '${(pct * 100).round()}% of goal',
                      style: TextStyle(
                        fontSize: 12,
                        color: goalMet
                            ? Colors.teal
                            : AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                NumberFormat('#,###').format(steps),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'steps',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
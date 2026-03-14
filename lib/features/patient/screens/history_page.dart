import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// History: date filter, daily/weekly/monthly graphs, stats (avg, max, min), list.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final GlucoseReadingService _readingService = GlucoseReadingService();

  String? _userId;
  bool _loading = true;
  List<GlucoseReading> _readings = [];
  HistoryFilter _filter = HistoryFilter.last7Days;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    if (_userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final all = await _readingService.getUserReadings(_userId!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      List<GlucoseReading> filtered;
      switch (_filter) {
        case HistoryFilter.today:
          filtered = all.where((r) {
            final d = r.date;
            return d.year == today.year && d.month == today.month && d.day == today.day;
          }).toList();
          break;
        case HistoryFilter.last7Days:
          final start = today.subtract(const Duration(days: 6));
          filtered = all.where((r) => !r.date.isBefore(start)).toList();
          break;
        case HistoryFilter.last30Days:
          final start = today.subtract(const Duration(days: 29));
          filtered = all.where((r) => !r.date.isBefore(start)).toList();
          break;
        case HistoryFilter.thisMonth:
          final start = DateTime(now.year, now.month, 1);
          filtered = all.where((r) => !r.date.isBefore(start)).toList();
          break;
      }
      filtered.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        setState(() {
        _readings = filtered;
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _readings = [];
        _loading = false;
      });
      }
    }
  }

  double get _average {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.glucoseLevel).reduce((a, b) => a + b) / _readings.length;
  }

  double get _highest {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.glucoseLevel).reduce((a, b) => a > b ? a : b);
  }

  double get _lowest {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.glucoseLevel).reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Please log in to view history', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReadings,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildFilterChips()),
                    SliverToBoxAdapter(child: _buildStatsCard()),
                    SliverToBoxAdapter(child: _buildGraphSection()),
                    SliverToBoxAdapter(child: _buildListHeader()),
                    _readings.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No readings in this period',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildListDelegate(
                              _buildGroupedList(),
                            ),
                          ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Graphs & statistics',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: HistoryFilter.values.map((f) {
            final isSelected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _filter = f;
                    _loadReadings();
                  });
                },
                selectedColor: Colors.teal.shade100,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem('Average', _readings.isEmpty ? '--' : '${_average.round()} mg/dL', Icons.analytics, Colors.blue),
          ),
          Expanded(
            child: _statItem('Highest', _readings.isEmpty ? '--' : '${_highest.round()} mg/dL', Icons.arrow_upward, Colors.red),
          ),
          Expanded(
            child: _statItem('Lowest', _readings.isEmpty ? '--' : '${_lowest.round()} mg/dL', Icons.arrow_downward, Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGraphSection() {
    if (_readings.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No data to show',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _filter == HistoryFilter.today ? 'Daily (by time)' : '${_filter.label} trend',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _filter == HistoryFilter.today ? _buildDailyChart() : _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart() {
    final points = _readings.map((r) => FlSpot(r.date.hour + r.date.minute / 60, r.glucoseLevel)).toList();
    points.sort((a, b) => a.x.compareTo(b.x));
    final maxY = _readings.isEmpty ? 200.0 : (_readings.map((r) => r.glucoseLevel).reduce((a, b) => a > b ? a : b) * 1.2).clamp(100, 400).toDouble();
    final minY = _readings.isEmpty ? 0.0 : (_readings.map((r) => r.glucoseLevel).reduce((a, b) => a < b ? a : b) * 0.8).clamp(0, 80).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: points.isEmpty ? [const FlSpot(0, 0)] : points,
            isCurved: true,
            color: Colors.teal,
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.1)),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}:00',
                style: TextStyle(color: Colors.grey[600], fontSize: 9),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildBarChart() {
    int daysCount;
    List<DateTime> dayStarts;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_filter) {
      case HistoryFilter.last7Days:
        daysCount = 7;
        dayStarts = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
        break;
      case HistoryFilter.last30Days:
        daysCount = 30;
        dayStarts = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));
        break;
      case HistoryFilter.thisMonth:
        final first = DateTime(now.year, now.month, 1);
        daysCount = today.difference(first).inDays + 1;
        dayStarts = List.generate(daysCount, (i) => first.add(Duration(days: i)));
        break;
      default:
        daysCount = 7;
        dayStarts = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    }

    final dayAverages = dayStarts.map((d) {
      final list = _readings.where((r) {
        return r.date.year == d.year && r.date.month == d.month && r.date.day == d.day;
      }).toList();
      if (list.isEmpty) return 0.0;
      return list.map((r) => r.glucoseLevel).reduce((a, b) => a + b) / list.length;
    }).toList();

    final maxVal = dayAverages.fold<double>(0, (p, v) => v > p ? v : p);
    final maxY = (maxVal > 0 ? (maxVal * 1.2).clamp(100.0, 400.0) : 200.0).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: dayAverages.asMap().entries.map((e) {
          final v = e.value;
          Color color = Colors.grey;
          if (v > 0) {
            if (v >= 70 && v <= 140) {
              color = Colors.green;
            } else if (v < 70) color = Colors.blue;
            else color = Colors.orange;
          }
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (v > 0 ? v : 0.01).toDouble(),
                color: color,
                width: (daysCount <= 7 ? 24 : (daysCount <= 30 ? 8 : 4)).toDouble(),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: daysCount <= 7 ? 1 : (daysCount <= 30 ? 5 : 10),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i >= 0 && i < dayStarts.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('d').format(dayStarts[i]),
                      style: TextStyle(color: Colors.grey[600], fontSize: 9),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        'Readings',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
      ),
    );
  }

  List<Widget> _buildGroupedList() {
    final Map<String, List<GlucoseReading>> grouped = {};
    for (final r in _readings) {
      final key = DateFormat('yyyy-MM-dd').format(r.date);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final list = <Widget>[];
    for (final key in keys) {
      final date = DateTime.parse(key);
      final isToday = key == DateFormat('yyyy-MM-dd').format(DateTime.now());
      final isYesterday = key == DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
      String label = isToday ? 'Today' : (isYesterday ? 'Yesterday' : DateFormat('EEEE, MMM d').format(date));
      list.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      ));
      for (final r in grouped[key]!) {
        list.add(_readingTile(r));
      }
    }
    list.add(const SizedBox(height: 24));
    return list;
  }

  Widget _readingTile(GlucoseReading r) {
    Color color = Colors.green;
    if (r.glucoseLevel < 70) {
      color = Colors.blue;
    } else if (r.glucoseLevel > 140) color = Colors.orange;
    if (r.glucoseLevel > 200) color = Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              r.glucoseLevel.toInt().toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.mealTime, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(DateFormat('h:mm a').format(r.date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (r.notes.isNotEmpty)
                  Text(r.notes, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('mg/dL', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

enum HistoryFilter {
  today('Today'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  thisMonth('This month');

  const HistoryFilter(this.label);
  final String label;
}

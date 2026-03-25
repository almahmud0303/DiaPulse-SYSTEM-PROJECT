import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/ui/responsive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// System monitoring: daily glucose readings trend and active users trend (last 14 days).
class AdminSystemMonitoringPage extends StatelessWidget {
  const AdminSystemMonitoringPage({super.key});

  static const int _days = 14;

  static List<DateTime> _lastNDays(int n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _parseReadingDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final days = _lastNDays(_days);
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Monitoring'),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last $_days days',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('glucose_readings').snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Column(
                        children: [
                          _ChartCard(
                            title: 'Glucose readings per day',
                            subtitle: 'Total readings logged each day (all patients)',
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          SizedBox(height: 20),
                          _ChartCard(
                            title: 'Active users per day',
                            subtitle: 'Patients who logged at least one reading that day',
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      );
                    }
                    if (snap.hasError) {
                      return _ChartCard(
                        title: 'Glucose readings per day',
                        subtitle: snap.error.toString(),
                        child: const SizedBox.shrink(),
                      );
                    }
                    final readingCounts = List<int>.filled(_days, 0);
                    final activeSets = List.generate(_days, (_) => <String>{});
                    for (final d in snap.data?.docs ?? const []) {
                      final data = d.data();
                      final dt = _parseReadingDate(data['date']);
                      if (dt == null) continue;
                      final uid = data['userId'] as String?;
                      final day = _dayOnly(dt);
                      for (var i = 0; i < days.length; i++) {
                        if (day.year == days[i].year &&
                            day.month == days[i].month &&
                            day.day == days[i].day) {
                          readingCounts[i]++;
                          if (uid != null && uid.isNotEmpty) {
                            activeSets[i].add(uid);
                          }
                          break;
                        }
                      }
                    }
                    final activeCounts = activeSets.map((s) => s.length).toList();
                    return Column(
                      children: [
                        _ChartCard(
                          title: 'Glucose readings per day',
                          subtitle: 'Total readings logged each day (all patients)',
                          child: _DailyBarChart(
                            days: days,
                            counts: readingCounts,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ChartCard(
                          title: 'Active users per day',
                          subtitle: 'Distinct patients who logged at least one reading that day',
                          child: _DailyBarChart(
                            days: days,
                            counts: activeCounts,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({
    required this.days,
    required this.counts,
    required this.color,
  });

  final List<DateTime> days;
  final List<int> counts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxY = counts.isEmpty
        ? 4.0
        : (counts.reduce((a, b) => a > b ? a : b) + 1).toDouble().clamp(2.0, 9999.0);

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY <= 5 ? 1 : null,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                final d = days[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('M/d').format(d),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(days.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[i].toDouble(),
                color: color,
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

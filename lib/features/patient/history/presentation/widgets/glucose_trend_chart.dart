import 'package:dia_plus/features/patient/history/models/glucose_trend_period.dart';
import 'package:dia_plus/features/patient/history/models/glucose_trend_point.dart';
import 'package:dia_plus/features/patient/history/presentation/widgets/history_period_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GlucoseTrendChart extends StatelessWidget {
  const GlucoseTrendChart({
    super.key,
    required this.trendPoints,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  final List<GlucoseTrendPoint> trendPoints;
  final GlucoseTrendPeriod selectedPeriod;
  final ValueChanged<GlucoseTrendPeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Glucose Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Daily, weekly, and monthly averages',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          HistoryPeriodSelector(
            selectedPeriod: selectedPeriod,
            onPeriodSelected: onPeriodSelected,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 260,
            child: trendPoints.isEmpty
                ? Center(
                    child: Text(
                      'No data available for this period',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : LineChart(_buildChartData(context)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final maxYValue = trendPoints
        .map((point) => point.averageGlucose)
        .reduce((first, second) => first > second ? first : second);
    final minYValue = trendPoints
        .map((point) => point.averageGlucose)
        .reduce((first, second) => first < second ? first : second);
    final minY = (minYValue - 30).clamp(0, 500).toDouble();
    final maxY = (maxYValue + 30).clamp(100, 500).toDouble();

    return LineChartData(
      minX: 0,
      maxX: trendPoints.length > 1 ? (trendPoints.length - 1).toDouble() : 1,
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 12,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final point = trendPoints[spot.x.toInt()];
              return LineTooltipItem(
                '${point.label}\n${point.averageGlucose.round()} mg/dL\n${point.readingCount} readings',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.withValues(alpha:0.16), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 44,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= trendPoints.length) {
                return const SizedBox.shrink();
              }

              final skipFactor = switch (selectedPeriod) {
                GlucoseTrendPeriod.daily => trendPoints.length > 10 ? 2 : 1,
                GlucoseTrendPeriod.weekly => 1,
                GlucoseTrendPeriod.monthly => 1,
              };

              if (index % skipFactor != 0 && index != trendPoints.length - 1) {
                return const SizedBox.shrink();
              }

              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 10,
                child: Text(
                  trendPoints[index].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 70,
            color: Colors.blue.withValues(alpha:0.5),
            dashArray: const [5, 4],
            strokeWidth: 1,
          ),
          HorizontalLine(
            y: 180,
            color: Colors.orange.withValues(alpha:0.5),
            dashArray: const [5, 4],
            strokeWidth: 1,
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: trendPoints
              .asMap()
              .entries
              .map(
                (entry) =>
                    FlSpot(entry.key.toDouble(), entry.value.averageGlucose),
              )
              .toList(),
          isCurved: true,
          color: Colors.teal.shade600,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final value = trendPoints[index].averageGlucose;
              final color = value < 70
                  ? Colors.blue
                  : value <= 180
                  ? Colors.green
                  : Colors.orange;
              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.teal.withValues(alpha:0.20),
                Colors.teal.withValues(alpha:0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

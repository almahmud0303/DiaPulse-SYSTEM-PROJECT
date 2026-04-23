import 'package:dia_plus/features/patient/history/models/history_statistics.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HistoryStatsSection extends StatelessWidget {
  const HistoryStatsSection({super.key, required this.statistics});

  final HistoryStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _HistoryStatCard(
            title: 'Average',
            value: statistics.hasData
                ? '${statistics.averageGlucose.round()} mg/dL'
                : '--',
            icon: Icons.analytics_outlined,
            color: AppTheme.secondaryLavender,
          ),
          _HistoryStatCard(
            title: 'Highest',
            value: statistics.hasData
                ? '${statistics.highestGlucose.round()} mg/dL'
                : '--',
            icon: Icons.arrow_upward_rounded,
            color: AppTheme.softError,
          ),
          _HistoryStatCard(
            title: 'Lowest',
            value: statistics.hasData
                ? '${statistics.lowestGlucose.round()} mg/dL'
                : '--',
            icon: Icons.arrow_downward_rounded,
            color: AppTheme.primaryMint,
          ),
          _HistoryStatCard(
            title: 'Readings',
            value: statistics.totalReadings.toString(),
            icon: Icons.receipt_long_outlined,
            color: AppTheme.accentPeach,
          ),
        ],
      ),
    );
  }
}

class _HistoryStatCard extends StatelessWidget {
  const _HistoryStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 700 ? (width - 56) / 4 : (width - 44) / 2;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardTintMintColor(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: AppTheme.textSecondaryColor(context))),
        ],
      ),
    );
  }
}

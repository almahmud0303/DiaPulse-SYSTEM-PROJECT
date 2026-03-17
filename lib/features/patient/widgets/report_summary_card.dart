import 'package:dia_plus/models/glucose_report_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays a preview summary of the upcoming report: period, statistics,
/// status breakdown, and trend sentence.
///
/// Purely presentational – all data comes from [reportData].
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({super.key, required this.reportData});

  final GlucoseReportData reportData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report Preview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildPeriodCard(),
        const SizedBox(height: 12),
        if (!reportData.stats.hasData)
          _buildEmptyState()
        else ...[
          _buildStatsRow(),
          const SizedBox(height: 12),
          _buildStatusBreakdown(),
          const SizedBox(height: 12),
          _buildTrendCard(),
        ],
      ],
    );
  }

  Widget _buildPeriodCard() {
    final df = DateFormat('d MMM yyyy');
    final stats = reportData.stats;

    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today,
              color: Colors.teal.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reportData.rangeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${df.format(reportData.rangeStart)} – ${df.format(reportData.rangeEnd)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.totalReadings}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'readings',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No readings for this period',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a different date range to generate a report.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final s = reportData.stats;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Average',
            s.averageGlucose.toStringAsFixed(1),
            'mg/dL',
            Colors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Highest',
            s.highestGlucose.toStringAsFixed(0),
            'mg/dL',
            Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Lowest',
            s.lowestGlucose.toStringAsFixed(0),
            'mg/dL',
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(bottom: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Text(unit, style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    final s = reportData.stats;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _breakdownItem('Low', s.lowCount, Colors.blue)),
              Expanded(
                child: _breakdownItem('Normal', s.normalCount, Colors.green),
              ),
              Expanded(
                child: _breakdownItem('High', s.highCount, Colors.orange),
              ),
              Expanded(
                child: _breakdownItem('Very High', s.veryHighCount, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, color: Colors.teal.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reportData.trendSummary,
              style: TextStyle(
                fontSize: 13,
                color: Colors.teal.shade900,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

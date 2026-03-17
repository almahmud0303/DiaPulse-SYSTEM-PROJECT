import 'package:dia_plus/models/health_score.dart';
import 'package:dia_plus/services/health_score_service.dart';
import 'package:flutter/material.dart';

class HealthScoreDetailsPage extends StatefulWidget {
  const HealthScoreDetailsPage({
    super.key,
    required this.userId,
    this.initialScore,
    this.initialPeriod = HealthScorePeriod.last7Days,
  });

  final String userId;
  final HealthScore? initialScore;
  final HealthScorePeriod initialPeriod;

  @override
  State<HealthScoreDetailsPage> createState() => _HealthScoreDetailsPageState();
}

class _HealthScoreDetailsPageState extends State<HealthScoreDetailsPage> {
  final HealthScoreService _healthScoreService = HealthScoreService();

  HealthScore? _score;
  HealthScorePeriod _period = HealthScorePeriod.last7Days;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _score = widget.initialScore;
    _loadScore();
  }

  Future<void> _loadScore() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final score = await _healthScoreService.calculateHealthScore(
        widget.userId,
        period: _period,
      );
      if (!mounted) return;
      setState(() {
        _score = score;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load health score: $e';
      });
    }
  }

  String _periodLabel(HealthScorePeriod period) {
    switch (period) {
      case HealthScorePeriod.today:
        return 'Today';
      case HealthScorePeriod.last7Days:
        return 'Last 7 days';
      case HealthScorePeriod.last30Days:
        return 'Last 30 days';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.teal;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _trendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.timeline;
    }
  }

  Widget _buildPeriodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: HealthScorePeriod.values.map((period) {
        final selected = period == _period;
        return ChoiceChip(
          label: Text(_periodLabel(period)),
          selected: selected,
          selectedColor: Colors.teal.shade100,
          onSelected: (value) {
            if (!value) return;
            setState(() => _period = period);
            _loadScore();
          },
        );
      }).toList(),
    );
  }

  Widget _buildScoreHeader(HealthScore score) {
    final color = _statusColor(score.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  score.status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(_trendIcon(score.trend), size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                score.trend,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.totalScore}',
                style: TextStyle(
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            score.summary,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(HealthScore score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Breakdown',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...score.breakdown.map((item) {
            final ratio = item.maxScore == 0
                ? 0.0
                : (item.score / item.maxScore).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.category,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${item.score} / ${item.maxScore}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ratio >= 0.75
                            ? Colors.green
                            : ratio >= 0.5
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                  if (item.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.note,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsights(HealthScore score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights & Recommendations',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (score.insights.isEmpty)
            Text(
              'No insights available yet.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else
            ...score.insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_outline, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowCalculated() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How This Score Is Calculated',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text('Glucose Control: up to 40 points'),
          Text('Medication Adherence: up to 25 points'),
          Text('Exercise Consistency: up to 20 points'),
          Text('Meal Logging: up to 15 points'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Health Score Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadScore,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadScore,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_score == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Health score is not available yet.'),
              )
            else ...[
              _buildScoreHeader(_score!),
              const SizedBox(height: 14),
              _buildBreakdown(_score!),
              const SizedBox(height: 14),
              _buildInsights(_score!),
              const SizedBox(height: 14),
              _buildHowCalculated(),
            ],
          ],
        ),
      ),
    );
  }
}

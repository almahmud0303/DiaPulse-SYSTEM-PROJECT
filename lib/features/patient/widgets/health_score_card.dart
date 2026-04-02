import 'package:dia_plus/models/health_score.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({
    super.key,
    this.healthScore,
    this.isLoading = false,
    this.errorMessage,
    this.onViewDetails,
    this.onTap,
    this.title = 'Health Score',
  });

  final HealthScore? healthScore;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onViewDetails;
  final VoidCallback? onTap;
  final String title;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF61B18B);
      case 'good':
        return AppTheme.primaryMint;
      case 'fair':
        return AppTheme.accentPeach;
      case 'poor':
        return AppTheme.softError;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _trendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return const Color(0xFF61B18B);
      case 'declining':
        return AppTheme.softError;
      case 'stable':
        return AppTheme.secondaryLavender;
      default:
        return AppTheme.textSecondary;
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

  String _formatScoreValue(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final score = healthScore;

    return Material(
      color: AppTheme.cardTintMint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardTintMint,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: isLoading
              ? const _HealthScoreLoadingState()
              : errorMessage != null
              ? _HealthScoreErrorState(message: errorMessage!)
              : score == null
              ? const _HealthScoreEmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useCompactAction = constraints.maxWidth < 350;
                        return Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryMint,
                                    AppTheme.secondaryLavender,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.monitor_heart_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    score.periodLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (onViewDetails != null)
                              useCompactAction
                                  ? IconButton(
                                      tooltip: 'View details',
                                      onPressed: onViewDetails,
                                      icon: const Icon(Icons.arrow_forward_ios),
                                      iconSize: 16,
                                    )
                                  : TextButton(
                                      onPressed: onViewDetails,
                                      child: const Text('View Details'),
                                    ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final statusChip = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              score.status,
                            ).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            score.status,
                            style: TextStyle(
                              color: _statusColor(score.status),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        );

                        final scoreText = FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatScoreValue(score.totalScore),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(score.status),
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '/ 100',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (constraints.maxWidth < 340) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              scoreText,
                              const SizedBox(height: 8),
                              statusChip,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: scoreText),
                            const SizedBox(width: 8),
                            statusChip,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _trendIcon(score.trend),
                          size: 18,
                          color: _trendColor(score.trend),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            score.trend,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _trendColor(score.trend),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (score.insights.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.secondaryLavender.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Text(
                          score.insights.first,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HealthScoreLoadingState extends StatelessWidget {
  const _HealthScoreLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HealthScoreErrorState extends StatelessWidget {
  const _HealthScoreErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.softError),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthScoreEmptyState extends StatelessWidget {
  const _HealthScoreEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Health score is not available yet.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

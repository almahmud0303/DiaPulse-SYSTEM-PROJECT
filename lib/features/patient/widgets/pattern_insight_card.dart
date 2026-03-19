import 'package:dia_plus/models/glucose_pattern_insight.dart';
import 'package:dia_plus/models/glucose_pattern_type.dart';
import 'package:dia_plus/models/insight_severity.dart';
import 'package:flutter/material.dart';

/// Reusable card for displaying a structured glucose pattern insight.
class PatternInsightCard extends StatelessWidget {
  const PatternInsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.showRecommendedAction = true,
    this.compact = false,
    this.margin,
  });

  final GlucosePatternInsight insight;
  final VoidCallback? onTap;
  final bool showRecommendedAction;
  final bool compact;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colors = _palette(context, insight.severity);
    final icon = _typeIcon(insight.type);

    return Container(
      margin: margin,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        compact ? 12 : 14,
                        14,
                        compact ? 12 : 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, icon, colors),
                          SizedBox(height: compact ? 8 : 10),
                          Text(
                            insight.message,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade800,
                              height: 1.35,
                            ),
                          ),
                          if (showRecommendedAction &&
                              insight.recommendedAction.trim().isNotEmpty) ...[
                            SizedBox(height: compact ? 8 : 10),
                            _buildRecommendedAction(context, colors),
                          ],
                          const SizedBox(height: 10),
                          _buildFooter(context, colors),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, IconData icon, _InsightPalette colors) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade900,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.chipBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colors.accent, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.title, style: titleStyle),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Pill(
                    label: _severityLabel(insight.severity),
                    textColor: colors.accent,
                    backgroundColor: colors.chipBackground,
                  ),
                  _Pill(
                    label: insight.relevanceLabel,
                    textColor: Colors.grey.shade700,
                    backgroundColor: Colors.grey.shade100,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedAction(BuildContext context, _InsightPalette colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.actionBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: colors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight.recommendedAction,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, _InsightPalette colors) {
    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w500,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _MetaItem(
          icon: Icons.date_range_outlined,
          label: insight.periodLabel,
          color: colors.accent,
          style: metaStyle,
        ),
        _MetaItem(
          icon: Icons.analytics_outlined,
          label: '${insight.supportingCount} supporting records',
          color: colors.accent,
          style: metaStyle,
        ),
      ],
    );
  }

  _InsightPalette _palette(BuildContext context, InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.critical:
        return _InsightPalette(
          accent: Colors.red.shade700,
          border: Colors.red.shade100,
          surface: Colors.white,
          chipBackground: Colors.red.shade50,
          actionBackground: Colors.red.shade50.withValues(alpha: 0.65),
          shadow: Colors.red.shade100.withValues(alpha: 0.45),
        );
      case InsightSeverity.warning:
        return _InsightPalette(
          accent: Colors.orange.shade700,
          border: Colors.orange.shade100,
          surface: Colors.white,
          chipBackground: Colors.orange.shade50,
          actionBackground: Colors.orange.shade50.withValues(alpha: 0.65),
          shadow: Colors.orange.shade100.withValues(alpha: 0.4),
        );
      case InsightSeverity.success:
        return _InsightPalette(
          accent: Colors.green.shade700,
          border: Colors.green.shade100,
          surface: Colors.white,
          chipBackground: Colors.green.shade50,
          actionBackground: Colors.green.shade50.withValues(alpha: 0.65),
          shadow: Colors.green.shade100.withValues(alpha: 0.4),
        );
      case InsightSeverity.info:
        return _InsightPalette(
          accent: Colors.teal.shade700,
          border: Colors.teal.shade100,
          surface: Colors.white,
          chipBackground: Colors.teal.shade50,
          actionBackground: Colors.teal.shade50.withValues(alpha: 0.65),
          shadow: Colors.teal.shade100.withValues(alpha: 0.4),
        );
    }
  }

  IconData _typeIcon(GlucosePatternType type) {
    switch (type) {
      case GlucosePatternType.morningHigh:
        return Icons.wb_sunny_outlined;
      case GlucosePatternType.afterMealSpike:
      case GlucosePatternType.mealRelatedSpike:
        return Icons.restaurant_outlined;
      case GlucosePatternType.frequentLow:
        return Icons.warning_amber_rounded;
      case GlucosePatternType.unstableReadings:
        return Icons.show_chart;
      case GlucosePatternType.improvingTrend:
      case GlucosePatternType.weeklyImprovement:
      case GlucosePatternType.exerciseRelatedImprovement:
        return Icons.trending_up;
      case GlucosePatternType.worseningTrend:
      case GlucosePatternType.weeklyDecline:
        return Icons.trending_down;
      case GlucosePatternType.goodControl:
        return Icons.check_circle_outline;
      case GlucosePatternType.missedMonitoringPattern:
        return Icons.schedule_outlined;
    }
  }

  String _severityLabel(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.critical:
        return 'Critical';
      case InsightSeverity.warning:
        return 'Warning';
      case InsightSeverity.success:
        return 'Positive';
      case InsightSeverity.info:
        return 'Info';
    }
  }
}

class _InsightPalette {
  const _InsightPalette({
    required this.accent,
    required this.border,
    required this.surface,
    required this.chipBackground,
    required this.actionBackground,
    required this.shadow,
  });

  final Color accent;
  final Color border;
  final Color surface;
  final Color chipBackground;
  final Color actionBackground;
  final Color shadow;
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.style,
  });

  final IconData icon;
  final String label;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: style),
      ],
    );
  }
}

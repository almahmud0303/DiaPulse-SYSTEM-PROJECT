import 'package:dia_plus/models/health_score_breakdown.dart';

class HealthScore {
  final int totalScore;
  final String status;
  final String trend;
  final DateTime calculatedAt;
  final String periodLabel;
  final List<HealthScoreBreakdown> breakdown;
  final List<String> insights;
  final String summary;

  HealthScore({
    required this.totalScore,
    required this.status,
    required this.trend,
    required this.calculatedAt,
    required this.periodLabel,
    required this.breakdown,
    this.insights = const [],
    this.summary = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'totalScore': totalScore,
      'status': status,
      'trend': trend,
      'calculatedAt': calculatedAt.toIso8601String(),
      'periodLabel': periodLabel,
      'breakdown': breakdown.map((item) => item.toMap()).toList(),
      'insights': insights,
      'summary': summary,
    };
  }

  factory HealthScore.fromMap(Map<String, dynamic> map) {
    return HealthScore(
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'Not available',
      trend: map['trend'] as String? ?? 'Not enough data',
      calculatedAt: DateTime.tryParse(map['calculatedAt'] as String? ?? '') ??
          DateTime.now(),
      periodLabel: map['periodLabel'] as String? ?? 'Last 7 days',
      breakdown: ((map['breakdown'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => HealthScoreBreakdown.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      insights: ((map['insights'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      summary: map['summary'] as String? ?? '',
    );
  }

  HealthScore copyWith({
    int? totalScore,
    String? status,
    String? trend,
    DateTime? calculatedAt,
    String? periodLabel,
    List<HealthScoreBreakdown>? breakdown,
    List<String>? insights,
    String? summary,
  }) {
    return HealthScore(
      totalScore: totalScore ?? this.totalScore,
      status: status ?? this.status,
      trend: trend ?? this.trend,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      periodLabel: periodLabel ?? this.periodLabel,
      breakdown: breakdown ?? this.breakdown,
      insights: insights ?? this.insights,
      summary: summary ?? this.summary,
    );
  }
}

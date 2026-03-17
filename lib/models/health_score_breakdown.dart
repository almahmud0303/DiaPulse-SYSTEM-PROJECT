class HealthScoreBreakdown {
  final String category;
  final int score;
  final int maxScore;
  final String note;

  HealthScoreBreakdown({
    required this.category,
    required this.score,
    required this.maxScore,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'score': score,
      'maxScore': maxScore,
      'note': note,
    };
  }

  factory HealthScoreBreakdown.fromMap(Map<String, dynamic> map) {
    return HealthScoreBreakdown(
      category: map['category'] as String? ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      maxScore: (map['maxScore'] as num?)?.toInt() ?? 0,
      note: map['note'] as String? ?? '',
    );
  }

  HealthScoreBreakdown copyWith({
    String? category,
    int? score,
    int? maxScore,
    String? note,
  }) {
    return HealthScoreBreakdown(
      category: category ?? this.category,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      note: note ?? this.note,
    );
  }
}

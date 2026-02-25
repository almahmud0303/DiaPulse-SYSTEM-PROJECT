/// Model representing a blood glucose reading
class GlucoseReading {
  final String id;
  final String userId;
  final DateTime date;
  final double glucoseLevel; // in mg/dL
  final String mealTime; // Fasting, Post Breakfast, etc.
  final DateTime createdAt;

  GlucoseReading({
    required this.id,
    required this.userId,
    required this.date,
    required this.glucoseLevel,
    required this.mealTime,
    required this.createdAt,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'glucoseLevel': glucoseLevel,
      'mealTime': mealTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from Firestore document
  factory GlucoseReading.fromMap(Map<String, dynamic> map) {
    return GlucoseReading(
      id: map['id'] as String,
      userId: map['userId'] as String,
      date: DateTime.parse(map['date'] as String),
      glucoseLevel: (map['glucoseLevel'] as num).toDouble(),
      mealTime: map['mealTime'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Get status based on glucose level
  String getStatus() {
    if (glucoseLevel < 70) {
      return 'Low';
    } else if (glucoseLevel >= 70 && glucoseLevel <= 140) {
      return 'Normal';
    } else if (glucoseLevel > 140 && glucoseLevel <= 200) {
      return 'High';
    } else {
      return 'Very High';
    }
  }

  /// Copy with method for updating fields
  GlucoseReading copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? glucoseLevel,
    String? mealTime,
    DateTime? createdAt,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      glucoseLevel: glucoseLevel ?? this.glucoseLevel,
      mealTime: mealTime ?? this.mealTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

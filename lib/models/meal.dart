/// A logged meal (category, carbs, notes) for a given date.
class Meal {
  final String id;
  final String userId;
  final String date; // yyyy-MM-dd
  final String category; // breakfast, lunch, dinner, snack
  final double carbs; // grams
  final String notes;
  final DateTime createdAt;

  Meal({
    required this.id,
    required this.userId,
    required this.date,
    required this.category,
    required this.carbs,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'category': category,
      'carbs': carbs,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      userId: map['userId'] as String,
      date: map['date'] as String? ?? '',
      category: map['category'] as String? ?? 'snack',
      carbs: (map['carbs'] is num) ? (map['carbs'] as num).toDouble() : 0.0,
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

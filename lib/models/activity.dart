/// A logged exercise/activity (type, duration, calories) for a given date.
class Activity {
  final String id;
  final String userId;
  final String date; // yyyy-MM-dd
  final String type; // walking, running, cycling, swimming, gym, other
  final int durationMinutes;
  final double calories;
  final String notes;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.durationMinutes,
    required this.calories,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'type': type,
      'durationMinutes': durationMinutes,
      'calories': calories,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as String,
      userId: map['userId'] as String,
      date: map['date'] as String? ?? '',
      type: map['type'] as String? ?? 'other',
      durationMinutes: (map['durationMinutes'] is num) ? (map['durationMinutes'] as num).toInt() : 0,
      calories: (map['calories'] is num) ? (map['calories'] as num).toDouble() : 0.0,
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

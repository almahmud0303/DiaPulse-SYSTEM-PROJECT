/// A medicine schedule (name, dosage, time, frequency).
class Medicine {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String time; // "09:00", "21:00"
  final String frequency; // daily, twice_daily, weekly
  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.time,
    required this.frequency,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'time': time,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      time: map['time'] as String? ?? '09:00',
      frequency: map['frequency'] as String? ?? 'daily',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

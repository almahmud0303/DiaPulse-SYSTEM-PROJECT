/// Log of medicine taken or missed on a given date.
class MedicineEntry {
  final String id;
  final String userId;
  final String medicineId;
  final String medicineName;
  final String date; // yyyy-MM-dd
  final bool taken;
  final DateTime? takenAt;
  final DateTime createdAt;

  MedicineEntry({
    required this.id,
    required this.userId,
    required this.medicineId,
    required this.medicineName,
    required this.date,
    required this.taken,
    this.takenAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'date': date,
      'taken': taken,
      'takenAt': takenAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicineEntry.fromMap(Map<String, dynamic> map) {
    return MedicineEntry(
      id: map['id'] as String,
      userId: map['userId'] as String,
      medicineId: map['medicineId'] as String,
      medicineName: map['medicineName'] as String? ?? '',
      date: map['date'] as String,
      taken: map['taken'] as bool? ?? false,
      takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt'] as String) : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

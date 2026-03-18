/// A prescription group: one save action by the doctor, with one or more medicines.
class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

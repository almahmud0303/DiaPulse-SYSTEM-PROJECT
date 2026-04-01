/// A prescription group: one save action by the doctor, with one or more medicines.
class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.createdAt,
    this.issuedByUid,
    this.issuedByName,
  });

  final String id;
  final String patientId;
  final DateTime createdAt;
  final String? issuedByUid;
  final String? issuedByName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'createdAt': createdAt.toIso8601String(),
      if (issuedByUid != null && issuedByUid!.isNotEmpty) 'issuedByUid': issuedByUid,
      if (issuedByName != null && issuedByName!.isNotEmpty) 'issuedByName': issuedByName,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      issuedByUid: map['issuedByUid'] as String?,
      issuedByName: map['issuedByName'] as String?,
    );
  }
}

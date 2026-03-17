/// A consultation note or diagnosis recorded by a doctor for a patient.
class ConsultationNote {
  const ConsultationNote({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.note,
    required this.diagnosis,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String note;
  final String diagnosis;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'note': note,
      'diagnosis': diagnosis,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory ConsultationNote.fromMap(Map<String, dynamic> map) {
    return ConsultationNote(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      doctorId: map['doctorId'] as String,
      note: map['note'] as String? ?? '',
      diagnosis: map['diagnosis'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }
}

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

  /// [documentId] is the Firestore document id when `id` is missing from stored fields.
  factory Prescription.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final id = _str(map['id']);
    final resolvedId =
        id.isNotEmpty ? id : (documentId ?? '');
    return Prescription(
      id: resolvedId,
      patientId: _str(map['patientId']),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      issuedByUid: map['issuedByUid'] as String?,
      issuedByName: map['issuedByName'] as String?,
    );
  }

  static String _str(dynamic v) => v == null ? '' : v.toString().trim();
}

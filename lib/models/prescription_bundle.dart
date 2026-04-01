import 'package:dia_plus/models/medicine.dart';

/// A single issued prescription, containing one or more medicines.
class PrescriptionBundle {
  const PrescriptionBundle({
    required this.patientId,
    required this.issuedAt,
    this.issuedByUid,
    this.issuedByName,
    required this.medicines,
  });

  final String patientId;
  final DateTime issuedAt;
  final String? issuedByUid;
  final String? issuedByName;
  final List<Medicine> medicines;
}


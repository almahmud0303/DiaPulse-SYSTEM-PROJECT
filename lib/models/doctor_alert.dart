/// Type of alert for the doctor.
enum DoctorAlertType {
  veryHighSugar,
  missedMedicine,
}

/// Single alert for the doctor (very high glucose or missed medicine).
class DoctorAlert {
  const DoctorAlert({
    required this.type,
    required this.patientId,
    required this.patientName,
    required this.title,
    required this.message,
    required this.timestamp,
    this.glucoseValue,
    this.readingDate,
    this.medicineName,
    this.entryDate,
  });

  final DoctorAlertType type;
  final String patientId;
  final String patientName;
  final String title;
  final String message;
  final DateTime timestamp;

  /// For [DoctorAlertType.veryHighSugar]: the glucose value (mg/dL).
  final double? glucoseValue;

  /// When the very-high reading was recorded.
  final DateTime? readingDate;

  /// For [DoctorAlertType.missedMedicine]: name of the medicine.
  final String? medicineName;

  /// For [DoctorAlertType.missedMedicine]: date of the missed entry (yyyy-MM-dd).
  final String? entryDate;
}

import 'package:dia_plus/models/doctor_alert.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:dia_plus/services/medicine_service.dart';

/// Threshold (mg/dL) above which a reading is considered "very high" for alerts.
const int kVeryHighGlucoseThreshold = 200;

/// Emergency thresholds aligned with emergency alert defaults.
const int kCriticalLowGlucoseThreshold = 60;
const int kCriticalHighGlucoseThreshold = 300;

/// Number of days to look back for very-high sugar and missed-medicine alerts.
const int kAlertLookbackDays = 2;

/// Fetches alerts for the doctor: critical/very high sugar and missed medicines.
class DoctorAlertService {
  final DoctorPatientService _patientService = DoctorPatientService();
  final GlucoseReadingService _glucoseService = GlucoseReadingService();
  final MedicineService _medicineService = MedicineService();

  /// Returns all alerts (critical/very high glucose in last [kAlertLookbackDays] days,
  /// and missed medicine entries in the same period), sorted by timestamp descending.
  Future<List<DoctorAlert>> getAlerts() async {
    final alerts = <DoctorAlert>[];
    final now = DateTime.now();
    final start = now.subtract(Duration(days: kAlertLookbackDays));
    final fromDate = _formatDate(start);
    final toDate = _formatDate(now);

    final patients = await _patientService.getPatients();
    for (final patient in patients) {
      // Glucose alerts in lookback period.
      final readings = await _glucoseService.getReadingsByDateRange(
        patient.uid,
        start,
        now,
      );
      for (final r in readings) {
        if (r.glucoseLevel < kCriticalLowGlucoseThreshold) {
          alerts.add(DoctorAlert(
            type: DoctorAlertType.veryHighSugar,
            patientId: patient.uid,
            patientName: patient.displayName.isEmpty ? patient.email : patient.displayName,
            title: 'Critical low glucose emergency',
            message: '${r.glucoseLevel.toStringAsFixed(0)} mg/dL (${r.mealTime}). Immediate follow-up recommended.',
            timestamp: r.createdAt,
            glucoseValue: r.glucoseLevel,
            readingDate: r.date,
          ));
          continue;
        }

        if (r.glucoseLevel > kCriticalHighGlucoseThreshold) {
          alerts.add(DoctorAlert(
            type: DoctorAlertType.veryHighSugar,
            patientId: patient.uid,
            patientName: patient.displayName.isEmpty ? patient.email : patient.displayName,
            title: 'Critical high glucose emergency',
            message: '${r.glucoseLevel.toStringAsFixed(0)} mg/dL (${r.mealTime}). Immediate follow-up recommended.',
            timestamp: r.createdAt,
            glucoseValue: r.glucoseLevel,
            readingDate: r.date,
          ));
          continue;
        }

        if (r.glucoseLevel >= kVeryHighGlucoseThreshold) {
          alerts.add(DoctorAlert(
            type: DoctorAlertType.veryHighSugar,
            patientId: patient.uid,
            patientName: patient.displayName.isEmpty ? patient.email : patient.displayName,
            title: 'Very high glucose',
            message: '${r.glucoseLevel.toStringAsFixed(0)} mg/dL (${r.mealTime}). Consider follow-up.',
            timestamp: r.createdAt,
            glucoseValue: r.glucoseLevel,
            readingDate: r.date,
          ));
        }
      }

      // Missed medicines: entries with taken == false in the lookback period
      final entries = await _medicineService.getEntries(
        patient.uid,
        fromDate: fromDate,
        toDate: toDate,
        missedOnly: true,
      );
      for (final e in entries) {
        alerts.add(DoctorAlert(
          type: DoctorAlertType.missedMedicine,
          patientId: patient.uid,
          patientName: patient.displayName.isEmpty ? patient.email : patient.displayName,
          title: 'Missed medicine',
          message: '${e.medicineName} not taken on ${e.date}.',
          timestamp: e.createdAt,
          medicineName: e.medicineName,
          entryDate: e.date,
        ));
      }
    }

    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return alerts;
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

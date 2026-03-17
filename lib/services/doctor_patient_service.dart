import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/patient_risk.dart';
import 'package:dia_plus/models/user_role.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';

/// Service for doctors to fetch and view patient data.
class DoctorPatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlucoseReadingService _glucoseService = GlucoseReadingService();

  /// Fetches all users with role [UserRole.patient].
  Future<List<AppUser>> getPatients() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.patient.value)
        .get();

    final list = snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  /// Fetches a single user by ID (e.g. for profile view). Returns null if not found.
  Future<AppUser?> getPatientProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap(doc.id, data);
  }

  /// Computes risk status from last 7 days of glucose. Returns null if no readings.
  Future<PatientRisk?> getPatientRisk(String patientId) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final readings = await _glucoseService.getReadingsByDateRange(patientId, start, now);
    if (readings.isEmpty) return null;

    final levels = readings.map((r) => r.glucoseLevel).toList();
    final avg = levels.reduce((a, b) => a + b) / levels.length;
    var lowCount = 0;
    var highCount = 0;
    var veryHighCount = 0;
    for (final v in levels) {
      if (v < 70) {
        lowCount++;
      } else if (v > 200) {
        veryHighCount++;
      } else if (v > 140) {
        highCount++;
      }
    }

    RiskLevel level;
    String summary;
    if (veryHighCount > 0 || lowCount >= 2) {
      level = RiskLevel.high;
      summary = veryHighCount > 0
          ? 'Very high glucose in last 7 days. Review urgently.'
          : 'Multiple low glucose readings. Hypoglycemia risk.';
    } else if (highCount >= 3 || avg > 160 || lowCount >= 1) {
      level = RiskLevel.elevated;
      summary = avg > 160
          ? 'Average glucose above target. Consider medication/diet review.'
          : highCount >= 3
              ? 'Several high readings. Monitor and advise.'
              : 'Low glucose recorded. Encourage regular monitoring.';
    } else if (avg > 140 || highCount >= 1) {
      level = RiskLevel.moderate;
      summary = 'Slightly above target range. Continue monitoring.';
    } else {
      level = RiskLevel.low;
      summary = 'Glucose in target range. Good control.';
    }

    return PatientRisk(
      level: level,
      summary: summary,
      averageGlucose: avg,
      readingCount: readings.length,
      lowCount: lowCount,
      highCount: highCount,
      veryHighCount: veryHighCount,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/user_role.dart';

/// Service for doctor-facing operations: list patients, latest readings, risk.
class DoctorPatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches all users with role [UserRole.patient], sorted by display name.
  Future<List<AppUser>> getPatients() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.patient.value)
        .get();

    final list = snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) =>
        (a.displayName.isEmpty ? a.email : a.displayName)
            .toLowerCase()
            .compareTo((b.displayName.isEmpty ? b.email : b.displayName).toLowerCase()));
    return list;
  }

  /// Fetches the most recent glucose reading for a user.
  Future<GlucoseReading?> getLatestReading(String userId) async {
    final snapshot = await _firestore
        .collection('glucose_readings')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    data['id'] = snapshot.docs.first.id;
    return GlucoseReading.fromMap(data);
  }

  /// Risk based on latest reading: low, normal, high, very_high.
  static String riskFromReading(GlucoseReading? reading) {
    if (reading == null) return 'unknown';
    final v = reading.glucoseLevel;
    if (v < 70) return 'low';
    if (v <= 140) return 'normal';
    if (v <= 200) return 'high';
    return 'very_high';
  }
}

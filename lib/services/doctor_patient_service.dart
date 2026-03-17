import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/user_role.dart';

/// Service for doctors to fetch and view patient data.
class DoctorPatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}

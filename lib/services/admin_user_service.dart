import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/user_role.dart';

class AdminUserService {
  AdminUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _batchLimit = 400;

  Future<void> setUserRole({
    required String uid,
    required UserRole role,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserBlocked({
    required String uid,
    required bool blocked,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'blocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
      if (blocked) 'blockedAt': FieldValue.serverTimestamp(),
      if (!blocked) 'unblockedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> _deleteByQuery(Query<Map<String, dynamic>> query) async {
    var deleted = 0;
    while (true) {
      final snap = await query.limit(_batchLimit).get();
      if (snap.docs.isEmpty) return deleted;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      deleted += snap.docs.length;
      if (snap.docs.length < _batchLimit) return deleted;
    }
  }

  /// Deletes a user's Firestore data. Note: this does NOT delete Firebase Auth account.
  ///
  /// Returns an approximate count of deleted docs.
  Future<int> deleteUserDataEverywhere({required String uid}) async {
    var deleted = 0;

    // Core user-owned collections
    deleted += await _deleteByQuery(
      _firestore.collection('glucose_readings').where('userId', isEqualTo: uid),
    );
    deleted += await _deleteByQuery(
      _firestore.collection('medicines').where('userId', isEqualTo: uid),
    );
    deleted += await _deleteByQuery(
      _firestore.collection('medicine_entries').where('userId', isEqualTo: uid),
    );
    deleted += await _deleteByQuery(
      _firestore.collection('meals').where('userId', isEqualTo: uid),
    );
    deleted += await _deleteByQuery(
      _firestore.collection('activities').where('userId', isEqualTo: uid),
    );

    // Prescriptions (group docs)
    deleted += await _deleteByQuery(
      _firestore.collection('prescriptions').where('patientId', isEqualTo: uid),
    );

    // Consultation notes (patient side)
    deleted += await _deleteByQuery(
      _firestore.collection('consultation_notes').where('patientId', isEqualTo: uid),
    );
    // Consultation notes (doctor side)
    deleted += await _deleteByQuery(
      _firestore.collection('consultation_notes').where('doctorId', isEqualTo: uid),
    );

    // Appointments (patient/doctor participation)
    deleted += await _deleteByQuery(
      _firestore.collection('appointments').where('patientId', isEqualTo: uid),
    );
    deleted += await _deleteByQuery(
      _firestore.collection('appointments').where('doctorId', isEqualTo: uid),
    );

    // Notifications for user
    deleted += await _deleteByQuery(
      _firestore.collection('notifications').where('userId', isEqualTo: uid),
    );

    // Messaging
    deleted += await _deleteByQuery(
      _firestore.collection('messages').where('senderId', isEqualTo: uid),
    );
    deleted += await _deleteByQuery(
      _firestore.collection('messages').where('receiverId', isEqualTo: uid),
    );
    deleted += await _deleteByQuery(
      _firestore.collection('conversations').where('participants', arrayContains: uid),
    );

    final userRef = _firestore.collection('users').doc(uid);
    deleted += await _deleteByQuery(userRef.collection('access_requests'));
    deleted += await _deleteByQuery(userRef.collection('announcement_reads'));

    // Finally delete the user profile.
    await userRef.delete();
    deleted += 1;

    return deleted;
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/user_role.dart';

class AdminUserService {
  AdminUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
}


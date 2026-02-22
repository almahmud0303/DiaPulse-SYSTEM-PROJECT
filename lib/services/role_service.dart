import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:dia_plus/models/user_role.dart';

/// Handles role-specific logic including second password for Doctor and Admin.
class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hash a password for storage. Uses SHA-256 with salt (uid) for uniqueness.
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Set the second password for a doctor or admin user.
  /// The second password must be different from the primary password.
  Future<void> setSecondPassword({
    required String uid,
    required String secondPassword,
    required String primaryPassword,
  }) async {
    if (secondPassword == primaryPassword) {
      throw ArgumentError('Second password must be different from your main password');
    }
    if (secondPassword.length < 6) {
      throw ArgumentError('Second password must be at least 6 characters');
    }
    final hash = _hashPassword(secondPassword, uid);
    await _firestore.collection('users').doc(uid).update({
      'secondPasswordHash': hash,
    });
  }

  /// Verify the second password for doctor/admin.
  Future<bool> verifySecondPassword({
    required String uid,
    required String secondPassword,
  }) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final hash = doc.data()?['secondPasswordHash'] as String?;
    if (hash == null) return false;
    final inputHash = _hashPassword(secondPassword, uid);
    return inputHash == hash;
  }

  /// Check if the user has set up their second password (for doctor/admin).
  Future<bool> hasSecondPassword(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['secondPasswordHash'] != null;
  }

  /// Get user role from Firestore.
  Future<UserRole?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return UserRole.fromString(doc.data()?['role'] as String?);
  }
}

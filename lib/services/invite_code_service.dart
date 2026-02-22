import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/user_role.dart';

/// Manages invite codes for Doctor and Admin registration.
/// Only users with valid codes can register as Doctor or Admin.
class InviteCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _codeLength = 8;
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Validate an invite code for the given role.
  /// Returns true if the code exists, matches role, and is not used.
  Future<bool> validateCode({
    required String code,
    required UserRole role,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    final doc = await _firestore
        .collection('inviteCodes')
        .doc(normalized)
        .get();
    if (!doc.exists) return false;
    final data = doc.data();
    if (data == null) return false;
    if (data['used'] == true) return false;
    final codeRole = UserRole.fromString(data['role'] as String?);
    return codeRole == role;
  }

  /// Consume (mark as used) an invite code after successful registration.
  Future<void> consumeCode({
    required String code,
    required String usedByUid,
    required String usedByEmail,
  }) async {
    final normalized = code.trim().toUpperCase();
    await _firestore.collection('inviteCodes').doc(normalized).update({
      'used': true,
      'usedBy': usedByUid,
      'usedByEmail': usedByEmail,
      'usedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Generate a new invite code. Only admins should call this.
  /// Returns the generated code (e.g. "ABC12XYZ").
  Future<String> createCode({
    required UserRole role,
    required String createdByUid,
  }) async {
    String code;
    int attempts = 0;
    do {
      code = _generateCode();
      final doc = await _firestore.collection('inviteCodes').doc(code).get();
      if (!doc.exists) break;
      attempts++;
      if (attempts > 10) throw StateError('Could not generate unique code');
    } while (true);

    await _firestore.collection('inviteCodes').doc(code).set({
      'code': code,
      'role': role.value,
      'used': false,
      'createdBy': createdByUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  String _generateCode() {
    final rnd = Random.secure();
    return List.generate(_codeLength, (_) => _chars[rnd.nextInt(_chars.length)])
        .join();
  }

  /// List invite codes (for admin UI). Filters applied in memory to avoid index.
  Future<List<Map<String, dynamic>>> listCodes({
    UserRole? roleFilter,
    bool unusedOnly = false,
  }) async {
    final snapshot = await _firestore
        .collection('inviteCodes')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    var list = snapshot.docs
        .map((d) => {'id': d.id, ...?d.data()})
        .toList();
    if (roleFilter != null) {
      list = list.where((m) => m['role'] == roleFilter.value).toList();
    }
    if (unusedOnly) {
      list = list.where((m) => m['used'] != true).toList();
    }
    return list;
  }
}

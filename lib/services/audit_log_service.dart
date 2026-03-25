import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/audit_log_entry.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Append-only audit log in Firestore. [actorId] is always the signed-in user.
class AuditLogService {
  AuditLogService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String collectionName = 'audit_logs';

  /// Must match [functions/index.js] scheduled purge (days kept in Firestore).
  static const int retentionDays = 90;

  Future<void> _append({
    required String action,
    required String category,
    String? targetUserId,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection(collectionName).add({
      'actorId': uid,
      'action': action,
      'category': category,
      'targetUserId': targetUserId,
      'metadata': metadata ?? const <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Successful primary auth; optional context for routing (second password, etc.).
  Future<void> logLoginSuccess({
    required bool emailVerified,
    bool? requiresSecondPassword,
    String? flow,
  }) {
    return _append(
      action: AuditLogActions.loginSuccess,
      category: AuditLogCategories.auth,
      metadata: {
        'emailVerified': emailVerified,
        if (requiresSecondPassword != null) 'requiresSecondPassword': requiresSecondPassword,
        if (flow != null) 'flow': flow,
      },
    );
  }

  /// Account is suspended in Firestore; user is signed out right after.
  Future<void> logLoginBlocked({required String targetUserId}) {
    return _append(
      action: AuditLogActions.loginBlocked,
      category: AuditLogCategories.auth,
      targetUserId: targetUserId,
    );
  }

  Future<void> logAdminSetRole({
    required String targetUserId,
    required String newRole,
  }) {
    return _append(
      action: AuditLogActions.adminSetRole,
      category: AuditLogCategories.admin,
      targetUserId: targetUserId,
      metadata: {'newRole': newRole},
    );
  }

  Future<void> logAdminSetBlocked({
    required String targetUserId,
    required bool blocked,
  }) {
    return _append(
      action: AuditLogActions.adminSetBlocked,
      category: AuditLogCategories.admin,
      targetUserId: targetUserId,
      metadata: {'blocked': blocked},
    );
  }

  Future<void> logAdminDeleteUser({
    required String targetUserId,
    required int deletedDocumentCount,
  }) {
    return _append(
      action: AuditLogActions.adminDeleteUser,
      category: AuditLogCategories.admin,
      targetUserId: targetUserId,
      metadata: {'deletedDocumentCount': deletedDocumentCount},
    );
  }
}

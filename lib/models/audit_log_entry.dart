import 'package:cloud_firestore/cloud_firestore.dart';

/// Document in [AuditLogService.collectionName] (append-only audit trail).
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.action,
    required this.category,
    this.targetUserId,
    this.metadata = const {},
    this.createdAt,
  });

  final String id;
  final String actorId;
  final String action;
  final String category;
  final String? targetUserId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory AuditLogEntry.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return AuditLogEntry(
      id: id,
      actorId: data['actorId'] as String? ?? '',
      action: data['action'] as String? ?? '',
      category: data['category'] as String? ?? '',
      targetUserId: data['targetUserId'] as String?,
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map? ?? const {},
      ),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

/// Values for [AuditLogEntry.action].
abstract class AuditLogActions {
  static const loginSuccess = 'login_success';
  static const loginBlocked = 'login_blocked';

  static const adminSetRole = 'admin_set_role';
  static const adminSetBlocked = 'admin_set_blocked';
  static const adminDeleteUser = 'admin_delete_user';
}

/// Values for [AuditLogEntry.category].
abstract class AuditLogCategories {
  static const auth = 'auth';
  static const admin = 'admin';
}

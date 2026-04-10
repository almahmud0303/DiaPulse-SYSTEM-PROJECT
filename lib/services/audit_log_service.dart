import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/audit_log_entry.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Filters for [AuditLogService.buildAuditLogsQuery] / [fetchAuditLogsPage].
class AuditLogQueryParams {
  const AuditLogQueryParams({
    this.action,
    this.category,
    this.actorUid,
    this.targetUid,
    this.from,
    this.to,
  });

  final String? action;
  final String? category;
  final String? actorUid;
  final String? targetUid;
  final DateTime? from;
  final DateTime? to;

  AuditLogQueryParams copyWith({
    String? action,
    String? category,
    String? actorUid,
    String? targetUid,
    DateTime? from,
    DateTime? to,
    bool clearAction = false,
    bool clearCategory = false,
    bool clearActorUid = false,
    bool clearTargetUid = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return AuditLogQueryParams(
      action: clearAction ? null : (action ?? this.action),
      category: clearCategory ? null : (category ?? this.category),
      actorUid: clearActorUid ? null : (actorUid ?? this.actorUid),
      targetUid: clearTargetUid ? null : (targetUid ?? this.targetUid),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }
}

/// One page of audit log rows (cursor-based pagination).
class AuditLogPageResult {
  const AuditLogPageResult({
    required this.entries,
    required this.hasMore,
    this.lastDocument,
  });

  final List<AuditLogEntry> entries;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}

/// Append-only audit log in Firestore. [actorId] is always the signed-in user.
class AuditLogService {
  AuditLogService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String collectionName = 'audit_logs';

  /// Must match [functions/index.js] scheduled purge (days kept in Firestore).
  static const int retentionDays = 90;

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  /// Builds a query ordered by [createdAt] descending. Requires composite indexes
  /// for combinations of filters; deploy [firestore.indexes.json] or use the link in the error.
  Query<Map<String, dynamic>> buildAuditLogsQuery(AuditLogQueryParams params) {
    Query<Map<String, dynamic>> q = _firestore.collection(collectionName);

    final a = params.action?.trim();
    final c = params.category?.trim();
    final actor = params.actorUid?.trim();
    final target = params.targetUid?.trim();

    if (a != null && a.isNotEmpty) {
      q = q.where('action', isEqualTo: a);
    }
    if (c != null && c.isNotEmpty) {
      q = q.where('category', isEqualTo: c);
    }
    if (actor != null && actor.isNotEmpty) {
      q = q.where('actorId', isEqualTo: actor);
    }
    if (target != null && target.isNotEmpty) {
      q = q.where('targetUserId', isEqualTo: target);
    }
    if (params.from != null) {
      q = q.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(params.from!),
      );
    }
    if (params.to != null) {
      q = q.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(params.to!)),
      );
    }

    return q.orderBy('createdAt', descending: true);
  }

  /// Fetches [pageSize] rows (plus one to detect [hasMore]). Pass [startAfter] for the next page.
  Future<AuditLogPageResult> fetchAuditLogsPage({
    required AuditLogQueryParams params,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = 25,
  }) async {
    Query<Map<String, dynamic>> q = buildAuditLogsQuery(params);
    q = q.limit(pageSize + 1);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final docs = snap.docs;
    final hasMore = docs.length > pageSize;
    final n = hasMore ? pageSize : docs.length;
    if (n == 0) {
      return AuditLogPageResult(
        entries: const [],
        hasMore: false,
        lastDocument: null,
      );
    }
    final entries = <AuditLogEntry>[];
    for (var i = 0; i < n; i++) {
      final d = docs[i];
      entries.add(AuditLogEntry.fromMap(d.id, d.data()));
    }
    return AuditLogPageResult(
      entries: entries,
      hasMore: hasMore,
      lastDocument: docs[n - 1],
    );
  }

  Future<void> _append({
    required String action,
    required String category,
    String? targetUserId,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final payload = <String, dynamic>{
      'actorId': uid,
      'action': action,
      'category': category,
      'metadata': metadata ?? const <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (targetUserId != null && targetUserId.isNotEmpty) {
      payload['targetUserId'] = targetUserId;
    }

    await _firestore.collection(collectionName).add(payload);
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
        if (requiresSecondPassword != null)
          'requiresSecondPassword': requiresSecondPassword,
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

  Future<void> logAdminConfigChange({
    required String action,
    required String collection,
    required String itemId,
    String? itemName,
  }) {
    return _append(
      action: action,
      category: AuditLogCategories.admin,
      metadata: {
        'collection': collection,
        'itemId': itemId,
        if (itemName != null) 'itemName': itemName,
      },
    );
  }
}

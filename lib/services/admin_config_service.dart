import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_config_item.dart';
import 'package:dia_plus/models/audit_log_entry.dart';
import 'package:dia_plus/services/audit_log_service.dart';

/// Admin-only CRUD service for dynamic app configuration.
///
/// Manages items under `app_config/{collection}/items/{docId}`.
/// All mutations are audit-logged.
class AdminConfigService {
  AdminConfigService({
    FirebaseFirestore? firestore,
    AuditLogService? auditLogService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogService = auditLogService ?? AuditLogService();

  final FirebaseFirestore _firestore;
  final AuditLogService _auditLogService;

  static const String _root = 'app_config';

  // ── Read (admin sees all items, including inactive) ──────────────────

  /// Streams all items (active + inactive), ordered by [order] then [name].
  Stream<List<AppConfigItem>> watchAll(String collection) {
    return _firestore
        .collection(_root)
        .doc(collection)
        .collection('items')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppConfigItem.fromMap(d.id, d.data()))
            .toList());
  }

  // ── Create ───────────────────────────────────────────────────────────

  Future<void> addItem(String collection, AppConfigItem item) async {
    final docRef = _firestore
        .collection(_root)
        .doc(collection)
        .collection('items')
        .doc();

    await docRef.set(item.toMap());

    await _auditLogService.logAdminConfigChange(
      action: AuditLogActions.adminConfigCreate,
      collection: collection,
      itemId: docRef.id,
      itemName: item.name,
    );
  }

  // ── Update ───────────────────────────────────────────────────────────

  Future<void> updateItem(
    String collection,
    String id,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection(_root)
        .doc(collection)
        .collection('items')
        .doc(id)
        .update(updates);

    await _auditLogService.logAdminConfigChange(
      action: AuditLogActions.adminConfigUpdate,
      collection: collection,
      itemId: id,
      itemName: updates['name'] as String?,
    );
  }

  /// Toggle active state.
  Future<void> toggleActive(
    String collection,
    String id,
    bool isActive,
  ) async {
    await updateItem(collection, id, {'isActive': isActive});
  }

  // ── Delete ───────────────────────────────────────────────────────────

  Future<void> deleteItem(
    String collection,
    String id, {
    String? itemName,
  }) async {
    await _firestore
        .collection(_root)
        .doc(collection)
        .collection('items')
        .doc(id)
        .delete();

    await _auditLogService.logAdminConfigChange(
      action: AuditLogActions.adminConfigDelete,
      collection: collection,
      itemId: id,
      itemName: itemName,
    );
  }

  // ── Seed defaults ────────────────────────────────────────────────────

  /// Seeds default items into a collection if it is empty.
  /// Call once during admin setup or first launch.
  Future<void> seedIfEmpty(
    String collection,
    List<AppConfigItem> defaults,
  ) async {
    final snap = await _firestore
        .collection(_root)
        .doc(collection)
        .collection('items')
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) return; // already seeded

    final batch = _firestore.batch();
    for (final item in defaults) {
      final docRef = _firestore
          .collection(_root)
          .doc(collection)
          .collection('items')
          .doc();
      batch.set(docRef, item.toMap());
    }
    await batch.commit();
  }
}

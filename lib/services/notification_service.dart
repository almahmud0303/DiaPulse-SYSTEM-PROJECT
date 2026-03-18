import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_notification.dart';

/// Firestore-backed in-app notifications.
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Create a "new message" notification for [receiverId].
  Future<void> createMessageNotification({
    required String receiverId,
    required String senderId,
    required String conversationId,
    required String messageText,
    String? senderName,
  }) async {
    final ref = _firestore.collection(_collection).doc();
    final now = DateTime.now();
    final title = senderName != null && senderName.trim().isNotEmpty
        ? 'New message from $senderName'
        : 'New message';
    final body = messageText.trim().isEmpty ? 'New message' : messageText.trim();

    final n = AppNotification(
      id: ref.id,
      userId: receiverId,
      type: AppNotificationType.message,
      title: title,
      body: body.length > 120 ? '${body.substring(0, 120)}…' : body,
      createdAt: now,
      read: false,
      actorId: senderId,
      conversationId: conversationId,
      otherUserId: senderId,
    );
    await ref.set(n.toMap());
  }

  /// Get all notifications for a user, newest first (sorted in Dart).
  Future<List<AppNotification>> getForUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    final list =
        snapshot.docs.map((d) => AppNotification.fromMap(d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Stream notifications for a user (sorted in Dart).
  Stream<List<AppNotification>> streamForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((d) => AppNotification.fromMap(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream unread count for a user.
  Stream<int> streamUnreadCount(String userId) {
    return streamForUser(userId).map((list) => list.where((n) => !n.read).length);
  }

  /// Mark a single notification as read (recipient only).
  Future<void> markRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'read': true,
    });
  }

  /// Mark message notifications for a conversation as read for the current user.
  /// Done without composite indexes (query by userId only, filter in Dart).
  Future<void> markConversationRead({
    required String userId,
    required String conversationId,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    final docs = snapshot.docs.where((d) {
      final data = d.data();
      return (data['type'] == AppNotificationType.message.value) &&
          (data['conversationId'] == conversationId) &&
          (data['read'] != true);
    }).toList();

    if (docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}


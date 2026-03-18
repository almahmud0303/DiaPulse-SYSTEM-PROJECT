import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/chat_message.dart';
import 'package:dia_plus/models/conversation.dart';
import 'package:dia_plus/services/notification_service.dart';

/// Manages doctor–patient messaging. Firestore: `conversations`, `messages`.
class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';
  final NotificationService _notificationService = NotificationService();

  /// conversationId = sorted [uid1, uid2] joined by '_'
  String conversationId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return list.join('_');
  }

  /// Send a message and create/update the conversation doc.
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
  }) async {
    final cid = conversationId(senderId, receiverId);
    final now = DateTime.now();
    final ref = _firestore.collection(_messagesCollection).doc();
    await ref.set({
      'conversationId': cid,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': Timestamp.fromDate(now),
      'read': false,
    });

    await _firestore.collection(_conversationsCollection).doc(cid).set({
      'participants': [senderId, receiverId]..sort(),
      'lastMessageAt': Timestamp.fromDate(now),
      'lastMessageText': text,
      'lastMessageSenderId': senderId,
    }, SetOptions(merge: true));

    // In-app notification for receiver.
    await _notificationService.createMessageNotification(
      receiverId: receiverId,
      senderId: senderId,
      conversationId: cid,
      messageText: text,
      senderName: senderName,
    );
  }

  /// List conversations for the current user, sorted by last message descending.
  /// Sorted in Dart to avoid Firestore composite index (participants + lastMessageAt).
  Future<List<Conversation>> getConversations(String userId) async {
    final snapshot = await _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: userId)
        .get();

    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      final lastAt = data['lastMessageAt'];
      final lastMessageAt = lastAt is Timestamp
          ? lastAt.toDate()
          : DateTime.tryParse(lastAt?.toString() ?? '') ?? DateTime.now();
      return Conversation(
        conversationId: doc.id,
        participants: List<String>.from(data['participants'] ?? []),
        lastMessageAt: lastMessageAt,
        lastMessageText: data['lastMessageText'] as String? ?? '',
        lastMessageSenderId: data['lastMessageSenderId'] as String?,
      );
    }).toList();
    list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return list;
  }

  /// Get messages for a conversation, newest first, limit 100.
  /// Sorted in Dart to avoid Firestore composite index (conversationId + createdAt).
  Future<List<ChatMessage>> getMessages(String cid, {int limit = 100}) async {
    final snapshot = await _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: cid)
        .get();

    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      final createdAt = data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now();
      return ChatMessage(
        id: doc.id,
        conversationId: data['conversationId'] as String? ?? cid,
        senderId: data['senderId'] as String? ?? '',
        receiverId: data['receiverId'] as String? ?? '',
        text: data['text'] as String? ?? '',
        createdAt: createdAt,
        read: data['read'] as bool? ?? false,
      );
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }

  /// Stream of messages for real-time updates in chat.
  /// Sorted in Dart to avoid Firestore composite index.
  Stream<List<ChatMessage>> streamMessages(String cid, {int limit = 100}) {
    return _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: cid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now();
        return ChatMessage(
          id: doc.id,
          conversationId: data['conversationId'] as String? ?? cid,
          senderId: data['senderId'] as String? ?? '',
          receiverId: data['receiverId'] as String? ?? '',
          text: data['text'] as String? ?? '',
          createdAt: createdAt,
          read: data['read'] as bool? ?? false,
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(limit).toList();
    });
  }
}

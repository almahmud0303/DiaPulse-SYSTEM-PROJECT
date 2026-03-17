import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/chat_message.dart';
import 'package:dia_plus/models/conversation.dart';

/// Manages doctor–patient messaging. Firestore: `conversations`, `messages`.
class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';

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
  }

  /// List conversations for the current user, sorted by last message descending.
  Future<List<Conversation>> getConversations(String userId) async {
    final snapshot = await _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
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
  }

  /// Get messages for a conversation, newest first, limit 100.
  Future<List<ChatMessage>> getMessages(String cid, {int limit = 100}) async {
    final snapshot = await _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: cid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
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
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// Stream of messages for real-time updates in chat.
  Stream<List<ChatMessage>> streamMessages(String cid, {int limit = 100}) {
    return _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: cid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
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
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }
}

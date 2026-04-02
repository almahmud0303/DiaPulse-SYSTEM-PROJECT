import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/chat_message.dart';
import 'package:dia_plus/models/conversation.dart';
import 'package:dia_plus/services/notification_service.dart';
import 'package:firebase_database/firebase_database.dart';

/// Doctor–patient messaging.
/// Message bodies live in **Realtime Database** (`chat_messages/{conversationId}`).
/// Conversation metadata (list, last preview) stays in Firestore (`conversations`).
class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  static const String _conversationsCollection = 'conversations';
  static const String _chatMessagesRoot = 'chat_messages';

  final NotificationService _notificationService = NotificationService();

  /// conversationId = sorted [uid1, uid2] joined by '_'
  String conversationId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return list.join('_');
  }

  DatabaseReference _messagesRef(String cid) =>
      _db.ref('$_chatMessagesRoot/$cid');

  /// Send a message (RTDB) and update Firestore conversation metadata + notification.
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
  }) async {
    final cid = conversationId(senderId, receiverId);
    final now = DateTime.now();
    final msgRef = _messagesRef(cid).push();
    await msgRef.set({
      'conversationId': cid,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': ServerValue.timestamp,
      'read': false,
    });

    await _firestore.collection(_conversationsCollection).doc(cid).set({
      'participants': [senderId, receiverId]..sort(),
      'lastMessageAt': Timestamp.fromDate(now),
      'lastMessageText': text,
      'lastMessageSenderId': senderId,
    }, SetOptions(merge: true));

    await _notificationService.createMessageNotification(
      receiverId: receiverId,
      senderId: senderId,
      conversationId: cid,
      messageText: text,
      senderName: senderName,
    );
  }

  /// List conversations for the current user, sorted by last message descending.
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

  List<ChatMessage> _parseChatSnapshot(DataSnapshot snapshot, String cid) {
    if (!snapshot.exists || snapshot.value == null) return [];
    final raw = snapshot.value;
    if (raw is! Map) return [];
    final map = Map<Object?, Object?>.from(raw);
    final out = <ChatMessage>[];
    for (final e in map.entries) {
      final key = e.key?.toString() ?? '';
      final val = e.value;
      if (val is! Map) continue;
      final m = Map<String, dynamic>.from(
        Map<Object?, Object?>.from(val).map(
          (k, v) => MapEntry(k.toString(), v),
        ),
      );
      out.add(ChatMessage.fromMap(key, m));
    }
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  /// Last [limit] messages, **oldest first** (previous at top, newest at bottom).
  Future<List<ChatMessage>> getMessages(String cid, {int limit = 100}) async {
    final q =
        _messagesRef(cid).orderByChild('createdAt').limitToLast(limit);
    final snapshot = await q.get();
    return _parseChatSnapshot(snapshot, cid);
  }

  /// Live stream — same order as [getMessages] (oldest → newest).
  Stream<List<ChatMessage>> streamMessages(String cid, {int limit = 100}) {
    final q =
        _messagesRef(cid).orderByChild('createdAt').limitToLast(limit);
    return q.onValue.map((e) => _parseChatSnapshot(e.snapshot, cid));
  }
}

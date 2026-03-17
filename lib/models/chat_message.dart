/// A single message in a doctor–patient conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final bool read;

  bool isFromSender(String userId) => senderId == userId;

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'read': read,
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      conversationId: map['conversationId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      read: map['read'] as bool? ?? false,
    );
  }
}

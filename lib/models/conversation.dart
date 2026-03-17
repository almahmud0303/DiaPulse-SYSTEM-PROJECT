/// Summary of a conversation for the list view.
class Conversation {
  const Conversation({
    required this.conversationId,
    required this.participants,
    required this.lastMessageAt,
    this.lastMessageText = '',
    this.lastMessageSenderId,
  });

  final String conversationId;
  final List<String> participants;
  final DateTime lastMessageAt;
  final String lastMessageText;
  final String? lastMessageSenderId;

  /// The other participant's uid (caller must pass current user id).
  String otherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
  }

  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    final participants = (map['participants'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final lastAt = map['lastMessageAt'];
    final lastMessageAt = lastAt is DateTime
        ? lastAt
        : (lastAt != null ? DateTime.tryParse(lastAt.toString()) : null) ?? DateTime.now();
    return Conversation(
      conversationId: id,
      participants: participants,
      lastMessageAt: lastMessageAt,
      lastMessageText: map['lastMessageText'] as String? ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
    );
  }
}

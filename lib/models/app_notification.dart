/// Notification type for in-app notifications.
enum AppNotificationType {
  message;

  String get value => name;

  static AppNotificationType fromString(String? v) {
    switch (v) {
      case 'message':
      default:
        return AppNotificationType.message;
    }
  }
}

/// In-app notification stored in Firestore `notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.actorId,
    this.conversationId,
    this.otherUserId,
  });

  final String id;
  /// Recipient user id.
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  /// User that triggered the notification (e.g. sender).
  final String? actorId;
  /// For message notifications.
  final String? conversationId;
  final String? otherUserId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
      if (actorId != null) 'actorId': actorId,
      if (conversationId != null) 'conversationId': conversationId,
      if (otherUserId != null) 'otherUserId': otherUserId,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: AppNotificationType.fromString(map['type'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      read: map['read'] as bool? ?? false,
      actorId: map['actorId'] as String?,
      conversationId: map['conversationId'] as String?,
      otherUserId: map['otherUserId'] as String?,
    );
  }
}


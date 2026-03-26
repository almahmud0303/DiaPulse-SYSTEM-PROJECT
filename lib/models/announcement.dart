import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.published,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.targetRole,
  });

  final String id;
  final String title;
  final String body;
  final bool published;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final String? targetRole;

  factory Announcement.fromMap(String id, Map<String, dynamic> data) {
    DateTime? asDate(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Announcement(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      published: data['published'] as bool? ?? false,
      createdBy: data['createdBy'] as String?,
      createdAt: asDate(data['createdAt']),
      updatedAt: asDate(data['updatedAt']),
      publishedAt: asDate(data['publishedAt']),
      targetRole: data['targetRole'] as String?,
    );
  }
}

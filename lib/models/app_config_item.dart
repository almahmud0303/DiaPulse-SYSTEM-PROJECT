import 'package:cloud_firestore/cloud_firestore.dart';

/// A generic configuration item stored in Firestore under
/// `app_config/{collection}/{docId}`.
///
/// Used for admin-managed dynamic lists such as meal categories,
/// activity types, glucose meal-time options, and diabetes essentials.
class AppConfigItem {
  const AppConfigItem({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.order = 0,
    this.isActive = true,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int order;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get section {
    final raw = metadata?['section'];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  factory AppConfigItem.fromMap(String id, Map<String, dynamic> data) {
    return AppConfigItem(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      icon: data['icon'] as String?,
      color: data['color'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'order': order,
      'isActive': isActive,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppConfigItem copyWith({
    String? name,
    String? description,
    String? icon,
    String? color,
    int? order,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AppConfigItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

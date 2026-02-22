import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/user_role.dart';

/// Represents the authenticated app user with role and profile info.
/// Extensible for future fields - use [extra] for custom data.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phone,
    this.createdAt,
    this.updatedAt,
    this.photoUrl,
    this.extra = const {},
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? photoUrl;
  /// Custom fields for future extension. Avoid storing sensitive data.
  final Map<String, dynamic> extra;

  bool get isPatient => role == UserRole.patient;
  bool get isDoctor => role == UserRole.doctor;
  bool get isAdmin => role == UserRole.admin;

  /// Initials from display name (e.g. "John Doe" -> "JD").
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? photoUrl,
    Map<String, dynamic>? extra,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      extra: extra ?? this.extra,
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    DateTime? createdAt;
    DateTime? updatedAt;
    final createdAtVal = data['createdAt'];
    final updatedAtVal = data['updatedAt'];
    if (createdAtVal != null && createdAtVal is Timestamp) {
      createdAt = createdAtVal.toDate();
    }
    if (updatedAtVal != null && updatedAtVal is Timestamp) {
      updatedAt = updatedAtVal.toDate();
    }
    const knownKeys = {
      'email', 'displayName', 'role', 'phone', 'createdAt', 'updatedAt',
      'photoUrl', 'secondPasswordHash',
    };
    final extra = <String, dynamic>{};
    for (final e in data.entries) {
      if (!knownKeys.contains(e.key)) extra[e.key] = e.value;
    }
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?) ?? UserRole.patient,
      phone: data['phone'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photoUrl: data['photoUrl'] as String?,
      extra: extra,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.value,
      'phone': phone ?? '',
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (photoUrl != null) 'photoUrl': photoUrl!,
      ...extra,
    };
    return map;
  }

  Map<String, dynamic> toJson() => toMap();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final uid = json['uid'] as String? ?? '';
    final data = Map<String, dynamic>.from(json)..remove('uid');
    return AppUser.fromMap(uid, data);
  }
}

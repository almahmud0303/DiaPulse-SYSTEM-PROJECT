import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/user_role.dart';

enum InviteAccessRequestStatus {
  pending,
  approved,
  rejected,
}

InviteAccessRequestStatus inviteAccessRequestStatusFromString(String? s) {
  switch (s) {
    case 'approved':
      return InviteAccessRequestStatus.approved;
    case 'rejected':
      return InviteAccessRequestStatus.rejected;
    default:
      return InviteAccessRequestStatus.pending;
  }
}

/// Doctor/Admin asks for account access; admin approves before second-password setup.
class InviteAccessRequest {
  const InviteAccessRequest({
    required this.id,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    this.message,
    this.createdAt,
    this.reviewedByUid,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final String email;
  final String displayName;
  final UserRole role;
  final InviteAccessRequestStatus status;
  final String? message;
  final DateTime? createdAt;
  final String? reviewedByUid;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  bool get isPending => status == InviteAccessRequestStatus.pending;
  bool get isApproved => status == InviteAccessRequestStatus.approved;
  bool get isRejected => status == InviteAccessRequestStatus.rejected;

  factory InviteAccessRequest.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime? createdAt;
    DateTime? reviewedAt;
    final c = data['createdAt'];
    final r = data['reviewedAt'];
    if (c is Timestamp) createdAt = c.toDate();
    if (r is Timestamp) reviewedAt = r.toDate();
    return InviteAccessRequest(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?) ?? UserRole.patient,
      status: inviteAccessRequestStatusFromString(data['status'] as String?),
      message: data['message'] as String?,
      createdAt: createdAt,
      reviewedByUid: data['reviewedBy'] as String?,
      reviewedAt: reviewedAt,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }
}

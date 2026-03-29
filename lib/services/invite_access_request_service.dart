import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/invite_access_request.dart';
import 'package:dia_plus/models/user_role.dart';

/// Firestore: `users/{uid}/access_requests/{requestId}` (per-user subcollection).
/// Admins list pending via [collectionGroup] `access_requests`.
class InviteAccessRequestService {
  InviteAccessRequestService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String subcollectionName = 'access_requests';

  CollectionReference<Map<String, dynamic>> _requestsForUser(String uid) =>
      _db.collection('users').doc(uid).collection(subcollectionName);

  /// Latest request for this user (any status), by [createdAt].
  Stream<InviteAccessRequest?> streamLatestForUser(String uid) {
    return _requestsForUser(uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return InviteAccessRequest.fromDoc(snap.docs.first);
    });
  }

  Future<InviteAccessRequest?> fetchLatestForUser(String uid) async {
    final snap = await _requestsForUser(uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return InviteAccessRequest.fromDoc(snap.docs.first);
  }

  Future<bool> hasPendingRequest(String uid) async {
    final snap = await _requestsForUser(uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Submits a new pending request. Throws if one is already pending.
  Future<void> submitRequest({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
    String? message,
  }) async {
    if (!role.requiresSecondPassword) {
      throw ArgumentError('This account type does not use access requests.');
    }
    final existing = await _requestsForUser(uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw ArgumentError(
        'You already have a pending request. Please wait for an administrator.',
      );
    }
    final trimmedMessage = message?.trim();
    final data = <String, dynamic>{
      'userId': uid,
      'email': email.trim(),
      'displayName': displayName.trim(),
      'role': role.name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (trimmedMessage != null && trimmedMessage.isNotEmpty) {
      data['message'] = trimmedMessage;
    }
    await _requestsForUser(uid).add(data);
  }

  Stream<List<InviteAccessRequest>> streamPendingForAdmin() {
    return _db
        .collectionGroup(subcollectionName)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map(InviteAccessRequest.fromDoc).toList());
  }

  Future<void> approve({
    required String userId,
    required String requestId,
    required String adminUid,
  }) async {
    await _requestsForUser(userId).doc(requestId).update({
      'status': 'approved',
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': FieldValue.delete(),
    });
  }

  Future<void> reject({
    required String userId,
    required String requestId,
    required String adminUid,
    String? reason,
  }) async {
    final update = <String, dynamic>{
      'status': 'rejected',
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    if (reason != null && reason.trim().isNotEmpty) {
      update['rejectionReason'] = reason.trim();
    } else {
      update['rejectionReason'] = FieldValue.delete();
    }
    await _requestsForUser(userId).doc(requestId).update(update);
  }
}

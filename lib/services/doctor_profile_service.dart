import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/doctor_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// CRUD service for doctor profiles stored at
/// `users/{uid}/doctor_profile/profile`.
///
/// Images are stored as Base64-encoded strings inside Firestore
/// (no Firebase Storage required — works on the free Spark plan).
class DoctorProfileService {
  DoctorProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _subCollection = 'doctor_profile';
  static const String _docId = 'profile';

  // ── References ──────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _firestore.collection('users').doc(uid).collection(_subCollection).doc(_docId);

  // ── Read ─────────────────────────────────────────────────────────────

  /// Fetches the doctor profile once. Returns null if it doesn't exist.
  Future<DoctorProfile?> getProfile(String uid) async {
    final snap = await _profileRef(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return DoctorProfile.fromMap(uid, snap.data()!);
  }

  /// Real-time stream of the doctor's profile.
  Stream<DoctorProfile?> watchProfile(String uid) {
    return _profileRef(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return DoctorProfile.fromMap(uid, snap.data()!);
    });
  }

  /// Streams all doctor profiles with a given verification status (filtered in Dart to avoid index requirement).
  Stream<List<DoctorProfile>> watchByVerificationStatus(
      VerificationStatus status) {
    return watchAllProfiles().map((profiles) {
      return profiles.where((p) => p.verificationStatus == status).toList();
    });
  }

  /// Fetches all doctor profiles (for admin listing).
  Stream<List<DoctorProfile>> watchAllProfiles() {
    return _firestore
        .collectionGroup(_subCollection)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final uid = d.reference.parent.parent!.id;
              return DoctorProfile.fromMap(uid, d.data());
            }).toList());
  }

  // ── Create / Update ─────────────────────────────────────────────────

  /// Creates or fully replaces the doctor profile document.
  Future<void> saveProfile(DoctorProfile profile) async {
    await _profileRef(profile.uid).set(profile.toMap());
  }

  /// Partially updates specific fields on the profile.
  Future<void> updateProfileFields(
      String uid, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _profileRef(uid).update(updates);
  }

  /// Sets verification status (admin action).
  Future<void> setVerificationStatus(
    String uid,
    VerificationStatus status, {
    String? rejectionReason,
  }) async {
    final updates = <String, dynamic>{
      'verificationStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == VerificationStatus.rejected && rejectionReason != null) {
      updates['rejectionReason'] = rejectionReason;
    }
    if (status == VerificationStatus.approved) {
      updates['rejectionReason'] = FieldValue.delete();
    }
    await _profileRef(uid).update(updates);
  }

  // ── Image encoding (Base64 in Firestore, no Storage needed) ─────────

  /// Reads a file and returns a `data:image/jpeg;base64,...` data URI string.
  Future<String> fileToBase64DataUri(File file) async {
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$b64';
  }

  // ── Rating update (called by DoctorReviewService) ───────────────────

  /// Updates computed rating fields on the profile.
  Future<void> updateRatingStats(
    String doctorId, {
    required double averageRating,
    required int totalReviews,
  }) async {
    await _profileRef(doctorId).update({
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/doctor_review.dart';
import 'package:dia_plus/services/doctor_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for doctor reviews stored in `doctor_reviews/{reviewId}`.
///
/// After each review submission, recomputes the doctor's average rating
/// and updates the profile document.
class DoctorReviewService {
  DoctorReviewService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    DoctorProfileService? profileService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _profileService = profileService ?? DoctorProfileService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DoctorProfileService _profileService;

  static const String _collection = 'doctor_reviews';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  // ── Read ─────────────────────────────────────────────────────────────

  /// Streams all reviews for a doctor, newest first.
  Stream<List<DoctorReview>> watchReviews(String doctorId) {
    return _ref
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DoctorReview.fromMap(d.id, d.data())).toList());
  }

  /// Checks whether the current patient has already reviewed this doctor.
  Future<bool> hasReviewed(String doctorId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final snap = await _ref
        .where('doctorId', isEqualTo: doctorId)
        .where('patientId', isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Submit ──────────────────────────────────────────────────────────

  /// Submits a new review and recomputes the doctor's rating.
  Future<void> submitReview({
    required String doctorId,
    required double rating,
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final review = DoctorReview(
      id: '',
      doctorId: doctorId,
      patientId: user.uid,
      patientName: user.displayName ?? 'Patient',
      rating: rating,
      comment: comment,
    );

    await _ref.add(review.toMap());
    await _recomputeRating(doctorId);
  }

  /// Deletes a review and recomputes the doctor's rating.
  Future<void> deleteReview(String reviewId, String doctorId) async {
    await _ref.doc(reviewId).delete();
    await _recomputeRating(doctorId);
  }

  // ── Internal ────────────────────────────────────────────────────────

  Future<void> _recomputeRating(String doctorId) async {
    final snap =
        await _ref.where('doctorId', isEqualTo: doctorId).get();
    if (snap.docs.isEmpty) {
      await _profileService.updateRatingStats(
        doctorId,
        averageRating: 0.0,
        totalReviews: 0,
      );
      return;
    }
    double total = 0;
    for (final d in snap.docs) {
      total += (d.data()['rating'] as num?)?.toDouble() ?? 0.0;
    }
    final avg = total / snap.docs.length;
    await _profileService.updateRatingStats(
      doctorId,
      averageRating: double.parse(avg.toStringAsFixed(1)),
      totalReviews: snap.docs.length,
    );
  }
}

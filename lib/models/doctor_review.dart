import 'package:cloud_firestore/cloud_firestore.dart';

/// A patient review of a doctor, stored in `doctor_reviews/{reviewId}`.
class DoctorReview {
  const DoctorReview({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final double rating; // 1.0 – 5.0
  final String? comment;
  final DateTime? createdAt;

  factory DoctorReview.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return DoctorReview(
      id: id,
      doctorId: data['doctorId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

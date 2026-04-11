import 'dart:convert';

import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/doctor_profile.dart';
import 'package:dia_plus/models/doctor_review.dart';
import 'package:dia_plus/services/doctor_profile_service.dart';
import 'package:dia_plus/services/doctor_review_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Patient-facing read-only view of a doctor's profile.
/// Shows public subset: name, photo, specialization, qualifications,
/// clinic, availability, fees, bio, services, and ratings/reviews.
class DoctorPublicProfilePage extends StatefulWidget {
  const DoctorPublicProfilePage({super.key, required this.doctorUid});

  final String doctorUid;

  @override
  State<DoctorPublicProfilePage> createState() =>
      _DoctorPublicProfilePageState();
}

class _DoctorPublicProfilePageState extends State<DoctorPublicProfilePage> {
  final _profileService = DoctorProfileService();
  final _reviewService = DoctorReviewService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DoctorProfile?>(
        stream: _profileService.watchProfile(widget.doctorUid),
        builder: (context, profileSnap) {
          if (profileSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = profileSnap.data;
          if (profile == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Doctor Profile')),
              body: const Center(child: Text('Profile not available')),
            );
          }
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(profile),
              SliverToBoxAdapter(child: _buildBody(profile)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(DoctorProfile profile) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppTheme.primaryMint,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryMint,
                AppTheme.primaryMint.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profile.profilePhotoUrl != null
                      ? _imageProvider(profile.profilePhotoUrl!)
                      : null,
                  child: profile.profilePhotoUrl == null
                      ? Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryMint,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (profile.specialization != null)
                  Text(
                    profile.specialization!,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DoctorProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating summary
          _buildRatingCard(profile),
          const SizedBox(height: 16),

          // Verification badge
          if (profile.verificationStatus == VerificationStatus.approved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Text('Verified Doctor',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Qualifications
          if (profile.qualifications.isNotEmpty) ...[
            _sectionTitle('Qualifications'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: profile.qualifications
                  .map((q) => Chip(
                        label: Text(q, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppTheme.cardTintLavender,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Experience
          if (profile.yearsOfExperience != null) ...[
            _infoRow(Icons.work_outline, '${profile.yearsOfExperience} years of experience'),
            const SizedBox(height: 8),
          ],

          // Clinic
          if (profile.clinicName != null) ...[
            _infoRow(Icons.local_hospital, profile.clinicName!),
            const SizedBox(height: 8),
          ],
          if (profile.clinicAddress != null) ...[
            _infoRow(Icons.location_on_outlined, profile.clinicAddress!),
            const SizedBox(height: 8),
          ],
          if (profile.city != null || profile.country != null) ...[
            _infoRow(
              Icons.map_outlined,
              [profile.city, profile.country].where((e) => e != null).join(', '),
            ),
            const SizedBox(height: 16),
          ],

          // Availability
          if (profile.availableDays.isNotEmpty) ...[
            _sectionTitle('Availability'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: profile.availableDays
                  .map((d) => Chip(
                        label: Text(d, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppTheme.cardTintMint,
                      ))
                  .toList(),
            ),
            if (profile.timeSlots.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...profile.timeSlots.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _infoRow(Icons.schedule, '${s.startTime} - ${s.endTime}'),
                  )),
            ],
            if (profile.isOnlineConsultationAvailable) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.videocam, 'Online consultation available'),
            ],
            const SizedBox(height: 16),
          ],

          // Fees
          if (profile.inPersonFee != null || profile.onlineFee != null) ...[
            _sectionTitle('Consultation Fees'),
            if (profile.inPersonFee != null)
              _infoRow(Icons.person, 'In-person: \$${profile.inPersonFee!.toStringAsFixed(0)}'),
            if (profile.onlineFee != null) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.videocam, 'Online: \$${profile.onlineFee!.toStringAsFixed(0)}'),
            ],
            if (profile.paymentMethods.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: profile.paymentMethods
                    .map((m) => Chip(
                          label: Text(m, style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            _sectionTitle('About'),
            Text(profile.bio!, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
          ],

          // Services
          if (profile.services.isNotEmpty) ...[
            _sectionTitle('Services Offered'),
            ...profile.services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _infoRow(Icons.check_circle_outline, s),
                )),
            const SizedBox(height: 16),
          ],

          // Languages
          if (profile.languagesSpoken.isNotEmpty) ...[
            _sectionTitle('Languages'),
            Wrap(
              spacing: 8,
              children: profile.languagesSpoken
                  .map((l) => Chip(label: Text(l, style: const TextStyle(fontSize: 12))))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Reviews section
          _sectionTitle('Reviews'),
          const SizedBox(height: 8),
          _buildReviewsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRatingCard(DoctorProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                profile.averageRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              _buildStarRow(profile.averageRating),
              Text(
                '${profile.totalReviews} reviews',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Container(height: 60, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(Icons.people, '${profile.totalPatientsTreated} patients treated'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (i < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        }
        return const Icon(Icons.star_border, color: Colors.amber, size: 18);
      }),
    );
  }

  Widget _buildReviewsSection() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isPatient = currentUid != null && currentUid != widget.doctorUid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPatient)
          FutureBuilder<bool>(
            future: _reviewService.hasReviewed(widget.doctorUid),
            builder: (context, snap) {
              if (snap.data == true) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'You have already reviewed this doctor.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewDialog(),
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Write a Review'),
                ),
              );
            },
          ),
        StreamBuilder<List<DoctorReview>>(
          stream: _reviewService.watchReviews(widget.doctorUid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reviews = snap.data ?? [];
            if (reviews.isEmpty) {
              return const Text(
                'No reviews yet.',
                style: TextStyle(color: AppTheme.textSecondary),
              );
            }
            return Column(
              children: reviews.map((r) => _buildReviewCard(r)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(DoctorReview review) {
    final dateStr = review.createdAt != null
        ? DateFormat.yMMMd().format(review.createdAt!)
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.secondaryLavender,
                child: Text(
                  review.patientName.isNotEmpty
                      ? review.patientName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.patientName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(dateStr,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              _buildStarRow(review.rating),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog() {
    double rating = 5.0;
    final commentController = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => rating = (i + 1).toDouble()),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Share your experience (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 300,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      try {
                        await _reviewService.submitReview(
                          doctorId: widget.doctorUid,
                          rating: rating,
                          comment: commentController.text.trim().isNotEmpty
                              ? commentController.text.trim()
                              : null,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          setState(() {}); // refresh FutureBuilder
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Review submitted!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  /// Returns an [ImageProvider] for a URL that may be a Base64 data URI
  /// or a normal network URL.
  static ImageProvider _imageProvider(String url) {
    if (url.startsWith('data:')) {
      final raw = url.split(',').last;
      return MemoryImage(base64Decode(raw));
    }
    return NetworkImage(url);
  }
}

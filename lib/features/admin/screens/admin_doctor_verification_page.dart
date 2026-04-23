import 'dart:convert';

import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/doctor_profile.dart';
import 'package:dia_plus/services/audit_log_service.dart';
import 'package:dia_plus/services/doctor_profile_service.dart';
import 'package:flutter/material.dart';

/// Admin page showing doctors pending verification with approve / reject actions.
class AdminDoctorVerificationPage extends StatefulWidget {
  const AdminDoctorVerificationPage({super.key});

  @override
  State<AdminDoctorVerificationPage> createState() =>
      _AdminDoctorVerificationPageState();
}

class _AdminDoctorVerificationPageState
    extends State<AdminDoctorVerificationPage>
    with SingleTickerProviderStateMixin {
  final _service = DoctorProfileService();
  final _auditLogService = AuditLogService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Doctor Verification'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(VerificationStatus.pending),
          _buildList(VerificationStatus.approved),
          _buildList(VerificationStatus.rejected),
        ],
      ),
    );
  }

  Widget _buildList(VerificationStatus status) {
    return StreamBuilder<List<DoctorProfile>>(
      stream: _service.watchByVerificationStatus(status),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final profiles = snap.data ?? [];
        if (profiles.isEmpty) {
          return Center(
            child: Text(
              'No ${status.displayName.toLowerCase()} profiles',
              style: TextStyle(color: AppTheme.textSecondaryColor(context)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: profiles.length,
          itemBuilder: (context, i) => _buildProfileCard(profiles[i]),
        );
      },
    );
  }

  Widget _buildProfileCard(DoctorProfile profile) {
    final isPending =
        profile.verificationStatus == VerificationStatus.pending;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryMint,
              backgroundImage: profile.profilePhotoUrl != null
                  ? _imageFromString(profile.profilePhotoUrl!)
                  : null,
              child: profile.profilePhotoUrl == null
                  ? Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : 'D',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(profile.fullName,
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(profile.specialization ?? 'No specialization'),
            trailing: _statusChip(profile.verificationStatus),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.medicalLicenseNumber != null)
                  _detailRow('License', profile.medicalLicenseNumber!),
                _detailRow('Email', profile.email),
                if (profile.phoneNumber != null)
                  _detailRow('Phone', profile.phoneNumber!),
                if (profile.clinicName != null)
                  _detailRow('Clinic', profile.clinicName!),
                if (profile.city != null)
                  _detailRow('City', profile.city!),
                if (profile.qualifications.isNotEmpty)
                  _detailRow('Qualifications', profile.qualifications.join(', ')),
                if (profile.yearsOfExperience != null)
                  _detailRow('Experience', '${profile.yearsOfExperience} years'),
              ],
            ),
          ),

          // Documents preview
          if (profile.certificateUrls.isNotEmpty ||
              profile.idProofUrl != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Documents',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (profile.idProofUrl != null)
                    _docThumb(profile.idProofUrl!, 'ID Proof'),
                  ...profile.certificateUrls.asMap().entries.map((e) =>
                      _docThumb(e.value, 'Cert ${e.key + 1}')),
                ],
              ),
            ),
          ],

          // Actions
          if (isPending)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approve(profile),
                      icon: Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(profile),
                      icon: Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            )
          else if (profile.verificationStatus == VerificationStatus.rejected &&
              profile.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection reason: ${profile.rejectionReason}',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statusChip(VerificationStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case VerificationStatus.pending:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
      case VerificationStatus.approved:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
      case VerificationStatus.rejected:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status.displayName,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: AppTheme.textSecondaryColor(context), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _docThumb(String url, String label) {
    return GestureDetector(
      onTap: () => _showImageDialog(url, label),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: _imageFromString(url),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image, size: 24),
                ),
              ),
            ),
            Text(label, style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String url, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            InteractiveViewer(
              child: Image(
                image: _imageFromString(url),
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(DoctorProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Doctor'),
        content: Text(
            'Approve ${profile.fullName} as a verified doctor? Their profile will become visible to patients.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.setVerificationStatus(
          profile.uid, VerificationStatus.approved);
      await _auditLogService.logDoctorProfileVerified(
          targetUserId: profile.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Doctor approved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(DoctorProfile profile) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${profile.fullName}\'s verification?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.setVerificationStatus(
                  profile.uid,
                  VerificationStatus.rejected,
                  rejectionReason: reasonController.text.trim().isNotEmpty
                      ? reasonController.text.trim()
                      : null,
                );
                await _auditLogService.logDoctorProfileRejected(
                  targetUserId: profile.uid,
                  reason: reasonController.text.trim().isNotEmpty
                      ? reasonController.text.trim()
                      : null,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doctor rejected')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  static ImageProvider _imageFromString(String url) {
    if (url.startsWith('data:')) {
      return MemoryImage(base64Decode(url.split(',').last));
    }
    return NetworkImage(url);
  }
}

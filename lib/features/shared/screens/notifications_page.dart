// ignore_for_file: use_build_context_synchronously

import 'package:dia_plus/models/app_notification.dart';
import 'package:dia_plus/features/shared/screens/announcements_page.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:dia_plus/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_page.dart';
import 'package:dia_plus/features/doctor/screens/doctor_appointments_page.dart';
import 'package:dia_plus/features/patient/screens/patient_appointments_page.dart';
import 'package:dia_plus/features/patient/screens/patient_prescriptions_page.dart';

/// In-app notifications list (messages, appointments, etc.).
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final DoctorPatientService _userService = DoctorPatientService();

  String? _uid;
  AppUser? _me;
  bool _loading = true;
  String? _error;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.getAppUser();
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Not signed in';
          _loading = false;
        });
        return;
      }
      final list = await _notificationService.getForUser(user.uid);
      if (!mounted) return;
      setState(() {
        _uid = user.uid;
        _me = user;
        _notifications = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openNotification(AppNotification n) async {
    if (_uid == null) return;
    if (!n.read) {
      try {
        await _notificationService.markRead(n.id);
      } catch (_) {}
    }

    if (n.type == AppNotificationType.message &&
        n.otherUserId != null &&
        n.otherUserId!.isNotEmpty) {
      final currentUser = await _authService.getAppUser();
      if (!mounted) return;
      if (currentUser == null) return;
      final other = await _userService.getPatientProfile(n.otherUserId!);
      if (!mounted) return;
      if (other == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              ChatPage(currentUser: currentUser, otherUser: other),
        ),
      );
    }

    if (n.type == AppNotificationType.appointment) {
      final currentUser = await _authService.getAppUser();
      if (!mounted) return;
      if (currentUser == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => currentUser.isDoctor
              ? const DoctorAppointmentsPage()
              : const PatientAppointmentsPage(),
        ),
      );
    }

    if (n.type == AppNotificationType.prescription) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              PatientPrescriptionsPage(openPrescriptionId: n.prescriptionId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d • HH:mm');
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Material(
                    color: AppTheme.cardTintLavender,
                    child: const TabBar(
                      labelColor: AppTheme.textPrimary,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryMint,
                      tabs: [
                        Tab(text: 'Notifications'),
                        Tab(text: 'Announcements'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _notifications.isEmpty
                            ? _buildEmpty()
                            : RefreshIndicator(
                                onRefresh: _load,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  itemCount: _notifications.length,
                                  itemBuilder: (context, index) {
                                    final n = _notifications[index];
                                    return _NotificationTile(
                                      notification: n,
                                      dateFmt: dateFmt,
                                      onTap: () => _openNotification(n),
                                    );
                                  },
                                ),
                              ),
                        _me == null
                            ? const Center(child: Text('Not signed in'))
                            : AnnouncementsPage(user: _me!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'New message alerts will show up here.',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.dateFmt,
    required this.onTap,
  });

  final AppNotification notification;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isUnread = !n.read;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppTheme.cardTintMint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.secondaryLavender.withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isUnread
              ? AppTheme.secondaryLavender.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.12),
          child: Icon(
            n.type == AppNotificationType.message
                ? Icons.chat_bubble_outline
                : Icons.notifications,
            color: isUnread ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        title: Text(
          n.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(
          dateFmt.format(n.createdAt),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}

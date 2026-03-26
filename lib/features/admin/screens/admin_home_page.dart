import 'package:dia_plus/features/admin/screens/admin_audit_logs_page.dart';
import 'package:dia_plus/features/admin/screens/admin_backup_export_page.dart';
import 'package:dia_plus/features/admin/screens/admin_backup_restore_page.dart';
import 'package:dia_plus/features/admin/screens/admin_system_monitoring_page.dart';
import 'package:dia_plus/features/admin/screens/invite_codes_page.dart';
import 'package:dia_plus/features/admin/screens/admin_user_management_page.dart';
import 'package:dia_plus/models/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Admin-specific home screen.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.deepPurple,
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage users and system settings',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const _AdminActiveUsersStats(),
              const SizedBox(height: 16),
              const _AdminDailyReadingsStats(),
              const SizedBox(height: 16),
              _buildCard(
                context,
                icon: Icons.vpn_key,
                title: 'Invite Codes',
                subtitle: 'Generate codes for Doctor and Admin registration',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InviteCodesPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                icon: Icons.people,
                title: 'User Management',
                subtitle: 'Manage patients, doctors, and admins',
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminUserManagementPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                icon: Icons.bar_chart,
                title: 'System Monitoring',
                subtitle: 'Readings and active users trends (last 14 days)',
                color: Colors.blueGrey,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminSystemMonitoringPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                icon: Icons.history,
                title: 'Audit logs',
                subtitle: 'Filter by action, user, and date; paginated list',
                color: Colors.brown,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminAuditLogsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                icon: Icons.backup,
                title: 'Data Backup Export',
                subtitle: 'Export selected collections to JSON (web/desktop)',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminBackupExportPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                icon: Icons.restore,
                title: 'Data Restore Import',
                subtitle: 'Validate backup JSON, dry-run, then import',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminBackupRestorePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                icon: Icons.verified_user,
                title: 'Role Assignment',
                subtitle: 'Assign and modify user roles',
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                icon: Icons.settings,
                title: 'System Settings',
                subtitle: 'Configure app-wide settings',
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha:0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AdminActiveUsersStats extends StatelessWidget {
  const _AdminActiveUsersStats();

  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance.collection('users');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: users.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _StatsCard(
            title: 'Active users',
            subtitle: 'Loading…',
            rows: [],
            icon: Icons.people_outline,
            iconColor: Colors.teal,
          );
        }
        if (snap.hasError) {
          return _StatsCard(
            title: 'Active users',
            subtitle: 'Failed to load',
            rows: [
              _StatsRow(label: 'Error', value: snap.error.toString()),
            ],
            icon: Icons.people_outline,
            iconColor: Colors.teal,
          );
        }

        var total = 0;
        var patients = 0;
        var doctors = 0;
        var admins = 0;
        var suspended = 0;

        for (final d in snap.data?.docs ?? const []) {
          final data = d.data();
          final blocked = data['blocked'] as bool? ?? false;
          if (blocked) {
            suspended += 1;
            continue;
          }
          total += 1;
          final role = UserRole.fromString(data['role'] as String?) ?? UserRole.patient;
          switch (role) {
            case UserRole.patient:
              patients += 1;
            case UserRole.doctor:
              doctors += 1;
            case UserRole.admin:
              admins += 1;
          }
        }

        return _StatsCard(
          title: 'Active users',
          subtitle: 'Not suspended (blocked=false)',
          rows: [
            _StatsRow(label: 'Total', value: '$total'),
            _StatsRow(label: 'Patients', value: '$patients'),
            _StatsRow(label: 'Doctors', value: '$doctors'),
            _StatsRow(label: 'Admins', value: '$admins'),
            _StatsRow(label: 'Suspended', value: '$suspended'),
          ],
          icon: Icons.people_outline,
          iconColor: Colors.teal,
        );
      },
    );
  }
}

/// Glucose readings in `glucose_readings` use `date` (ISO string) per [GlucoseReading].
class _AdminDailyReadingsStats extends StatelessWidget {
  const _AdminDailyReadingsStats();

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final readings = FirebaseFirestore.instance.collection('glucose_readings');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: readings.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _StatsCard(
            title: 'Glucose readings',
            subtitle: 'Loading…',
            rows: [],
            icon: Icons.monitor_heart_outlined,
            iconColor: Colors.deepOrange,
          );
        }
        if (snap.hasError) {
          return _StatsCard(
            title: 'Glucose readings',
            subtitle: 'Failed to load',
            rows: [
              _StatsRow(label: 'Error', value: snap.error.toString()),
            ],
            icon: Icons.monitor_heart_outlined,
            iconColor: Colors.deepOrange,
          );
        }

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final tomorrowStart = todayStart.add(const Duration(days: 1));
        final weekStart = todayStart.subtract(const Duration(days: 6));

        var todayCount = 0;
        var last7Count = 0;

        for (final d in snap.data?.docs ?? const []) {
          final dt = _parseDate(d.data()['date']);
          if (dt == null) continue;
          if (!dt.isBefore(todayStart) && dt.isBefore(tomorrowStart)) {
            todayCount += 1;
          }
          if (!dt.isBefore(weekStart) && dt.isBefore(tomorrowStart)) {
            last7Count += 1;
          }
        }

        return _StatsCard(
          title: 'Glucose readings',
          subtitle: 'All patients (local calendar day)',
          rows: [
            _StatsRow(label: 'Today', value: '$todayCount'),
            _StatsRow(label: 'Last 7 days', value: '$last7Count'),
          ],
          icon: Icons.monitor_heart_outlined,
          iconColor: Colors.deepOrange,
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.title,
    required this.subtitle,
    required this.rows,
    this.icon = Icons.insights,
    this.iconColor = Colors.teal,
  });

  final String title;
  final String subtitle;
  final List<_StatsRow> rows;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: rows.map((r) => _StatPill(row: r)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow {
  const _StatsRow({required this.label, required this.value});
  final String label;
  final String value;
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.row});
  final _StatsRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            row.label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            row.value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

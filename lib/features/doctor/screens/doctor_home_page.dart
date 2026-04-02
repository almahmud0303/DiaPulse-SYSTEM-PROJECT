import 'package:dia_plus/models/patient_risk.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:dia_plus/features/shared/screens/conversation_list_page.dart';
import 'package:flutter/material.dart';
import 'package:dia_plus/ui/responsive.dart';
import 'package:dia_plus/ui/widgets/wellness_card.dart';

import 'doctor_alerts_page.dart';
import 'doctor_appointments_page.dart';
import 'doctor_monitoring_dashboard_page.dart';
import 'doctor_patients_page.dart';

/// Doctor-specific home screen.
class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final DoctorPatientService _service = DoctorPatientService();
  int _highRiskCount = 0;
  int _poorControlCount = 0;
  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final list = await _service.getPatients();
      final risks = await Future.wait(
        list.map((p) => _service.getPatientRisk(p.uid)),
      );
      if (!mounted) return;
      var highRisk = 0;
      var poorControl = 0;
      for (final r in risks) {
        if (r == null) continue;
        if (r.level == RiskLevel.elevated || r.level == RiskLevel.high) {
          highRisk++;
        } else if (r.level == RiskLevel.moderate) {
          poorControl++;
        }
      }
      setState(() {
        _highRiskCount = highRisk;
        _poorControlCount = poorControl;
        _summaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _summaryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ResponsiveCenter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final tileWidth = isWide
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              Widget tile(Widget child) =>
                  SizedBox(width: tileWidth, child: child);

              final actions = [
                tile(
                  _buildCard(
                    context,
                    icon: Icons.people,
                    title: 'My Patients',
                    subtitle: 'View and manage patient consultations',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const DoctorPatientsPage(),
                        ),
                      );
                    },
                  ),
                ),
                tile(
                  _buildCard(
                    context,
                    icon: Icons.monitor_heart,
                    title: 'Monitoring Dashboard',
                    subtitle: 'High-risk and poor-control patients',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const DoctorMonitoringDashboardPage(),
                        ),
                      );
                    },
                  ),
                ),
                tile(
                  _buildCard(
                    context,
                    icon: Icons.notifications_active,
                    title: 'Alerts',
                    subtitle: 'Very high sugar, missed medicines',
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const DoctorAlertsPage(),
                        ),
                      );
                    },
                  ),
                ),
                tile(
                  _buildCard(
                    context,
                    icon: Icons.schedule,
                    title: 'Appointments',
                    subtitle: 'Upcoming and past appointments',
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const DoctorAppointmentsPage(),
                        ),
                      );
                    },
                  ),
                ),
                tile(
                  _buildCard(
                    context,
                    icon: Icons.chat,
                    title: 'Messages',
                    subtitle: 'Patient messages and inquiries',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const ConversationListPage(),
                        ),
                      );
                    },
                  ),
                ),
              ];

              return SingleChildScrollView(
                padding: pad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryMint,
                          child: const Icon(
                            Icons.medical_services,
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
                                'Doctor Dashboard',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your consultations',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildMonitoringSummaryCard(context),
                    const SizedBox(height: 24),
                    if (isWide)
                      Wrap(spacing: 16, runSpacing: 16, children: actions)
                    else
                      Column(
                        children: actions
                            .map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: w,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              );
            },
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
      child: WellnessCard(
        padding: const EdgeInsets.all(20),
        tint: AppTheme.cardTintMint,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringSummaryCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const DoctorMonitoringDashboardPage(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardTintLavender,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.secondaryLavender.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x12000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryMint.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart,
                color: AppTheme.textPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 7 days summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_summaryLoading)
                    Text(
                      'Loading…',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else
                    Text(
                      '$_highRiskCount high risk · $_poorControlCount poor control',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

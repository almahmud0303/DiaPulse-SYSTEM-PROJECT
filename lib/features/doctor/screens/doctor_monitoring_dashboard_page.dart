import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/patient_risk.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:flutter/material.dart';

import 'doctor_patient_profile_page.dart';

/// Monitoring dashboard: high-risk and poor-control patients at a glance.
/// High risk = elevated or high; Poor control = moderate (above target).
class DoctorMonitoringDashboardPage extends StatefulWidget {
  const DoctorMonitoringDashboardPage({super.key});

  @override
  State<DoctorMonitoringDashboardPage> createState() =>
      _DoctorMonitoringDashboardPageState();
}

class _DoctorMonitoringDashboardPageState
    extends State<DoctorMonitoringDashboardPage> {
  final DoctorPatientService _service = DoctorPatientService();
  List<AppUser> _patients = [];
  List<PatientRisk?> _risks = [];
  Map<String, List<GlucoseReading>> _latestReadings = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _latestReadings = {};
    });
    try {
      final list = await _service.getPatients();
      final risks = await Future.wait(
        list.map((p) => _service.getPatientRisk(p.uid)),
      );
      if (!mounted) return;
      setState(() {
        _patients = list;
        _risks = risks;
      });
      // Load latest readings for patients that appear in high-risk or poor-control
      final highRiskIds = <String>{};
      for (var i = 0; i < list.length; i++) {
        final r = i < risks.length ? risks[i] : null;
        if (r != null &&
            (r.level == RiskLevel.elevated ||
                r.level == RiskLevel.high ||
                r.level == RiskLevel.moderate)) {
          highRiskIds.add(list[i].uid);
        }
      }
      final latestMap = <String, List<GlucoseReading>>{};
      await Future.wait(
        highRiskIds.map((id) async {
          final readings = await _service.getLatestReadings(id, limit: 3);
          latestMap[id] = readings;
        }),
      );
      if (!mounted) return;
      setState(() {
        _latestReadings = latestMap;
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

  /// High risk = elevated or high.
  List<_PatientWithRisk> get _highRisk {
    final result = <_PatientWithRisk>[];
    for (var i = 0; i < _patients.length; i++) {
      final risk = i < _risks.length ? _risks[i] : null;
      if (risk != null &&
          (risk.level == RiskLevel.elevated || risk.level == RiskLevel.high)) {
        result.add(_PatientWithRisk(user: _patients[i], risk: risk));
      }
    }
    return result;
  }

  /// Poor control = moderate (above target, needs monitoring).
  List<_PatientWithRisk> get _poorControl {
    final result = <_PatientWithRisk>[];
    for (var i = 0; i < _patients.length; i++) {
      final risk = i < _risks.length ? _risks[i] : null;
      if (risk != null && risk.level == RiskLevel.moderate) {
        result.add(_PatientWithRisk(user: _patients[i], risk: risk));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Monitoring Dashboard'),
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      _buildSection(
                        title: 'High risk',
                        subtitle: 'Elevated or high risk – review soon',
                        list: _highRisk,
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                        emptyMessage:
                            'No high-risk patients in the last 7 days.',
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Poor control',
                        subtitle: 'Moderate risk – above target range',
                        list: _poorControl,
                        icon: Icons.trending_up,
                        color: Colors.orange,
                        emptyMessage:
                            'No patients in poor-control range right now.',
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
              style: TextStyle(color: Colors.grey.shade700),
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

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<_PatientWithRisk> list,
    required IconData icon,
    required Color color,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${list.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 40, color: Colors.grey.shade400),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...list.map(
            (p) => _MonitoringTile(
              user: p.user,
              risk: p.risk,
              latestReadings: _latestReadings[p.user.uid] ?? const [],
              onTap: () => _openProfile(p.user),
            ),
          ),
      ],
    );
  }

  void _openProfile(AppUser patient) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DoctorPatientProfilePage(patient: patient),
      ),
    );
  }
}

class _PatientWithRisk {
  const _PatientWithRisk({required this.user, required this.risk});
  final AppUser user;
  final PatientRisk risk;
}

class _MonitoringTile extends StatelessWidget {
  const _MonitoringTile({
    required this.user,
    required this.risk,
    this.latestReadings = const [],
    required this.onTap,
  });

  final AppUser user;
  final PatientRisk risk;
  final List<GlucoseReading> latestReadings;
  final VoidCallback onTap;

  static Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.moderate:
        return Colors.orange;
      case RiskLevel.elevated:
        return Colors.deepOrange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(risk.level);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isEmpty ? 'No name' : user.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        risk.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    if (risk.averageGlucose != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Avg ${risk.averageGlucose!.toStringAsFixed(0)} mg/dL · ${risk.readingCount} readings',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (latestReadings.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Latest: ${latestReadings.map((r) => r.glucoseLevel.toStringAsFixed(0)).join(', ')} mg/dL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      risk.summary,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

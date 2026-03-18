import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/patient_risk.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:flutter/material.dart';

import 'doctor_patient_profile_page.dart';

/// Lists all patients for the doctor; tap opens [DoctorPatientProfilePage].
/// If [selectedPatientId] is set, opens that patient's profile after load (e.g. from Appointments).
class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({super.key, this.selectedPatientId});

  final String? selectedPatientId;

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final AuthService _authService = AuthService();
  final DoctorPatientService _service = DoctorPatientService();
  List<AppUser> _patients = [];
  List<PatientRisk?> _risks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await _authService.getAppUser();
      if (me == null || !me.isDoctor) {
        if (!mounted) return;
        setState(() {
          _error = 'Not signed in as doctor';
          _loading = false;
        });
        return;
      }

      final list = await _service.getMyPatientsForDoctor(me.uid);
      final risks = await Future.wait(list.map((p) => _service.getPatientRisk(p.uid)));
      if (!mounted) return;
      setState(() {
        _patients = list;
        _risks = risks;
        _loading = false;
      });
      final id = widget.selectedPatientId;
      if (id != null && id.isNotEmpty) {
        final match = list.where((p) => p.uid == id);
        final patient = match.isEmpty ? null : match.first;
        if (patient != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => DoctorPatientProfilePage(patient: patient),
              ),
            );
          });
        } else {
          final fetched = await _service.getPatientProfile(id);
          if (fetched != null && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => DoctorPatientProfilePage(patient: fetched),
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load patients: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Patients'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                          onPressed: _loadPatients,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _patients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No patients yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Patients who register will appear here.',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPatients,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          final risk = index < _risks.length ? _risks[index] : null;
                          return _PatientTile(
                            patient: patient,
                            risk: risk,
                            onTap: () => _openProfile(patient),
                          );
                        },
                      ),
                    ),
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

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient, this.risk, required this.onTap});

  final AppUser patient;
  final PatientRisk? risk;
  final VoidCallback onTap;

  static Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.moderate:
        return Colors.blue;
      case RiskLevel.elevated:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            patient.initials,
            style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          patient.displayName.isEmpty ? 'No name' : patient.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              patient.email,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (risk != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _riskColor(risk!.level).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  risk!.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _riskColor(risk!.level),
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}

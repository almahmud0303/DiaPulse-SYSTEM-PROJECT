import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:flutter/material.dart';

/// Doctor screen: list of patients with latest reading and risk status.
class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final DoctorPatientService _service = DoctorPatientService();
  List<AppUser> _patients = [];
  Map<String, GlucoseReading?> _latestReadings = {};
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
    });
    try {
      final patients = await _service.getPatients();
      final readings = <String, GlucoseReading?>{};
      for (final p in patients) {
        readings[p.uid] = await _service.getLatestReading(p.uid);
      }
      if (mounted) {
        setState(() {
          _patients = patients;
          _latestReadings = readings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Patients')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Patients')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _patients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No patients yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _patients.length,
                itemBuilder: (context, index) {
                  final patient = _patients[index];
                  final reading = _latestReadings[patient.uid];
                  final risk = DoctorPatientService.riskFromReading(reading);
                  return _PatientTile(
                    patient: patient,
                    latestReading: reading,
                    risk: risk,
                    onTap: () {
                      // TODO: navigate to doctor patient profile (d2)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile: ${patient.displayName}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({
    required this.patient,
    required this.latestReading,
    required this.risk,
    required this.onTap,
  });

  final AppUser patient;
  final GlucoseReading? latestReading;
  final String risk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(risk);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          child: Text(
            patient.initials,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.displayName.isNotEmpty ? patient.displayName : patient.email,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (latestReading != null)
              Text(
                'Latest: ${latestReading!.glucoseLevel.toInt()} mg/dL · ${latestReading!.mealTime}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              )
            else
              Text(
                'No readings yet',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            risk.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          backgroundColor: riskColor.withValues(alpha: 0.2),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Color _riskColor(String r) {
    switch (r) {
      case 'low':
        return Colors.blue;
      case 'normal':
        return Colors.green;
      case 'high':
        return Colors.orange;
      case 'very_high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

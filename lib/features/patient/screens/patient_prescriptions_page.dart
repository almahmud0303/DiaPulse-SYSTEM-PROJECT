import 'package:dia_plus/features/patient/screens/patient_prescription_detail_page.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/prescription.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Patient: list prescriptions (issue date, issued by, medicines count).
class PatientPrescriptionsPage extends StatefulWidget {
  const PatientPrescriptionsPage({super.key, this.openPrescriptionId});

  final String? openPrescriptionId;

  @override
  State<PatientPrescriptionsPage> createState() => _PatientPrescriptionsPageState();
}

class _PatientPrescriptionsPageState extends State<PatientPrescriptionsPage> {
  final AuthService _authService = AuthService();
  final MedicineService _medicineService = MedicineService();

  bool _loading = true;
  String? _error;
  String? _uid;
  List<Prescription> _prescriptions = [];
  Map<String, List<Medicine>> _medicinesByRx = {};

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
      final list = await _medicineService.getPrescriptions(user.uid);
      final grouped = await _medicineService.getMedicinesGroupedByPrescription(user.uid);
      if (!mounted) return;
      setState(() {
        _uid = user.uid;
        _prescriptions = list;
        _medicinesByRx = grouped;
        _loading = false;
      });

      final targetId = widget.openPrescriptionId;
      if (targetId != null && targetId.isNotEmpty) {
        final matches = list.where((p) => p.id == targetId);
        final rx = matches.isEmpty ? null : matches.first;
        if (rx != null && mounted) {
          _open(rx);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  Future<void> _open(Prescription rx) async {
    if (_uid == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientPrescriptionDetailPage(
          prescription: rx,
          patientId: _uid!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy · HH:mm');
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _prescriptions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No prescriptions yet.', style: TextStyle(color: Colors.grey.shade700)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _prescriptions.length,
                        itemBuilder: (_, i) {
                          final rx = _prescriptions[i];
                          final issuedBy = (rx.issuedByName ?? '').trim().isNotEmpty ? rx.issuedByName!.trim() : 'Doctor';
                          final meds = _medicinesByRx[rx.id] ?? const <Medicine>[];
                          final count = meds.length;
                          final previewNames = meds.map((m) => m.name).join(', ');
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _open(rx),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.teal.withValues(alpha: 0.12),
                                      child: const Icon(Icons.assignment_outlined, color: Colors.teal),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Prescription · ${df.format(rx.createdAt)}',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Issued by $issuedBy',
                                            style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.medication_outlined, size: 18, color: Colors.teal.shade700),
                                              const SizedBox(width: 6),
                                              Text(
                                                count == 0
                                                    ? 'No medicines linked — tap to refresh details'
                                                    : '$count medicine${count == 1 ? '' : 's'}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: count == 0 ? Colors.orange.shade800 : Colors.black87,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (previewNames.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              previewNames,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                height: 1.35,
                                                color: Colors.grey.shade900,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}


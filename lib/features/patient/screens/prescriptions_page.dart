import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/features/shared/screens/pdf_bytes_preview_page.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/prescription_bundle.dart';
import 'package:dia_plus/services/prescription_bundle_pdf_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _pdfService = PrescriptionBundlePdfService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  bool _loading = true;
  String? _error;
  List<PrescriptionBundle> _bundles = [];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _patientName {
    final u = FirebaseAuth.instance.currentUser;
    final name = (u?.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    return (u?.email ?? '').trim();
  }

  @override
  void initState() {
    super.initState();
    if (_uid.isEmpty) {
      _loading = false;
      _error = 'Not signed in';
      return;
    }
    _listen();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listen() {
    _sub?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });

    _sub = _firestore
        .collection('medicines')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .listen(
      (snap) {
        final meds = snap.docs.map((d) => Medicine.fromMap(d.data())).toList();
        final bundles = _groupBundles(meds);
        if (!mounted) return;
        setState(() {
          _bundles = bundles;
          _loading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _error = '$e';
          _loading = false;
        });
      },
    );
  }

  List<PrescriptionBundle> _groupBundles(List<Medicine> medicines) {
    final prescribed = medicines.where((m) => m.prescribedAt != null || m.prescribedByUid != null).toList();
    final map = <String, List<Medicine>>{};
    final issuedAtMap = <String, DateTime>{};
    final issuedByUidMap = <String, String?>{};
    final issuedByNameMap = <String, String?>{};

    for (final m in prescribed) {
      final at = m.prescribedAt ?? m.createdAt;
      final dayKey = DateTime(at.year, at.month, at.day);
      final by = (m.prescribedByUid ?? '').trim();
      final key = '${dayKey.toIso8601String()}|$by';
      map.putIfAbsent(key, () => []).add(m);
      issuedAtMap[key] ??= dayKey;
      issuedByUidMap[key] ??= m.prescribedByUid;
      issuedByNameMap[key] ??= m.prescribedByName;
    }

    final bundles = map.entries.map((e) {
      final meds = e.value..sort((a, b) => a.time.compareTo(b.time));
      return PrescriptionBundle(
        patientId: _uid,
        issuedAt: issuedAtMap[e.key] ?? DateTime.now(),
        issuedByUid: issuedByUidMap[e.key],
        issuedByName: issuedByNameMap[e.key],
        medicines: meds,
      );
    }).toList();

    bundles.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return bundles;
  }

  Future<void> _exportPdf(PrescriptionBundle bundle) async {
    try {
      final bytes = await _pdfService.generatePdf(bundle: bundle, patientName: _patientName);
      if (!mounted) return;
      final safeDate = DateFormat('yyyyMMdd').format(bundle.issuedAt);
      final safeName = _patientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = 'Prescription_${safeName}_$safeDate.pdf';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfBytesPreviewPage(
            title: 'Prescription PDF',
            pdfBytes: bytes,
            fileName: fileName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _listen,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _bundles.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No prescriptions yet.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bundles.length,
                      itemBuilder: (context, index) {
                        final b = _bundles[index];
                        final issuer = (b.issuedByName ?? '').trim().isNotEmpty ? b.issuedByName!.trim() : (b.issuedByUid ?? 'Doctor');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.withValues(alpha: 0.12),
                              child: const Icon(Icons.description_outlined, color: Colors.teal),
                            ),
                            title: Text('Prescription • ${df.format(b.issuedAt)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('$issuer • ${b.medicines.length} medicine${b.medicines.length == 1 ? '' : 's'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              tooltip: 'Export PDF',
                              onPressed: () => _exportPdf(b),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => _PrescriptionBundleDetailsPage(bundle: b)),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

class _PrescriptionBundleDetailsPage extends StatelessWidget {
  const _PrescriptionBundleDetailsPage({required this.bundle});

  final PrescriptionBundle bundle;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');
    final issuer = (bundle.issuedByName ?? '').trim().isNotEmpty ? bundle.issuedByName!.trim() : (bundle.issuedByUid ?? 'Doctor');

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Issued on', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(df.format(bundle.issuedAt), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text('Issued by', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(issuer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...bundle.medicines.map((m) {
            final freq = m.frequency.replaceAll('_', ' ');
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${m.dosage} • ${m.time} • $freq'),
              ),
            );
          }),
        ],
      ),
    );
  }
}


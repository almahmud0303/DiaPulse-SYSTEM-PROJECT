import 'dart:typed_data';

import 'package:dia_plus/features/shared/screens/pdf_bytes_preview_page.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/prescription.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PatientPrescriptionDetailPage extends StatefulWidget {
  const PatientPrescriptionDetailPage({
    super.key,
    required this.prescription,
    required this.patientId,
  });

  final Prescription prescription;
  final String patientId;

  @override
  State<PatientPrescriptionDetailPage> createState() => _PatientPrescriptionDetailPageState();
}

class _PatientPrescriptionDetailPageState extends State<PatientPrescriptionDetailPage> {
  final MedicineService _medicineService = MedicineService();
  bool _loading = true;
  List<Medicine> _medicines = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final meds = await _medicineService.getMedicinesForPrescription(
        widget.patientId,
        widget.prescription.id,
      );
      if (!mounted) return;
      setState(() {
        _medicines = meds;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<Uint8List> _buildPdfBytes() async {
    final rx = widget.prescription;
    final list = _medicines;
    final doc = pw.Document();
    final df = DateFormat('MMM d, yyyy · HH:mm');
    final issuedBy = (rx.issuedByName ?? '').trim().isNotEmpty ? rx.issuedByName!.trim() : 'Doctor';

    pw.Widget header() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Prescription', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Issued by: $issuedBy'),
          pw.Text('Date: ${df.format(rx.createdAt)}'),
          pw.Text('Medicines: ${list.length}'),
        ],
      );
    }

    pw.Widget table() {
      final data = list.map((m) {
        final when = Medicine.medicineTimesLabel(m);
        final name = m.isInsulin ? '${m.name} (${Medicine.insulinTypeLabel(m.insulinType)})' : m.name;
        return [name, m.dosage, when, m.frequency.replaceAll('_', ' ')];
      }).toList();
      return pw.TableHelper.fromTextArray(
        headers: const ['Medicine', 'Dosage', 'When to take', 'Frequency'],
        data: data,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellAlignment: pw.Alignment.centerLeft,
        cellStyle: const pw.TextStyle(fontSize: 10),
        headerHeight: 22,
        cellHeight: 22,
        columnWidths: {
          0: const pw.FlexColumnWidth(3.2),
          1: const pw.FlexColumnWidth(1.3),
          2: const pw.FlexColumnWidth(2.2),
          3: const pw.FlexColumnWidth(1.5),
        },
      );
    }

    pw.Widget notes() {
      final withNotes = list.where((m) => m.adjustmentInstructions != null && m.adjustmentInstructions!.trim().isNotEmpty).toList();
      if (withNotes.isEmpty) return pw.SizedBox.shrink();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 14),
          pw.Text('Notes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          ...withNotes.map((m) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: '${m.name}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.TextSpan(text: m.adjustmentInstructions!.trim()),
                    ],
                  ),
                ),
              )),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [header(), pw.SizedBox(height: 16), table(), notes()],
      ),
    );
    return doc.save();
  }

  Future<void> _previewPdf() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicines in this prescription'), backgroundColor: Colors.orange),
      );
      return;
    }
    final bytes = await _buildPdfBytes();
    final df = DateFormat('yyyyMMdd_HHmm');
    final fileName = 'prescription_${df.format(widget.prescription.createdAt)}.pdf';
    if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final rx = widget.prescription;
    final df = DateFormat('MMM d, yyyy · HH:mm');
    final issuedBy = (rx.issuedByName ?? '').trim().isNotEmpty ? rx.issuedByName!.trim() : 'Doctor';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Prescription'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            onPressed: _loading ? null : _previewPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
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
                          Text(df.format(rx.createdAt), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Text('Issued by', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(issuedBy, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_medicines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No medicines in this prescription.', style: TextStyle(color: Colors.grey.shade700)),
                    )
                  else
                    ..._medicines.map((m) {
                      final sub = '${m.dosage} · ${Medicine.medicineTimesLabel(m)} · ${m.frequency.replaceAll('_', ' ')}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(sub),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}


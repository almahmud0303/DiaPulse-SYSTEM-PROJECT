import 'dart:typed_data';

import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/prescription.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'doctor_add_edit_prescription_page.dart';

/// View a prescription group: list of medicines + Generate PDF.
class DoctorPrescriptionDetailPage extends StatefulWidget {
  const DoctorPrescriptionDetailPage({
    super.key,
    required this.patient,
    required this.prescription,
    this.medicines,
  });

  final AppUser patient;
  final Prescription prescription;
  final List<Medicine>? medicines;

  @override
  State<DoctorPrescriptionDetailPage> createState() =>
      _DoctorPrescriptionDetailPageState();
}

class _DoctorPrescriptionDetailPageState
    extends State<DoctorPrescriptionDetailPage> {
  final MedicineService _medicineService = MedicineService();
  List<Medicine>? _medicines;
  bool _loading = true;

  List<Medicine> get medicines => _medicines ?? widget.medicines ?? [];

  @override
  void initState() {
    super.initState();
    if (widget.medicines != null) {
      _medicines = widget.medicines;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _medicineService.getMedicinesForPrescription(
        widget.patient.uid,
        widget.prescription.id,
      );
      if (!mounted) return;
      setState(() {
        _medicines = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<Uint8List> _buildPdfBytes() async {
    final patient = widget.patient;
    final rx = widget.prescription;
    final list = medicines;
    final doc = pw.Document();
    final df = DateFormat('MMM d, yyyy · HH:mm');

    pw.Widget header() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Prescription',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Patient: ${patient.displayName.isNotEmpty ? patient.displayName : patient.email}',
          ),
          pw.Text('Date: ${df.format(rx.createdAt)}'),
          pw.Text('Medicines: ${list.length}'),
        ],
      );
    }

    pw.Widget table() {
      final data = list.map((m) {
        final when = Medicine.medicineTimesLabel(m);
        final name = m.isInsulin
            ? '${m.name} (${Medicine.insulinTypeLabel(m.insulinType)})'
            : m.name;
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
      final withNotes = list
          .where(
            (m) =>
                m.adjustmentInstructions != null &&
                m.adjustmentInstructions!.trim().isNotEmpty,
          )
          .toList();
      if (withNotes.isEmpty) return pw.SizedBox.shrink();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 14),
          pw.Text(
            'Notes',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...withNotes.map(
            (m) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: '${m.name}: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(text: m.adjustmentInstructions!.trim()),
                  ],
                ),
              ),
            ),
          ),
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

  Future<void> _generatePdf() async {
    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No medicines in this prescription'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      final bytes = await _buildPdfBytes();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name:
            'prescription_${widget.patient.displayName.isNotEmpty ? widget.patient.displayName : widget.patient.uid}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addMedicineToThisPrescription() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorAddEditPrescriptionPage(
          patient: widget.patient,
          appendToPrescriptionId: widget.prescription.id,
        ),
      ),
    );
    _load();
  }

  Future<void> _deleteThisPrescription() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete prescription?'),
        content: const Text(
          'This will delete the whole prescription (all medicines).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _medicineService.deletePrescription(
      prescriptionId: widget.prescription.id,
      patientId: widget.patient.uid,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final rx = widget.prescription;
    final df = DateFormat('MMM d, yyyy · HH:mm');
    final list = medicines;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('View prescription'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Add medicine',
            onPressed: _loading ? null : _addMedicineToThisPrescription,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Generate PDF',
            onPressed: list.isEmpty ? null : _generatePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Delete prescription',
            onPressed: _loading ? null : _deleteThisPrescription,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Prescription · ${df.format(rx.createdAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Patient: ${widget.patient.displayName.isNotEmpty ? widget.patient.displayName : widget.patient.email}',
                    style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                  ),
                  const SizedBox(height: 20),
                  if (list.isEmpty)
                    Text(
                      'No medicines in this prescription.',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    )
                  else
                    ...list.map((m) {
                      final sub =
                          '${m.dosage} · ${Medicine.medicineTimesLabel(m)} · ${m.frequency.replaceAll('_', ' ')}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: AppTheme.surfaceColor(context),
                        child: ListTile(
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(
                            m.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            sub,
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

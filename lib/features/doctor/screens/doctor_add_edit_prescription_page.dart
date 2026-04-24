// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/prescription.dart';
import 'package:dia_plus/services/drug_suggestion_service.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dia_plus/services/notification_service.dart';

import 'doctor_prescription_detail_page.dart';

/// Doctor: add or edit a prescription (medicine) for a patient.
class DoctorAddEditPrescriptionPage extends StatefulWidget {
  const DoctorAddEditPrescriptionPage({
    super.key,
    required this.patient,
    this.medicine,
    this.appendToPrescriptionId,
  });

  final AppUser patient;
  final Medicine? medicine;
  /// When set, saving in add-mode appends medicines to this prescription group.
  final String? appendToPrescriptionId;

  @override
  State<DoctorAddEditPrescriptionPage> createState() => _DoctorAddEditPrescriptionPageState();
}

class _PrescriptionDraftItem {
  const _PrescriptionDraftItem({
    required this.name,
    required this.dosageValue,
    required this.dosageUnit,
    required this.frequency,
    required this.times,
    required this.isInsulin,
    this.insulinType,
    this.adjustmentInstructions,
    this.mealOffsetMinutes = 30,
  });

  final String name;
  final int dosageValue;
  final String dosageUnit;
  final String frequency;
  final List<String> times;
  final bool isInsulin;
  final String? insulinType;
  final String? adjustmentInstructions;
  final int mealOffsetMinutes;

  String get dosage => Medicine.buildDosageText(dosageValue, dosageUnit);

  bool get hasMealRelative => times.any(Medicine.isMealRelativeTime);
}

class _DoctorAddEditPrescriptionPageState extends State<DoctorAddEditPrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _adjustmentInstructionsController = TextEditingController();
  final DrugSuggestionService _drugSuggestionService = DrugSuggestionService();
  final MedicineService _medicineService = MedicineService();
  final NotificationService _notificationService = NotificationService();
  Timer? _medicineSuggestionDebounce;
  List<String> _medicineSuggestions = const [];
  bool _loadingMedicineSuggestions = false;

  /// 'specific' = use time picker; otherwise meal-relative key (after_lunch, etc.)
  String _whenToTake1 = 'specific';
  TimeOfDay _time1 = const TimeOfDay(hour: 9, minute: 0);
  String _whenToTake2 = 'specific';
  TimeOfDay _time2 = const TimeOfDay(hour: 19, minute: 0);
  String _whenToTake3 = 'specific';
  TimeOfDay _time3 = const TimeOfDay(hour: 22, minute: 0);
  String _frequency = 'once_daily';
  String _dosageUnit = 'tablet';
  int _mealOffsetMinutes = 30;
  bool _isInsulin = false;
  String _insulinType = 'rapid_acting';
  bool _saving = false;
  final List<_PrescriptionDraftItem> _draftItems = [];

  static const List<Map<String, String>> frequencies = [
    {'value': 'once_daily', 'label': 'Once daily'},
    {'value': 'twice_daily', 'label': 'Twice daily'},
    {'value': 'thrice_daily', 'label': 'Thrice daily'},
    {'value': 'once_weekly', 'label': 'Once a week'},
    {'value': 'once_biweekly', 'label': 'Once every 2 weeks'},
  ];

  static const List<String> dosageUnits = [
    'tablet',
    'mg',
    'spoon',
    'capsule',
    'drop',
    'ml',
    'unit',
  ];

  static const List<Map<String, String>> insulinTypes = [
    {'value': 'rapid_acting', 'label': 'Rapid-acting'},
    {'value': 'short_acting', 'label': 'Short-acting'},
    {'value': 'intermediate_acting', 'label': 'Intermediate-acting'},
    {'value': 'long_acting', 'label': 'Long-acting'},
    {'value': 'mixed', 'label': 'Mixed'},
  ];

  String _normalizeFrequency(String raw) {
    switch (raw) {
      case 'daily':
        return 'once_daily';
      case 'weekly':
        return 'once_weekly';
      case 'twice_weekly':
        return 'once_weekly'; // Legacy fallback for removed option
      default:
        return frequencies.any((f) => f['value'] == raw)
            ? raw
            : 'once_daily';
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onMedicineNameChanged);
    final m = widget.medicine;
    if (m != null) {
      _nameController.text = m.name;
      final dosageParts = Medicine.parseDosage(m.dosage);
      _dosageController.text =
          ((m.dosageValue ?? dosageParts.$1) ?? 1).toString();
      _dosageUnit = (m.dosageUnit ?? dosageParts.$2 ?? 'tablet').toLowerCase();
      if (!dosageUnits.contains(_dosageUnit)) {
        _dosageUnit = 'tablet';
      }
      _frequency = _normalizeFrequency(m.frequency);
      final times = m.effectiveTimes;
      _applyTimeToState(isSecond: false, value: times.isNotEmpty ? times.first : m.time);
      if (times.length > 1) {
        _applyTimeToState(isSecond: true, value: times[1]);
      }
      if (times.length > 2) {
        _applyTimeToState(isThird: true, value: times[2]);
      }
      _isInsulin = m.isInsulin;
      _insulinType = m.insulinType ?? 'rapid_acting';
      _adjustmentInstructionsController.text = m.adjustmentInstructions ?? '';
      _mealOffsetMinutes = m.mealOffsetMinutes;
    }
  }

  @override
  void dispose() {
    _medicineSuggestionDebounce?.cancel();
    _nameController.removeListener(_onMedicineNameChanged);
    _nameController.dispose();
    _dosageController.dispose();
    _adjustmentInstructionsController.dispose();
    super.dispose();
  }

  void _onMedicineNameChanged() {
    final query = _nameController.text.trim();
    _medicineSuggestionDebounce?.cancel();

    if (query.length < 2) {
      if (_medicineSuggestions.isNotEmpty || _loadingMedicineSuggestions) {
        setState(() {
          _medicineSuggestions = const [];
          _loadingMedicineSuggestions = false;
        });
      }
      return;
    }

    _medicineSuggestionDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchMedicineSuggestions(query);
    });
  }

  Future<void> _fetchMedicineSuggestions(String query) async {
    setState(() => _loadingMedicineSuggestions = true);
    try {
      final suggestions = await _drugSuggestionService.suggestMedicineNames(query);
      if (!mounted) return;
      if (_nameController.text.trim() != query) return;
      setState(() {
        _medicineSuggestions = suggestions;
        _loadingMedicineSuggestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _medicineSuggestions = const [];
        _loadingMedicineSuggestions = false;
      });
    }
  }

  void _applyMedicineSuggestion(String value) {
    _medicineSuggestionDebounce?.cancel();
    _nameController.text = value;
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    setState(() {
      _medicineSuggestions = const [];
      _loadingMedicineSuggestions = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time1);
    if (picked != null) setState(() => _time1 = picked);
  }

  Future<void> _pickTime2() async {
    final picked = await showTimePicker(context: context, initialTime: _time2);
    if (picked != null) setState(() => _time2 = picked);
  }

  Future<void> _pickTime3() async {
    final picked = await showTimePicker(context: context, initialTime: _time3);
    if (picked != null) setState(() => _time3 = picked);
  }

  void _applyTimeToState({bool isSecond = false, bool isThird = false, required String value}) {
    if (Medicine.isMealRelativeTime(value)) {
      if (isThird) {
        _whenToTake3 = value;
      } else if (isSecond) {
        _whenToTake2 = value;
      } else {
        _whenToTake1 = value;
      }
      return;
    }
    final parts = value.split(':');
    final t = (parts.length >= 2)
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          )
        : const TimeOfDay(hour: 9, minute: 0);
    if (isThird) {
      _whenToTake3 = 'specific';
      _time3 = t;
    } else if (isSecond) {
      _whenToTake2 = 'specific';
      _time2 = t;
    } else {
      _whenToTake1 = 'specific';
      _time1 = t;
    }
  }

  String _timeString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _savedTime1 => _whenToTake1 == 'specific' ? _timeString(_time1) : _whenToTake1;
  String get _savedTime2 => _whenToTake2 == 'specific' ? _timeString(_time2) : _whenToTake2;
  String get _savedTime3 => _whenToTake3 == 'specific' ? _timeString(_time3) : _whenToTake3;

  List<String> get _savedTimes {
    if (_frequency == 'twice_daily') {
      return [_savedTime1, _savedTime2];
    }
    if (_frequency == 'thrice_daily') {
      return [_savedTime1, _savedTime2, _savedTime3];
    }
    return [_savedTime1];
  }

  bool get _anyMealRelative => _savedTimes.any(Medicine.isMealRelativeTime);

  void _resetForNext() {
    _nameController.clear();
    _dosageController.clear();
    _adjustmentInstructionsController.clear();
    _frequency = 'once_daily';
    _whenToTake1 = 'specific';
    _time1 = const TimeOfDay(hour: 9, minute: 0);
    _whenToTake2 = 'specific';
    _time2 = const TimeOfDay(hour: 19, minute: 0);
    _whenToTake3 = 'specific';
    _time3 = const TimeOfDay(hour: 22, minute: 0);
    _dosageUnit = 'tablet';
    _isInsulin = false;
    _insulinType = 'rapid_acting';
    _mealOffsetMinutes = 30;
  }

  bool get _hasAnyInput =>
      _nameController.text.trim().isNotEmpty ||
      _dosageController.text.trim().isNotEmpty ||
      (_isInsulin && _adjustmentInstructionsController.text.trim().isNotEmpty);

  _PrescriptionDraftItem _buildDraftFromForm() {
    final times = _savedTimes;
    final dosageValue = int.parse(_dosageController.text.trim());
    return _PrescriptionDraftItem(
      name: _nameController.text.trim(),
      dosageValue: dosageValue,
      dosageUnit: _dosageUnit,
      frequency: _frequency,
      times: times,
      isInsulin: _isInsulin,
      insulinType: _isInsulin ? _insulinType : null,
      adjustmentInstructions: _isInsulin && _adjustmentInstructionsController.text.trim().isNotEmpty
          ? _adjustmentInstructionsController.text.trim()
          : null,
      mealOffsetMinutes: _mealOffsetMinutes,
    );
  }

  Future<void> _addCurrentToList() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _draftItems.add(_buildDraftFromForm());
      _resetForNext();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to prescription list'), backgroundColor: Colors.green),
    );
  }

  Future<void> _confirmDelete(Medicine existing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete prescription?'),
        content: Text('Delete "${existing.name}" for this patient? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _medicineService.deleteMedicine(existing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription deleted'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAppendToSamePrescription() async {
    final existing = widget.medicine;
    final pid = existing?.prescriptionId;
    if (pid == null || pid.isEmpty) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DoctorAddEditPrescriptionPage(
          patient: widget.patient,
          appendToPrescriptionId: pid,
        ),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<Uint8List> _buildPrescriptionPdfBytes({
    required AppUser patient,
    required List<_PrescriptionDraftItem> items,
    required bool includeDraftCount,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final df = DateFormat('MMM d, yyyy • HH:mm');

    pw.Widget header() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Prescription',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Patient: ${patient.displayName.isNotEmpty ? patient.displayName : patient.email}'),
          pw.Text('Generated: ${df.format(now)}'),
          if (includeDraftCount)
            pw.Text('Medicines: ${items.length}'),
        ],
      );
    }

    pw.Widget medicinesTable() {
      final headers = ['Medicine', 'Dosage', 'When to take', 'Frequency'];
      final data = items.map((item) {
        var when = item.times.map(Medicine.timeDisplayLabel).join(' / ');
        if (item.hasMealRelative) {
          when = '$when · ${item.mealOffsetMinutes} min before/after meal';
        }
        final freq = item.frequency.replaceAll('_', ' ');
        final name = item.isInsulin
            ? '${item.name} (${Medicine.insulinTypeLabel(item.insulinType)})'
            : item.name;
        return [
          name,
          item.dosage,
          when,
          freq,
        ];
      }).toList();

      return pw.TableHelper.fromTextArray(
        headers: headers,
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

    pw.Widget notesSection() {
      final notes = items
          .where((i) => i.adjustmentInstructions != null && i.adjustmentInstructions!.trim().isNotEmpty)
          .toList();
      if (notes.isEmpty) return pw.SizedBox.shrink();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 14),
          pw.Text('Notes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          ...notes.map((i) {
            final title = i.isInsulin
                ? '${i.name} (${Medicine.insulinTypeLabel(i.insulinType)})'
                : i.name;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '$title: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: i.adjustmentInstructions!.trim()),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          header(),
          pw.SizedBox(height: 16),
          medicinesTable(),
          notesSection(),
        ],
      ),
    );

    return doc.save();
  }

  /// Generate PDF for current draft list (add mode only).
  Future<void> _generatePdf() async {
    final items = <_PrescriptionDraftItem>[..._draftItems];
    if (_hasAnyInput) {
      if (!_formKey.currentState!.validate()) return;
      items.add(_buildDraftFromForm());
    }
    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medicine to generate PDF'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      final bytes = await _buildPrescriptionPdfBytes(
        patient: widget.patient,
        items: items,
        includeDraftCount: true,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'prescription_${widget.patient.displayName.isNotEmpty ? widget.patient.displayName : widget.patient.uid}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAfterSaveDialog(Prescription prescription, {required int savedCount}) async {
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prescription saved'),
        content: Text('$savedCount medicine${savedCount == 1 ? '' : 's'} saved. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'add_more'),
            child: const Text('Add more medicine'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'pdf'),
            child: const Text('Generate PDF'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'view'),
            child: const Text('View prescription'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'view':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorPrescriptionDetailPage(
              patient: widget.patient,
              prescription: prescription,
            ),
          ),
        );
        Navigator.pop(context, true);
        break;
      case 'pdf':
        final list = await _medicineService.getMedicinesForPrescription(widget.patient.uid, prescription.id);
        if (list.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No medicines to export')));
        } else {
          final doc = pw.Document();
          final df = DateFormat('MMM d, yyyy · HH:mm');
          pw.Widget header() {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Prescription', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('Patient: ${widget.patient.displayName.isNotEmpty ? widget.patient.displayName : widget.patient.email}'),
                pw.Text('Date: ${df.format(prescription.createdAt)}'),
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
              columnWidths: {0: const pw.FlexColumnWidth(3.2), 1: const pw.FlexColumnWidth(1.3), 2: const pw.FlexColumnWidth(2.2), 3: const pw.FlexColumnWidth(1.5)},
            );
          }
          doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(32), build: (_) => [header(), pw.SizedBox(height: 16), table()]));
          try {
            final bytes = await doc.save();
            await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'prescription_${widget.patient.uid}.pdf');
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
            );
          }
        }
        Navigator.pop(context, true);
        break;
      case 'add_more':
        setState(() {
          _draftItems.clear();
          _resetForNext();
        });
        break;
      default:
        Navigator.pop(context, true);
    }
  }

  Future<void> _saveAll() async {
    final patient = widget.patient;
    final existing = widget.medicine;
    final appendToId = widget.appendToPrescriptionId;

    setState(() => _saving = true);
    try {
      if (existing != null) {
        if (!_formKey.currentState!.validate()) return;
        final times = _savedTimes;
        final updated = Medicine(
          id: existing.id,
          userId: patient.uid,
          name: _nameController.text.trim(),
          dosage: Medicine.buildDosageText(
            int.parse(_dosageController.text.trim()),
            _dosageUnit,
          ),
          dosageValue: int.parse(_dosageController.text.trim()),
          dosageUnit: _dosageUnit,
          time: times.first,
          times: times.length > 1 ? times : null,
          frequency: _frequency,
          createdAt: existing.createdAt,
          prescriptionId: existing.prescriptionId,
          isInsulin: _isInsulin,
          insulinType: _isInsulin ? _insulinType : null,
          adjustmentInstructions: _isInsulin && _adjustmentInstructionsController.text.trim().isNotEmpty
              ? _adjustmentInstructionsController.text.trim()
              : null,
          mealOffsetMinutes: _mealOffsetMinutes,
        );
        await _medicineService.updateMedicine(updated);
      } else {
        // Add mode: save multiple medicines if the doctor used the + list builder.
        final items = <_PrescriptionDraftItem>[..._draftItems];
        if (_hasAnyInput) {
          // If something is typed in the form, include it too (validated).
          if (!_formKey.currentState!.validate()) return;
          items.add(_buildDraftFromForm());
        }
        if (items.isEmpty) {
          throw Exception('Add at least one medicine');
        }
        final now = DateTime.now();
        final medicines = <Medicine>[];
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          final times = item.times;
          medicines.add(Medicine(
            id: '${patient.uid}_med_${now.millisecondsSinceEpoch}_$i',
            userId: patient.uid,
            name: item.name,
            dosage: item.dosage,
            dosageValue: item.dosageValue,
            dosageUnit: item.dosageUnit,
            time: times.first,
            times: times.length > 1 ? times : null,
            frequency: item.frequency,
            createdAt: now,
            isInsulin: item.isInsulin,
            insulinType: item.insulinType,
            adjustmentInstructions: item.adjustmentInstructions,
            mealOffsetMinutes: item.mealOffsetMinutes,
          ));
        }

        if (appendToId != null && appendToId.isNotEmpty) {
          await _medicineService.addMedicinesToPrescription(
            patientId: patient.uid,
            prescriptionId: appendToId,
            medicines: medicines,
          );
        } else {
          final me = FirebaseAuth.instance.currentUser;
          final doctorId = me?.uid;
          final doctorName = (me?.displayName != null && me!.displayName!.trim().isNotEmpty)
              ? me.displayName!.trim()
              : (me?.email ?? '').trim();
          final prescription = await _medicineService.addPrescriptionWithMedicines(
            patient.uid,
            medicines,
            issuedByUid: doctorId,
            issuedByName: doctorName,
          );
          if (mounted && prescription != null) {
            // In-app notification for the patient.
            if (doctorId != null && doctorId.isNotEmpty) {
              try {
                await _notificationService.createPrescriptionNotification(
                  patientId: patient.uid,
                  doctorId: doctorId,
                  prescriptionId: prescription.id,
                  doctorName: doctorName,
                  medicineCount: medicines.length,
                );
              } catch (_) {}
            }
            await _showAfterSaveDialog(prescription, savedCount: medicines.length);
            return;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing != null
                ? 'Prescription updated'
                : 'Prescription saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicine != null;
    final isAppending = !isEdit && widget.appendToPrescriptionId != null && widget.appendToPrescriptionId!.isNotEmpty;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit prescription' : (isAppending ? 'Add medicine' : 'Add prescription')),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Generate PDF',
            onPressed: _saving ? null : _generatePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          if (isEdit)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) async {
                if (v == 'delete_medicine') {
                  await _confirmDelete(widget.medicine!);
                } else if (v == 'delete_prescription') {
                  final pid = widget.medicine!.prescriptionId;
                  if (pid == null || pid.isEmpty) return;
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete prescription?'),
                      content: const Text('This will delete the whole prescription (all medicines in this group).'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  setState(() => _saving = true);
                  try {
                    await _medicineService.deletePrescription(
                      prescriptionId: pid,
                      patientId: widget.patient.uid,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prescription deleted'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'delete_medicine', child: Text('Delete medicine')),
                PopupMenuItem(value: 'delete_prescription', child: Text('Delete prescription')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          TextButton(
            onPressed: _saving ? null : _saveAll,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving
            ? null
            : (isEdit ? _openAppendToSamePrescription : _addCurrentToList),
        tooltip: isEdit ? 'Add medicine' : 'Add to list',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'For ${widget.patient.displayName.isEmpty ? "patient" : widget.patient.displayName}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 20),
              if (!isEdit && _draftItems.isNotEmpty) ...[
                Text(
                  'Prescription medicines (${_draftItems.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._draftItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final timesLabel = item.times.map(Medicine.timeDisplayLabel).join(' / ');
                  final offsetNote = item.hasMealRelative ? ' · ${item.mealOffsetMinutes} min vs meal' : '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.medication_outlined),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${item.dosage} · $timesLabel$offsetNote · ${item.frequency.replaceAll('_', ' ')}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.close),
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _draftItems.removeAt(idx);
                                }),
                      ),
                    ),
                  );
                }),
                const Divider(height: 32),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine name',
                  hintText: 'Type at least 2 letters for suggestions',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              if (_loadingMedicineSuggestions || _medicineSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: AppTheme.cardTintMintColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: _loadingMedicineSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Loading medicine suggestions...'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _medicineSuggestions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppTheme.borderColor(context),
                          ),
                          itemBuilder: (context, index) {
                            final suggestion = _medicineSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.medication_outlined),
                              title: Text(suggestion),
                              onTap: () => _applyMedicineSuggestion(suggestion),
                            );
                          },
                        ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dosage amount',
                  hintText: 'Enter an integer (e.g. 1, 2, 10)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) {
                    return 'Enter a valid positive integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _dosageUnit,
                decoration: const InputDecoration(
                  labelText: 'Dosage unit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                items: dosageUnits
                    .map((u) => DropdownMenuItem<String>(
                          value: u,
                          child: Text(u),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _dosageUnit = v ?? 'tablet'),
              ),
              const SizedBox(height: 16),
              const Text('When to take', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _dosePicker(
                label: 'Dose 1',
                whenValue: _whenToTake1,
                onWhenChanged: (v) => setState(() => _whenToTake1 = v ?? 'specific'),
                timeText: _timeString(_time1),
                onPickTime: _pickTime,
              ),
              if (_frequency == 'twice_daily') ...[
                const SizedBox(height: 12),
                _dosePicker(
                  label: 'Dose 2',
                  whenValue: _whenToTake2,
                  onWhenChanged: (v) => setState(() => _whenToTake2 = v ?? 'specific'),
                  timeText: _timeString(_time2),
                  onPickTime: _pickTime2,
                ),
              ],
              if (_frequency == 'thrice_daily') ...[
                const SizedBox(height: 12),
                _dosePicker(
                  label: 'Dose 2',
                  whenValue: _whenToTake2,
                  onWhenChanged: (v) => setState(() => _whenToTake2 = v ?? 'specific'),
                  timeText: _timeString(_time2),
                  onPickTime: _pickTime2,
                ),
                const SizedBox(height: 12),
                _dosePicker(
                  label: 'Dose 3',
                  whenValue: _whenToTake3,
                  onWhenChanged: (v) => setState(() => _whenToTake3 = v ?? 'specific'),
                  timeText: _timeString(_time3),
                  onPickTime: _pickTime3,
                ),
              ],
              if (_anyMealRelative) ...[
                const SizedBox(height: 20),
                const Text(
                  'Minutes before / after meal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient reminders use their meal routine ± this value.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _mealOffsetMinutes,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  items: const [15, 30, 45, 60]
                      .map(
                        (v) => DropdownMenuItem<int>(
                          value: v,
                          child: Text('$v minutes'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _mealOffsetMinutes = v ?? 30),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _frequency,
                onChanged: (v) => setState(() => _frequency = v!),
                child: Column(
                  children: frequencies
                      .map((f) => RadioListTile<String>(
                            title: Text(f['label']!),
                            value: f['value']!,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Insulin adjustment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('This prescription is insulin'),
                subtitle: const Text('Add type and adjustment instructions'),
                value: _isInsulin,
                onChanged: (v) => setState(() => _isInsulin = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_isInsulin) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _insulinType,
                  decoration: const InputDecoration(
                    labelText: 'Insulin type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication_liquid),
                  ),
                  items: insulinTypes
                      .map((t) => DropdownMenuItem(value: t['value']!, child: Text(t['label']!)))
                      .toList(),
                  onChanged: (v) => setState(() => _insulinType = v ?? 'rapid_acting'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adjustmentInstructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment instructions',
                    hintText: 'e.g. Adjust by 1–2 units if fasting glucose > 140',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dosePicker({
    required String label,
    required String whenValue,
    required ValueChanged<String?> onWhenChanged,
    required String timeText,
    required VoidCallback onPickTime,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: whenValue,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.schedule),
          ),
          items: medicineTimeOptions
              .map((o) => DropdownMenuItem<String>(
                    value: o['value']!,
                    child: Text(o['label']!),
                  ))
              .toList(),
          onChanged: onWhenChanged,
        ),
        if (whenValue == 'specific') ...[
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Time'),
            subtitle: Text(timeText),
            trailing: const Icon(Icons.access_time),
            onTap: onPickTime,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: AppTheme.surfaceAltColor(context),
          ),
        ],
      ],
    );
  }
}

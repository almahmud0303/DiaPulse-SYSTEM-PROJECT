import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Doctor: add or edit a prescription (medicine) for a patient.
class DoctorAddEditPrescriptionPage extends StatefulWidget {
  const DoctorAddEditPrescriptionPage({super.key, required this.patient, this.medicine});

  final AppUser patient;
  final Medicine? medicine;

  @override
  State<DoctorAddEditPrescriptionPage> createState() => _DoctorAddEditPrescriptionPageState();
}

class _DoctorAddEditPrescriptionPageState extends State<DoctorAddEditPrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _adjustmentInstructionsController = TextEditingController();
  final MedicineService _medicineService = MedicineService();

  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _frequency = 'daily';
  bool _isInsulin = false;
  String _insulinType = 'rapid_acting';
  bool _saving = false;

  static const List<Map<String, String>> frequencies = [
    {'value': 'daily', 'label': 'Once daily'},
    {'value': 'twice_daily', 'label': 'Twice daily'},
    {'value': 'weekly', 'label': 'Weekly'},
  ];

  static const List<Map<String, String>> insulinTypes = [
    {'value': 'rapid_acting', 'label': 'Rapid-acting'},
    {'value': 'short_acting', 'label': 'Short-acting'},
    {'value': 'intermediate_acting', 'label': 'Intermediate-acting'},
    {'value': 'long_acting', 'label': 'Long-acting'},
    {'value': 'mixed', 'label': 'Mixed'},
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    if (m != null) {
      _nameController.text = m.name;
      _dosageController.text = m.dosage;
      final parts = m.time.split(':');
      if (parts.length >= 2) {
        _time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      _frequency = m.frequency;
      _isInsulin = m.isInsulin;
      _insulinType = m.insulinType ?? 'rapid_acting';
      _adjustmentInstructionsController.text = m.adjustmentInstructions ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _adjustmentInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String get _timeString =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final patient = widget.patient;
    final existing = widget.medicine;
    final doctor = FirebaseAuth.instance.currentUser;
    final doctorUid = doctor?.uid;
    final doctorName =
        (doctor?.displayName?.trim().isNotEmpty ?? false) ? doctor!.displayName!.trim() : (doctor?.email ?? '');

    setState(() => _saving = true);
    try {
      if (existing != null) {
        final updated = Medicine(
          id: existing.id,
          userId: patient.uid,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          time: _timeString,
          frequency: _frequency,
          createdAt: existing.createdAt,
          prescribedByUid: existing.prescribedByUid,
          prescribedByName: existing.prescribedByName,
          prescribedAt: existing.prescribedAt,
          isInsulin: _isInsulin,
          insulinType: _isInsulin ? _insulinType : null,
          adjustmentInstructions: _isInsulin && _adjustmentInstructionsController.text.trim().isNotEmpty
              ? _adjustmentInstructionsController.text.trim()
              : null,
        );
        await _medicineService.updateMedicine(updated);
      } else {
        final medicine = Medicine(
          id: '${patient.uid}_med_${DateTime.now().millisecondsSinceEpoch}',
          userId: patient.uid,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          time: _timeString,
          frequency: _frequency,
          createdAt: DateTime.now(),
          prescribedByUid: doctorUid,
          prescribedByName: doctorName.isEmpty ? null : doctorName,
          prescribedAt: DateTime.now(),
          isInsulin: _isInsulin,
          insulinType: _isInsulin ? _insulinType : null,
          adjustmentInstructions: _isInsulin && _adjustmentInstructionsController.text.trim().isNotEmpty
              ? _adjustmentInstructionsController.text.trim()
              : null,
        );
        await _medicineService.addMedicine(medicine);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing != null ? 'Prescription updated' : 'Prescription added'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit prescription' : 'Add prescription'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
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
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g. 5mg, 1 tablet',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(_timeString),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.grey.shade100,
              ),
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
}

import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddEditMedicinePage extends StatefulWidget {
  const AddEditMedicinePage({super.key, this.medicine});

  final Medicine? medicine;

  @override
  State<AddEditMedicinePage> createState() => _AddEditMedicinePageState();
}

class _AddEditMedicinePageState extends State<AddEditMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _medicineService = MedicineService();

  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _frequency = 'daily';
  bool _saving = false;

  static const List<Map<String, String>> frequencies = [
    {'value': 'daily', 'label': 'Once daily'},
    {'value': 'twice_daily', 'label': 'Twice daily'},
    {'value': 'weekly', 'label': 'Weekly'},
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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  String get _timeString =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      if (widget.medicine != null) {
        final updated = Medicine(
          id: widget.medicine!.id,
          userId: user.uid,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          time: _timeString,
          frequency: _frequency,
          createdAt: widget.medicine!.createdAt,
        );
        await _medicineService.updateMedicine(updated);
      } else {
        final medicine = Medicine(
          id: '${user.uid}_med_${DateTime.now().millisecondsSinceEpoch}',
          userId: user.uid,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          time: _timeString,
          frequency: _frequency,
          createdAt: DateTime.now(),
        );
        await _medicineService.addMedicine(medicine);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.medicine != null ? 'Updated' : 'Medicine added'), backgroundColor: Colors.green),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine != null ? 'Edit Medicine' : 'Add Medicine'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
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
              ...frequencies.map((f) {
                return RadioListTile<String>(
                  title: Text(f['label']!),
                  value: f['value']!,
                  groupValue: _frequency,
                  onChanged: (v) => setState(() => _frequency = v!),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

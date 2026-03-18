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

  String _whenToTake1 = 'specific';
  TimeOfDay _time1 = const TimeOfDay(hour: 9, minute: 0);
  String _whenToTake2 = 'specific';
  TimeOfDay _time2 = const TimeOfDay(hour: 19, minute: 0);
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
      _frequency = m.frequency;
      final times = m.effectiveTimes;
      _applyTimeToState(isSecond: false, value: times.isNotEmpty ? times.first : m.time);
      if (times.length > 1) {
        _applyTimeToState(isSecond: true, value: times[1]);
      }
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
      initialTime: _time1,
    );
    if (picked != null) setState(() => _time1 = picked);
  }

  Future<void> _pickTime2() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time2,
    );
    if (picked != null) setState(() => _time2 = picked);
  }

  void _applyTimeToState({required bool isSecond, required String value}) {
    if (Medicine.isMealRelativeTime(value)) {
      if (isSecond) {
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
    if (isSecond) {
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

  List<String> get _savedTimes {
    if (_frequency == 'twice_daily') return [_savedTime1, _savedTime2];
    return [_savedTime1];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      if (widget.medicine != null) {
        final times = _savedTimes;
        final updated = Medicine(
          id: widget.medicine!.id,
          userId: user.uid,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          time: times.first,
          times: times.length > 1 ? times : null,
          frequency: _frequency,
          createdAt: widget.medicine!.createdAt,
        );
        await _medicineService.updateMedicine(updated);
      } else {
        final times = _savedTimes;
        final medicine = Medicine(
          id: '${user.uid}_med_${DateTime.now().millisecondsSinceEpoch}',
          userId: user.uid,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          time: times.first,
          times: times.length > 1 ? times : null,
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
              const SizedBox(height: 16),
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _frequency,
                onChanged: (v) => setState(() => _frequency = v!),
                child: Column(
                  children: frequencies.map((f) {
                    return RadioListTile<String>(
                      title: Text(f['label']!),
                      value: f['value']!,
                    );
                  }).toList(),
                ),
              ),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: whenValue,
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
            tileColor: Colors.grey.shade100,
          ),
        ],
      ],
    );
  }
}

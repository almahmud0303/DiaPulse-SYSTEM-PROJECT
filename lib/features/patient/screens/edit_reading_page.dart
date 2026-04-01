// ignore_for_file: use_build_context_synchronously

import 'package:dia_plus/features/patient/screens/emergency_alert_details_page.dart';
import 'package:dia_plus/models/emergency_alert.dart';
import 'package:dia_plus/models/emergency_alert_type.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/services/emergency_alert_service.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Edit an existing glucose reading.
class EditReadingPage extends StatefulWidget {
  const EditReadingPage({super.key, required this.reading});

  final GlucoseReading reading;

  @override
  State<EditReadingPage> createState() => _EditReadingPageState();
}

class _EditReadingPageState extends State<EditReadingPage> {
  final _readingService = GlucoseReadingService();
  final _emergencyAlertService = EmergencyAlertService();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late double _glucoseLevel;
  late String _selectedMealTime;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _mealTimes = [
    {
      'label': 'Fasting',
      'icon': Icons.wb_sunny_outlined,
      'color': Colors.orange,
    },
    {
      'label': 'Before meal',
      'icon': Icons.restaurant_outlined,
      'color': Colors.amber,
    },
    {'label': 'After meal', 'icon': Icons.restaurant, 'color': Colors.teal},
    {
      'label': 'Bedtime',
      'icon': Icons.nightlight_round,
      'color': Colors.indigo,
    },
    {
      'label': 'Post Breakfast',
      'icon': Icons.free_breakfast,
      'color': Colors.amber,
    },
    {
      'label': 'Pre Lunch',
      'icon': Icons.lunch_dining_outlined,
      'color': Colors.green,
    },
    {'label': 'Post Lunch', 'icon': Icons.restaurant, 'color': Colors.teal},
    {
      'label': 'Pre Dinner',
      'icon': Icons.dinner_dining_outlined,
      'color': Colors.indigo,
    },
    {
      'label': 'Post Dinner',
      'icon': Icons.restaurant_menu,
      'color': Colors.purple,
    },
    {'label': 'Random', 'icon': Icons.shuffle, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.reading;
    _selectedDate = r.date;
    _glucoseLevel = r.glucoseLevel;
    _selectedMealTime = r.mealTime;
    _notesController.text = r.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Color _colorForLevel(double level) {
    if (level < 70) return Colors.blue;
    if (level <= 140) return Colors.green;
    if (level <= 200) return Colors.orange;
    return Colors.red;
  }

  Future<void> _save() async {
    if (_selectedMealTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reading type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = widget.reading.copyWith(
        date: _selectedDate,
        glucoseLevel: _glucoseLevel,
        mealTime: _selectedMealTime,
        notes: _notesController.text.trim(),
      );
      await _readingService.updateReading(updated);

      final emergencyAlert = await _emergencyAlertService
          .checkReadingForEmergency(updated);

      if (mounted) {
        if (emergencyAlert != null) {
          await _showEmergencyAlertDialog(emergencyAlert);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reading updated'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showEmergencyAlertDialog(EmergencyAlert alert) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          title: Text(alert.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${alert.glucoseValue.toStringAsFixed(0)} mg/dL • ${alert.alertType.label}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(alert.message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Dismiss'),
            ),
            OutlinedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EmergencyAlertDetailsPage(
                      alert: alert,
                      onAcknowledge: (current) async {
                        await _emergencyAlertService.markAlertAcknowledged(
                          current.id,
                        );
                      },
                      onNotifyDoctor: (current) async {
                        await _emergencyAlertService.notifyDoctorSimulation(
                          current,
                        );
                      },
                      onNotifyEmergencyContact: (current) async {
                        await _emergencyAlertService
                            .notifyEmergencyContactSimulation(current);
                      },
                    ),
                  ),
                );
              },
              child: const Text('View Details'),
            ),
            FilledButton(
              onPressed: () async {
                await _emergencyAlertService.markAlertAcknowledged(alert.id);
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Acknowledge'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Reading'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateTile(),
            const SizedBox(height: 20),
            _buildGlucoseTile(),
            const SizedBox(height: 20),
            _buildMealTimeChips(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile() {
    return ListTile(
      title: const Text('Date & time'),
      subtitle: Text(DateFormat('MMM d, y • h:mm a').format(_selectedDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: _selectDate,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.white,
    );
  }

  Widget _buildGlucoseTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _colorForLevel(_glucoseLevel).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            _glucoseLevel.toInt().toString(),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: _colorForLevel(_glucoseLevel),
            ),
          ),
          const Text(
            'mg/dL',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Slider(
            value: _glucoseLevel,
            min: 40,
            max: 400,
            divisions: 360,
            activeColor: _colorForLevel(_glucoseLevel),
            onChanged: (v) => setState(() => _glucoseLevel = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _mealTimes.map((m) {
        final label = m['label'] as String;
        final isSelected = _selectedMealTime == label;
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedMealTime = label),
        );
      }).toList(),
    );
  }
}

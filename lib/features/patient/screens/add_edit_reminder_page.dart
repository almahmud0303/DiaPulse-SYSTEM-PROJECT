import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/models/reminder_repeat_mode.dart';
import 'package:dia_plus/models/reminder_type.dart';
import 'package:dia_plus/services/reminder_service.dart';
import 'package:dia_plus/features/patient/widgets/repeat_selector.dart';
import 'package:dia_plus/features/patient/widgets/weekday_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEditReminderPage extends StatefulWidget {
  const AddEditReminderPage({super.key, this.reminder});

  final Reminder? reminder;

  bool get isEditMode => reminder != null;

  @override
  State<AddEditReminderPage> createState() => _AddEditReminderPageState();
}

class _AddEditReminderPageState extends State<AddEditReminderPage> {
  final ReminderService _reminderService = ReminderService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  ReminderType _type = ReminderType.medicine;
  ReminderRepeatMode _repeatMode = ReminderRepeatMode.once;
  DateTime _date = DateTime.now().add(const Duration(minutes: 5));
  TimeOfDay _time = TimeOfDay.now();
  List<int> _selectedWeekdays = <int>[];
  bool _isEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.reminder;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _type = existing.reminderType;
      _repeatMode = existing.repeatMode;
      _date = existing.date;
      _time = TimeOfDay.fromDateTime(existing.time);
      _selectedWeekdays = List<int>.from(existing.selectedWeekdays);
      _isEnabled = existing.isEnabled;
    } else {
      final now = DateTime.now().add(const Duration(minutes: 5));
      _date = now;
      _time = TimeOfDay(hour: now.hour, minute: now.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null && mounted) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);

    if (picked != null && mounted) {
      setState(() {
        _time = picked;
      });
    }
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
        _selectedWeekdays.sort();
      }
    });
  }

  DateTime _composeScheduledDateTime() {
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
  }

  Future<void> _saveReminder() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_repeatMode == ReminderRepeatMode.selectedWeekdays &&
        _selectedWeekdays.isEmpty) {
      _showError('Please select at least one weekday.');
      return;
    }

    final scheduledDateTime = _composeScheduledDateTime();
    if (_repeatMode == ReminderRepeatMode.once &&
        !scheduledDateTime.isAfter(DateTime.now())) {
      _showError('One-time reminders must be scheduled in the future.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _reminderService.initialize();
      await _reminderService.requestNotificationPermissions();

      final existing = widget.reminder;
      final reminder = Reminder(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        reminderType: _type,
        date: DateTime(_date.year, _date.month, _date.day),
        time: DateTime(1970, 1, 1, _time.hour, _time.minute),
        repeatMode: _repeatMode,
        selectedWeekdays: _repeatMode == ReminderRepeatMode.selectedWeekdays
            ? List<int>.from(_selectedWeekdays)
            : const <int>[],
        isEnabled: _isEnabled,
        createdAt: existing?.createdAt ?? DateTime.now(),
        relatedEntityId: existing?.relatedEntityId,
        notificationIds: existing?.notificationIds ?? const <int>[],
      );

      if (widget.isEditMode) {
        await _reminderService.updateReminder(reminder);
      } else {
        await _reminderService.saveReminder(reminder);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Reminder updated successfully.'
                : 'Reminder saved successfully.',
          ),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Failed to save reminder: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _typeDescription(ReminderType type) {
    switch (type) {
      case ReminderType.medicine:
        return 'Medication timing and dosage reminders.';
      case ReminderType.glucoseTest:
        return 'Blood glucose check reminders.';
      case ReminderType.exercise:
        return 'Physical activity reminders.';
      case ReminderType.appointment:
        return 'Doctor consultation or follow-up reminders.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showWeekdaySelector =
        _repeatMode == ReminderRepeatMode.selectedWeekdays;
    final showDatePicker = _repeatMode != ReminderRepeatMode.selectedWeekdays;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Reminder' : 'Add Reminder'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<ReminderType>(
              initialValue: _type,
              items: ReminderType.values
                  .map(
                    (type) => DropdownMenuItem<ReminderType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Reminder Type'),
            ),
            const SizedBox(height: 6),
            Text(
              _typeDescription(_type),
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            RepeatSelector(
              value: _repeatMode,
              onChanged: (value) {
                setState(() {
                  _repeatMode = value;
                  if (value != ReminderRepeatMode.selectedWeekdays) {
                    _selectedWeekdays = <int>[];
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            if (showDatePicker)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('EEE, MMM d, yyyy').format(_date)),
                  onTap: _pickDate,
                ),
              ),
            if (showDatePicker) const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time_outlined),
                title: const Text('Time'),
                subtitle: Text(_time.format(context)),
                onTap: _pickTime,
              ),
            ),
            if (showWeekdaySelector) ...[
              const SizedBox(height: 14),
              const Text(
                'Choose weekdays',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              WeekdaySelector(
                selectedWeekdays: _selectedWeekdays,
                onToggle: _toggleWeekday,
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              subtitle: const Text('Only enabled reminders are scheduled.'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveReminder,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : (widget.isEditMode ? 'Update Reminder' : 'Save Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

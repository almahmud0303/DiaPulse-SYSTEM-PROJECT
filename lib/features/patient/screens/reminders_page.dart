import 'package:dia_plus/features/patient/screens/add_edit_reminder_page.dart';
import 'package:dia_plus/features/patient/widgets/reminder_empty_state.dart';
import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/models/reminder_repeat_mode.dart';
import 'package:dia_plus/models/reminder_type.dart';
import 'package:dia_plus/services/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final ReminderService _reminderService = ReminderService();

  bool _isLoading = true;
  List<Reminder> _reminders = const [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _reminderService.initialize();
      await _loadReminders();
    } catch (e) {
      _showError('Failed to initialize reminders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadReminders() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final reminders = await _reminderService.getAllReminders();
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load reminders: $e');
    }
  }

  Future<void> _openAddReminder() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddEditReminderPage()),
    );

    if (saved == true) {
      await _loadReminders();
    }
  }

  Future<void> _openEditReminder(Reminder reminder) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddEditReminderPage(reminder: reminder),
      ),
    );

    if (updated == true) {
      await _loadReminders();
    }
  }

  Future<void> _toggleReminder(Reminder reminder, bool enabled) async {
    try {
      await _reminderService.toggleReminder(reminder, enabled);
      await _loadReminders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Reminder enabled successfully.'
                : 'Reminder disabled successfully.',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      _showError('Failed to update reminder: $e');
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: Text('Are you sure you want to delete "${reminder.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _reminderService.deleteReminder(reminder);
      await _loadReminders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted.'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      _showError('Failed to delete reminder: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _repeatLabel(Reminder reminder) {
    switch (reminder.repeatMode) {
      case ReminderRepeatMode.once:
        return 'Once';
      case ReminderRepeatMode.daily:
        return 'Daily';
      case ReminderRepeatMode.weekly:
        return 'Weekly';
      case ReminderRepeatMode.selectedWeekdays:
        if (reminder.selectedWeekdays.isEmpty) {
          return 'Selected Weekdays';
        }
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final parts = reminder.selectedWeekdays
            .where((w) => w >= 1 && w <= 7)
            .map((w) => names[w - 1])
            .toList();
        return parts.join(', ');
    }
  }

  IconData _typeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.medicine:
        return Icons.medication_outlined;
      case ReminderType.glucoseTest:
        return Icons.bloodtype_outlined;
      case ReminderType.exercise:
        return Icons.directions_run;
      case ReminderType.appointment:
        return Icons.calendar_month_outlined;
    }
  }

  Color _typeColor(ReminderType type) {
    switch (type) {
      case ReminderType.medicine:
        return Colors.indigo;
      case ReminderType.glucoseTest:
        return Colors.deepOrange;
      case ReminderType.exercise:
        return Colors.green;
      case ReminderType.appointment:
        return Colors.purple;
    }
  }

  Widget _buildReminderCard(Reminder reminder) {
    final next = _reminderService.getNextTriggerTime(reminder);
    final nextLabel = next == null
        ? 'No upcoming trigger'
        : DateFormat('EEE, MMM d • hh:mm a').format(next);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _typeColor(reminder.reminderType).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _typeIcon(reminder.reminderType),
                    color: _typeColor(reminder.reminderType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reminder.reminderType.label,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nextLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _repeatLabel(reminder),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (reminder.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          reminder.description.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: reminder.isEnabled,
                  onChanged: (value) => _toggleReminder(reminder, value),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _openEditReminder(reminder),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteReminder(reminder),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Smart Reminders')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
          ? const ReminderEmptyState()
          : RefreshIndicator(
              onRefresh: _loadReminders,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 96),
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  return _buildReminderCard(_reminders[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddReminder,
        icon: const Icon(Icons.add_alert),
        label: const Text('Add Reminder'),
      ),
    );
  }
}

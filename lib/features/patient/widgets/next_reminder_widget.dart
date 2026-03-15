import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/models/reminder_repeat_mode.dart';
import 'package:dia_plus/models/reminder_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NextReminderWidget extends StatelessWidget {
  const NextReminderWidget({
    super.key,
    this.reminder,
    this.nextTrigger,
    this.title = 'Next Reminder',
  });

  final Reminder? reminder;
  final DateTime? nextTrigger;
  final String title;

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

  String _repeatText(Reminder reminder) {
    switch (reminder.repeatMode) {
      case ReminderRepeatMode.once:
        return 'One-time reminder';
      case ReminderRepeatMode.daily:
        return 'Repeats daily';
      case ReminderRepeatMode.weekly:
        return 'Repeats weekly';
      case ReminderRepeatMode.selectedWeekdays:
        return 'Repeats on selected weekdays';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = reminder;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: item == null
            ? const Text('No upcoming reminders')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _typeColor(
                            item.reminderType,
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _typeIcon(item.reminderType),
                          color: _typeColor(item.reminderType),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(item.reminderType.label),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (nextTrigger != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('EEE, MMM d • hh:mm a').format(nextTrigger!),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _repeatText(item),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
      ),
    );
  }
}

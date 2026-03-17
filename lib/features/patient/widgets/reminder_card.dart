import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/models/reminder_type.dart';
import 'package:flutter/material.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    this.nextTriggerLabel,
    this.repeatLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    this.onTap,
  });

  final Reminder reminder;
  final String? nextTriggerLabel;
  final String? repeatLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;

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

  @override
  Widget build(BuildContext context) {
    final accent = _typeColor(reminder.reminderType);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
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
                      color: accent.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIcon(reminder.reminderType),
                      color: accent,
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
                        if ((nextTriggerLabel ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            nextTriggerLabel!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                        if ((repeatLabel ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            repeatLabel!,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
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
                  Switch(value: reminder.isEnabled, onChanged: onToggle),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

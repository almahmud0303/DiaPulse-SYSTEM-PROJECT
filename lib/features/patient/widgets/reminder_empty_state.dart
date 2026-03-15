import 'package:flutter/material.dart';

class ReminderEmptyState extends StatelessWidget {
  const ReminderEmptyState({
    super.key,
    this.title = 'No reminders yet',
    this.message = 'Tap Add Reminder to create your first smart reminder.',
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 64),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add_alert_outlined),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

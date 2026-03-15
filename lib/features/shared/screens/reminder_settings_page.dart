import 'package:flutter/material.dart';

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  bool _allRemindersEnabled = true;
  bool _medicineEnabled = true;
  bool _glucoseEnabled = true;
  bool _exerciseEnabled = true;
  bool _appointmentEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('All Reminders'),
            value: _allRemindersEnabled,
            onChanged: (value) => setState(() => _allRemindersEnabled = value),
          ),
          const Divider(height: 0),
          SwitchListTile(
            title: const Text('Medicine Reminders'),
            value: _medicineEnabled,
            onChanged: (value) => setState(() => _medicineEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Glucose Reminders'),
            value: _glucoseEnabled,
            onChanged: (value) => setState(() => _glucoseEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Exercise Reminders'),
            value: _exerciseEnabled,
            onChanged: (value) => setState(() => _exerciseEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Appointment Reminders'),
            value: _appointmentEnabled,
            onChanged: (value) => setState(() => _appointmentEnabled = value),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification coming soon.'),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Send Test Notification'),
            ),
          ),
        ],
      ),
    );
  }
}

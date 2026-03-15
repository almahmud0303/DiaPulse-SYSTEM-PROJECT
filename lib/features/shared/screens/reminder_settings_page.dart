import 'package:dia_plus/models/reminder_settings.dart';
import 'package:dia_plus/services/reminder_service.dart';
import 'package:flutter/material.dart';

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  final _service = ReminderService();
  ReminderSettings _settings = const ReminderSettings();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    final s = await _service.getSettings();
    if (mounted)
      setState(() {
        _settings = s;
        _loading = false;
      });
  }

  Future<void> _update(ReminderSettings updated) async {
    setState(() {
      _settings = updated;
      _saving = true;
    });
    await _service.updateSettings(updated);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _sendTest() async {
    await _service.requestNotificationPermissions();
    await _service.sendTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test notification sent!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Master switch ─────────────────────────────────────
                _SectionHeader(title: 'Master Switch'),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications,
                    color: Colors.teal,
                  ),
                  title: const Text('All Reminders'),
                  subtitle: const Text(
                    'Enable or disable all reminder notifications',
                  ),
                  activeColor: Colors.teal,
                  value: _settings.allRemindersEnabled,
                  onChanged: (v) =>
                      _update(_settings.copyWith(allRemindersEnabled: v)),
                ),
                const Divider(height: 1),

                // ── Per-category ──────────────────────────────────────
                _SectionHeader(title: 'Reminder Categories'),
                SwitchListTile(
                  secondary: const Icon(Icons.medication, color: Colors.purple),
                  title: const Text('Medicine Reminders'),
                  activeColor: Colors.teal,
                  value: _settings.medicineRemindersEnabled,
                  onChanged: _settings.allRemindersEnabled
                      ? (v) => _update(
                          _settings.copyWith(medicineRemindersEnabled: v),
                        )
                      : null,
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.water_drop,
                    color: Colors.lightBlue,
                  ),
                  title: const Text('Glucose Test Reminders'),
                  activeColor: Colors.teal,
                  value: _settings.glucoseRemindersEnabled,
                  onChanged: _settings.allRemindersEnabled
                      ? (v) => _update(
                          _settings.copyWith(glucoseRemindersEnabled: v),
                        )
                      : null,
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.fitness_center,
                    color: Colors.green,
                  ),
                  title: const Text('Exercise Reminders'),
                  activeColor: Colors.teal,
                  value: _settings.exerciseRemindersEnabled,
                  onChanged: _settings.allRemindersEnabled
                      ? (v) => _update(
                          _settings.copyWith(exerciseRemindersEnabled: v),
                        )
                      : null,
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.calendar_today,
                    color: Colors.orange,
                  ),
                  title: const Text('Appointment Reminders'),
                  activeColor: Colors.teal,
                  value: _settings.appointmentRemindersEnabled,
                  onChanged: _settings.allRemindersEnabled
                      ? (v) => _update(
                          _settings.copyWith(appointmentRemindersEnabled: v),
                        )
                      : null,
                ),
                const Divider(height: 1),

                // ── Notification style ────────────────────────────────
                _SectionHeader(title: 'Notification Style'),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up, color: Colors.teal),
                  title: const Text('Sound'),
                  activeColor: Colors.teal,
                  value: _settings.soundEnabled,
                  onChanged: (v) =>
                      _update(_settings.copyWith(soundEnabled: v)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration, color: Colors.teal),
                  title: const Text('Vibration'),
                  activeColor: Colors.teal,
                  value: _settings.vibrationEnabled,
                  onChanged: (v) =>
                      _update(_settings.copyWith(vibrationEnabled: v)),
                ),
                const Divider(height: 1),

                // ── Test ──────────────────────────────────────────────
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.icon(
                    onPressed: _sendTest,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Send Test Notification'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

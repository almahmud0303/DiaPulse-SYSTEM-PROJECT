import 'package:dia_plus/models/reminder_settings.dart';
import 'package:dia_plus/services/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    if (mounted) {
      setState(() {
        _settings = s;
        _loading = false;
      });
    }
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

  Future<void> _showDiagnostics() async {
    await _service.initialize();
    final report = await _service.buildSchedulingDiagnosticsReport();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reminder Diagnostics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      report,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: report));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Diagnostics copied to clipboard.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                  activeThumbColor: Colors.teal,
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
                  activeThumbColor: Colors.teal,
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
                  activeThumbColor: Colors.teal,
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
                  activeThumbColor: Colors.teal,
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
                  activeThumbColor: Colors.teal,
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
                  activeThumbColor: Colors.teal,
                  value: _settings.soundEnabled,
                  onChanged: (v) =>
                      _update(_settings.copyWith(soundEnabled: v)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration, color: Colors.teal),
                  title: const Text('Vibration'),
                  activeThumbColor: Colors.teal,
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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _showDiagnostics,
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('View Scheduling Diagnostics'),
                    style: OutlinedButton.styleFrom(
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

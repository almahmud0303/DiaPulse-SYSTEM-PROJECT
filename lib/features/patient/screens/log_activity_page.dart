import 'package:dia_plus/models/activity.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/app_config_item.dart';
import 'package:dia_plus/services/activity_service.dart';
import 'package:dia_plus/services/config_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogActivityPage extends StatefulWidget {
  const LogActivityPage({super.key});

  @override
  State<LogActivityPage> createState() => _LogActivityPageState();
}

class _LogActivityPageState extends State<LogActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  final _activityService = ActivityService();
  final _configService = ConfigService();

  DateTime _date = DateTime.now();
  String _type = '';
  bool _saving = false;

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No activity types available. Ask admin to add one.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final calories = double.tryParse(_caloriesController.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      final activity = Activity(
        id: '${user.uid}_activity_${_dateStr}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        date: _dateStr,
        type: _type,
        durationMinutes: duration,
        calories: calories,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );
      await _activityService.addActivity(activity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity logged'),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Log Activity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            const Text(
              'Exercise type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<AppConfigItem>>(
              stream: _configService.getActivityTypes(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (snap.hasError) {
                  return const Text(
                    'Could not load activity types from admin configuration.',
                    style: TextStyle(color: Colors.red),
                  );
                }

                final items = snap.data ?? const <AppConfigItem>[];
                if (items.isEmpty) {
                  if (_type.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _type = '');
                    });
                  }
                  return Text(
                    'No activity types available. Please contact admin.',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  );
                }

                final values = items.map((t) => t.name.toLowerCase()).toSet();
                if (_type.isEmpty || !values.contains(_type)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final first = items.first.name.toLowerCase();
                    if (_type != first) setState(() => _type = first);
                  });
                }

                return Wrap(
                  spacing: 8,
                  children: items.map((t) {
                    final value = t.name.toLowerCase();
                    final selected = _type == value;
                    return ChoiceChip(
                      label: Text(t.name),
                      selected: selected,
                      onSelected: (_) => setState(() => _type = value),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'e.g. 30',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter duration';
                if (int.tryParse(v.trim()) == null) return 'Enter a number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories (optional)',
                hintText: 'e.g. 150',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Morning jog in the park',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Activity'),
            ),
          ],
        ),
      ),
    );
  }
}

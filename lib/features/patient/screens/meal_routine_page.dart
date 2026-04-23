import 'package:dia_plus/models/meal_routine.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/services/meal_routine_service.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:dia_plus/services/reminder_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Patient sets usual breakfast / lunch / dinner / snack times so meal-linked
/// medicines can schedule reminders (meal ± offset from prescription).
class MealRoutinePage extends StatefulWidget {
  const MealRoutinePage({super.key});

  @override
  State<MealRoutinePage> createState() => _MealRoutinePageState();
}

class _MealRoutinePageState extends State<MealRoutinePage> {
  final _service = MealRoutineService();
  final _medicineService = MedicineService();

  TimeOfDay _breakfast = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunch = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinner = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _snack = const TimeOfDay(hour: 15, minute: 30);

  bool _loading = true;
  bool _saving = false;

  static String _hm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _parseHm(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await _service.getRoutine(user.uid);
      if (r != null) {
        _breakfast = _parseHm(r.breakfast) ?? _breakfast;
        _lunch = _parseHm(r.lunch) ?? _lunch;
        _dinner = _parseHm(r.dinner) ?? _dinner;
        _snack = _parseHm(r.snack) ?? _snack;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final routine = MealRoutine(
        breakfast: _hm(_breakfast),
        lunch: _hm(_lunch),
        dinner: _hm(_dinner),
        snack: _hm(_snack),
      );
      await _service.saveRoutine(user.uid, routine);
      try {
        final meds = await _medicineService.getMedicines(user.uid);
        await ReminderNotificationService().scheduleMedicineReminders(
          meds,
          mealRoutine: routine,
        );
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal routine saved. Medicine reminders updated.'),
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

  Widget _row(String label, TimeOfDay t, Future<void> Function() onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor(context),
        ),
      ),
      subtitle: Text(_hm(t)),
      trailing: Icon(
        Icons.schedule,
        color: AppTheme.textSecondaryColor(context),
      ),
      onTap: () => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: AppTheme.surfaceAltColor(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Meal routine'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'When do you usually eat? This is used with medicines timed '
            '"before breakfast", "after lunch", etc. Reminders are set at '
            'your meal time minus or plus the minutes your doctor prescribed.',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _row(
            'Breakfast',
            _breakfast,
            () async {
              final picked = await showTimePicker(context: context, initialTime: _breakfast);
              if (picked != null) setState(() => _breakfast = picked);
            },
          ),
          const SizedBox(height: 12),
          _row(
            'Lunch',
            _lunch,
            () async {
              final picked = await showTimePicker(context: context, initialTime: _lunch);
              if (picked != null) setState(() => _lunch = picked);
            },
          ),
          const SizedBox(height: 12),
          _row(
            'Dinner',
            _dinner,
            () async {
              final picked = await showTimePicker(context: context, initialTime: _dinner);
              if (picked != null) setState(() => _dinner = picked);
            },
          ),
          const SizedBox(height: 12),
          _row(
            'Snack (optional)',
            _snack,
            () async {
              final picked = await showTimePicker(context: context, initialTime: _snack);
              if (picked != null) setState(() => _snack = picked);
            },
          ),
        ],
      ),
    );
  }
}

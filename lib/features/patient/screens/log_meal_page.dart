import 'package:dia_plus/models/meal.dart';
import 'package:dia_plus/services/meal_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogMealPage extends StatefulWidget {
  const LogMealPage({super.key});

  @override
  State<LogMealPage> createState() => _LogMealPageState();
}

class _LogMealPageState extends State<LogMealPage> {
  final _formKey = GlobalKey<FormState>();
  final _carbsController = TextEditingController();
  final _notesController = TextEditingController();
  final _mealService = MealService();

  DateTime _date = DateTime.now();
  String _category = 'breakfast';
  bool _saving = false;

  static const List<Map<String, String>> categories = [
    {'value': 'breakfast', 'label': 'Breakfast'},
    {'value': 'lunch', 'label': 'Lunch'},
    {'value': 'dinner', 'label': 'Dinner'},
    {'value': 'snack', 'label': 'Snack'},
  ];

  @override
  void dispose() {
    _carbsController.dispose();
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      final meal = Meal(
        id: '${user.uid}_meal_${_dateStr}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        date: _dateStr,
        category: _category,
        carbs: carbs,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );
      await _mealService.addMeal(meal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal logged'),
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
      appBar: AppBar(
        title: const Text('Log Meal'),
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
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categories.map((c) {
                final selected = _category == c['value'];
                return ChoiceChip(
                  label: Text(c['label']!),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c['value']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _carbsController,
              decoration: const InputDecoration(
                labelText: 'Carbs (g)',
                hintText: 'e.g. 45',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter carbs';
                if (double.tryParse(v.trim()) == null) return 'Enter a number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. 1 slice bread, coffee',
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
                  : const Text('Save Meal'),
            ),
          ],
        ),
      ),
    );
  }
}

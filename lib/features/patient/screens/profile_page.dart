import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.user});

  final AppUser? user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _authService = AuthService();
  final _profileService = ProfileService();
  DateTime? _dateOfBirth;

  String _diabetesType = 'type2';
  bool _loading = true;
  bool _saving = false;

  static const List<Map<String, String>> diabetesTypes = [
    {'value': 'type1', 'label': 'Type 1'},
    {'value': 'type2', 'label': 'Type 2'},
    {'value': 'gestational', 'label': 'Gestational'},
    {'value': 'prediabetes', 'label': 'Prediabetes'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _authService.getAppUser();
    if (user != null && mounted) {
      _nameController.text = user.displayName;
      _dateOfBirth = _parseDateOfBirth(user.extra['dateOfBirth']);
      _weightController.text = user.extra['weight']?.toString() ?? '';
      _heightController.text = user.extra['height']?.toString() ?? '';
      final dt = user.extra['diabetesType'];
      if (dt is String && diabetesTypes.any((t) => t['value'] == dt)) {
        _diabetesType = dt;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  DateTime? _parseDateOfBirth(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 30, 1, 1);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected == null) return;
    setState(() => _dateOfBirth = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final birthYear = _dateOfBirth?.year;
      int? age;
      if (birthYear != null) {
        final computedAge = DateTime.now().year - birthYear;
        if (computedAge > 0 && computedAge < 130) {
          age = computedAge;
        }
      }
      final weight = double.tryParse(_weightController.text.trim());
      final height = double.tryParse(_heightController.text.trim());

      await _profileService.updatePatientProfile(user.uid,
        displayName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        birthYear: birthYear,
        age: age,
        weight: weight,
        height: height,
        diabetesType: _diabetesType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved'), backgroundColor: Colors.green),
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateOfBirth,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
              ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateOfBirth == null
                          ? 'Select date'
                          : DateFormat('MMMM d, yyyy').format(_dateOfBirth!),
                    ),
                    const Icon(Icons.calendar_month_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g. 70',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                hintText: 'e.g. 170',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text('Diabetes type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: diabetesTypes.map((t) {
                final selected = _diabetesType == t['value'];
                return ChoiceChip(
                  label: Text(t['label']!),
                  selected: selected,
                  onSelected: (_) => setState(() => _diabetesType = t['value']!),
                );
              }).toList(),
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
                  : const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/features/patient/screens/profile_page.dart';
import 'package:dia_plus/features/shared/screens/settings_page.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientProfileSectionPage extends StatefulWidget {
  const PatientProfileSectionPage({super.key, this.user});

  final AppUser? user;

  @override
  State<PatientProfileSectionPage> createState() => _PatientProfileSectionPageState();
}

class _PatientProfileSectionPageState extends State<PatientProfileSectionPage> {
  final _authService = AuthService();
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final latest = await _authService.getAppUser();
    if (!mounted) return;
    setState(() {
      _user = latest ?? widget.user;
      _loading = false;
    });
  }

  Future<void> _openEditor() async {
    final user = _user;
    if (user == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(user: user)),
    );
    await _loadUser();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsPage(user: _user ?? widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user ?? widget.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not available')));
    }

    final dateOfBirth = _extractDate(user.extra['dateOfBirth']);
    final weight = _extractDouble(user.extra['weight']);
    final height = _extractDouble(user.extra['height']);
    final diabetesType = _stringOrNA(user.extra['diabetesType']);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardTintMint,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppTheme.primaryMint,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName.isEmpty ? 'N/A' : user.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openEditor,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Name', _stringOrNA(user.displayName)),
                  _infoRow(
                    'Date of birth',
                    dateOfBirth == null
                        ? 'N/A'
                        : DateFormat('MMMM d, yyyy').format(dateOfBirth),
                  ),
                  _infoRow('Weight', weight == null ? 'N/A' : '${weight.toStringAsFixed(1)} kg'),
                  _infoRow('Height', height == null ? 'N/A' : '${height.toStringAsFixed(1)} cm'),
                  _infoRow('Diabetes type', diabetesType),
                  _infoRow('Phone', _stringOrNA(user.phone)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _extractDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double? _extractDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String _stringOrNA(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'N/A' : text;
  }
}

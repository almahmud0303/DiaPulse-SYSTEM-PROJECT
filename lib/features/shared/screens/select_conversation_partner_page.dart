import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

/// Pick a user to start a conversation (doctor picks patient, patient picks doctor).
class SelectConversationPartnerPage extends StatefulWidget {
  const SelectConversationPartnerPage({super.key});

  @override
  State<SelectConversationPartnerPage> createState() =>
      _SelectConversationPartnerPageState();
}

class _SelectConversationPartnerPageState
    extends State<SelectConversationPartnerPage> {
  final AuthService _authService = AuthService();
  final DoctorPatientService _userService = DoctorPatientService();

  AppUser? _currentUser;
  List<AppUser> _partners = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.getAppUser();
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Not signed in';
          _loading = false;
        });
        return;
      }
      final list = user.isDoctor
          ? await _userService.getPatients()
          : await _userService.getDoctors();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _partners = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentUser?.isDoctor == true
        ? 'Message a patient'
        : 'Message a doctor';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _partners.isEmpty
          ? Center(
              child: Text(
                _currentUser?.isDoctor == true
                    ? 'No patients yet'
                    : 'No doctors available',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
              itemCount: _partners.length,
              itemBuilder: (context, index) {
                final partner = _partners[index];
                final name = partner.displayName.isNotEmpty
                    ? partner.displayName
                    : partner.email;
                return Card(
                  color: AppTheme.cardTintMint,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppTheme.secondaryLavender.withValues(alpha: 0.25),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondaryLavender.withValues(
                        alpha: 0.35,
                      ),
                      child: Text(
                        partner.initials,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      partner.email,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () {
                      if (_currentUser != null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (context) => ChatPage(
                              currentUser: _currentUser!,
                              otherUser: partner,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

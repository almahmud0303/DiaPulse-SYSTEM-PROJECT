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
      backgroundColor: AppTheme.backgroundColor(context),
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
                      style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: Icon(Icons.refresh),
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
                style: TextStyle(color: AppTheme.textSecondaryColor(context)),
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
                  color: AppTheme.cardTintMintColor(context),
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
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      partner.email,
                      style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.textSecondaryColor(context),
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

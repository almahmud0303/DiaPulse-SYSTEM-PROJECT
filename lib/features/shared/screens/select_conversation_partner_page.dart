import 'package:dia_plus/models/app_user.dart';
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
    final title = _currentUser?.isDoctor == true ? 'Message a patient' : 'Message a doctor';
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
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
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _partners.length,
                      itemBuilder: (context, index) {
                        final partner = _partners[index];
                        final name = partner.displayName.isNotEmpty
                            ? partner.displayName
                            : partner.email;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(
                              partner.initials,
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(partner.email),
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
                        );
                      },
                    ),
    );
  }
}

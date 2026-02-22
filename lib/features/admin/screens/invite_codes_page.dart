import 'package:dia_plus/models/user_role.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/invite_code_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Admin screen to generate and view invite codes for Doctor and Admin registration.
class InviteCodesPage extends StatefulWidget {
  const InviteCodesPage({super.key});

  @override
  State<InviteCodesPage> createState() => _InviteCodesPageState();
}

class _InviteCodesPageState extends State<InviteCodesPage> {
  final _inviteCodeService = InviteCodeService();
  final _authService = AuthService();

  List<Map<String, dynamic>> _codes = [];
  bool _loading = true;
  String? _error;
  UserRole _generatingFor = UserRole.doctor;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _inviteCodeService.listCodes();
      if (mounted) {
        setState(() {
          _codes = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _generateCode() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    setState(() => _error = null);
    try {
      final code = await _inviteCodeService.createCode(
        role: _generatingFor,
        createdByUid: uid,
      );
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_generatingFor.displayName} code copied: $code',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      );
      await _loadCodes();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invite Codes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Generate invite codes for Doctor or Admin registration. '
              'Share the code with the person—they must enter it when registering.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<UserRole>(
                    segments: [
                      ButtonSegment(
                        value: UserRole.doctor,
                        label: const Text('Doctor'),
                        icon: const Icon(Icons.medical_services, size: 18),
                      ),
                      ButtonSegment(
                        value: UserRole.admin,
                        label: const Text('Admin'),
                        icon: const Icon(Icons.admin_panel_settings, size: 18),
                      ),
                    ],
                    selected: {_generatingFor},
                    onSelectionChanged: (s) =>
                        setState(() => _generatingFor = s.first),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _generateCode,
                  icon: const Icon(Icons.add),
                  label: const Text('Generate'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Recent Codes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_codes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No invite codes yet. Generate one above.'),
                  ),
                ),
              )
            else
              ..._codes.take(20).map(_buildCodeTile),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeTile(Map<String, dynamic> m) {
    final used = m['used'] == true;
    final role = UserRole.fromString(m['role'] as String?) ?? UserRole.patient;
    final code = m['id'] ?? m['code'] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          role == UserRole.doctor ? Icons.medical_services : Icons.admin_panel_settings,
          color: used ? Colors.grey : Colors.deepPurple,
        ),
        title: Text(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            decoration: used ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          used
              ? 'Used by ${m['usedByEmail'] ?? 'unknown'}'
              : '${role.displayName} • Unused',
          style: TextStyle(
            fontSize: 12,
            color: used ? Colors.grey : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy code',
              onPressed: () => _copyCode(code),
            ),
            if (used)
              const Icon(Icons.check_circle, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied: $code')),
      );
    }
  }
}

import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/models/user_role.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/invite_access_request_service.dart';
import 'package:flutter/material.dart';

/// After admin approves access: confirm main password and set second password.
class CompleteProfessionalRegistrationPage extends StatefulWidget {
  const CompleteProfessionalRegistrationPage({super.key});

  @override
  State<CompleteProfessionalRegistrationPage> createState() =>
      _CompleteProfessionalRegistrationPageState();
}

class _CompleteProfessionalRegistrationPageState
    extends State<CompleteProfessionalRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _mainPasswordController = TextEditingController();
  final _secondPasswordController = TextEditingController();
  final _confirmSecondController = TextEditingController();
  final _authService = AuthService();
  final _accessService = InviteAccessRequestService();

  bool _obscureMain = true;
  bool _obscureSecond = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final me = await _authService.getAppUser();
    if (me != null && me.blocked) {
      await _authService.signOut();
      if (!mounted) return;
      AppRouter.goToStart(context);
      return;
    }
    final role = me?.role ?? await _authService.getCurrentUserRole();
    if (!mounted) return;
    if (role == null || !role.requiresSecondPassword) {
      AppRouter.goToHome(context);
      return;
    }
    if (!(me?.needsProfessionalInviteCompletion ?? false)) {
      AppRouter.goToSecondPassword(context);
      return;
    }
    final uid = me?.uid;
    if (uid == null) {
      AppRouter.goToHome(context);
      return;
    }
    final latest = await _accessService.fetchLatestForUser(uid);
    if (!mounted) return;
    if (latest == null || !latest.isApproved) {
      AppRouter.goToProfessionalAccessRequest(context);
      return;
    }
    setState(() => _role = role);
  }

  @override
  void dispose() {
    _mainPasswordController.dispose();
    _secondPasswordController.dispose();
    _confirmSecondController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      await _authService.completeProfessionalRegistration(
        primaryPassword: _mainPasswordController.text,
        secondPassword: _secondPasswordController.text,
      );
      if (!mounted) return;
      AppRouter.goToHome(context);
    } on ArgumentError catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    AppRouter.goToStart(context);
  }

  @override
  Widget build(BuildContext context) {
    final roleName = _role?.displayName ?? 'Staff';
    if (_role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finish setup'),
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Complete $roleName setup',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account was approved by an administrator. Enter your main password to verify, '
                  'then choose a second password (different from the first).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _mainPasswordController,
                  obscureText: _obscureMain,
                  decoration: InputDecoration(
                    labelText: 'Main password (verify)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureMain ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureMain = !_obscureMain),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _secondPasswordController,
                  obscureText: _obscureSecond,
                  decoration: InputDecoration(
                    labelText: 'Second password',
                    hintText: 'Different from your main password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.security),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSecond
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureSecond = !_obscureSecond),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter second password';
                    if (v.length < 6) return 'At least 6 characters';
                    if (v == _mainPasswordController.text) {
                      return 'Must be different from main password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmSecondController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm second password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _secondPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue to app'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

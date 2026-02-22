import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/models/user_role.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:flutter/material.dart';

/// Screen for Doctor and Admin to enter their second password.
/// Shown after primary login for users with requiresSecondPassword role.
class SecondPasswordPage extends StatefulWidget {
  const SecondPasswordPage({super.key});

  @override
  State<SecondPasswordPage> createState() => _SecondPasswordPageState();
}

class _SecondPasswordPageState extends State<SecondPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _mainPasswordController = TextEditingController();
  final _secondPasswordController = TextEditingController();
  final _confirmSecondController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureMain = true;
  bool _obscureSecond = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _needsSetup = false;
  String? _errorMessage;
  UserRole? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final hasSecond = await _authService.hasSecondPassword();
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _needsSetup = !hasSecond && role != null && role.requiresSecondPassword;
        _role = role;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
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
      if (_needsSetup) {
        await _authService.setupSecondPassword(
          primaryPassword: _mainPasswordController.text,
          secondPassword: _secondPasswordController.text,
        );
        if (!mounted) return;
        AppRouter.goToHome(context);
      } else {
        final valid = await _authService.verifySecondPassword(
          _passwordController.text,
        );
        setState(() => _isLoading = false);
        if (!mounted) return;
        if (valid) {
          AppRouter.goToHome(context);
        } else {
          setState(() {
            _errorMessage = 'Incorrect second password';
          });
        }
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Password'),
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
                const SizedBox(height: 24),
                Icon(
                  Icons.security,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _needsSetup
                      ? 'Second Password Not Set'
                      : 'Enter Second Password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _needsSetup
                      ? 'Set up your $roleName second password below. Enter your main login password first, then choose a different second password.'
                      : 'Enter your $roleName second password to continue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_needsSetup) ...[
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
                      if (v == null || v.isEmpty) return 'Enter main password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _secondPasswordController,
                    obscureText: _obscureSecond,
                    decoration: InputDecoration(
                      labelText: 'Second password',
                      hintText: 'Must be different from main',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.security),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSecond ? Icons.visibility : Icons.visibility_off,
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
                          _obscureConfirm ? Icons.visibility : Icons.visibility_off,
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
                ],
                if (!_needsSetup)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Second Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter second password';
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
                if (_needsSetup) ...[
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
                        : const Text('Set Up Second Password'),
                  ),
                ],
                if (!_needsSetup) ...[
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
                        : const Text('Verify'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

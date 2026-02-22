import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/models/user_role.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondPasswordController = TextEditingController();
  final _confirmSecondPasswordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _authService = AuthService();

  UserRole _selectedRole = UserRole.patient;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscureSecond = true;
  bool _obscureConfirmSecond = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _secondPasswordController.dispose();
    _confirmSecondPasswordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      String? secondPassword;
      if (_selectedRole.requiresSecondPassword) {
        secondPassword = _secondPasswordController.text;
      }
      await _authService.registerWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        role: _selectedRole,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        secondPassword: secondPassword,
        inviteCode: _selectedRole.requiresSecondPassword
            ? _inviteCodeController.text.trim()
            : null,
      );
      await _authService.sendEmailVerification();
      if (!mounted) return;
      AppRouter.goToEmailVerification(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Registration failed';
      });
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

  @override
  Widget build(BuildContext context) {
    final requiresSecond = _selectedRole.requiresSecondPassword;
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Account Type',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<UserRole>(
                  segments: UserRole.values
                      .map((r) => ButtonSegment(
                            value: r,
                            label: Text(r.displayName),
                            icon: Icon(_iconForRole(r), size: 18),
                          ))
                      .toList(),
                  selected: {_selectedRole},
                  onSelectionChanged: (Set<UserRole> selected) {
                    setState(() {
                      _selectedRole = selected.first;
                      _secondPasswordController.clear();
                      _confirmSecondPasswordController.clear();
                      _inviteCodeController.clear();
                    });
                  },
                ),
                if (requiresSecond)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Doctors and Admins require an invite code and a second password.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                    ),
                  ),
                if (requiresSecond) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _inviteCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Invite Code',
                      hintText: 'Obtain from your administrator',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    validator: requiresSecond
                        ? (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Invite code required for ${_selectedRole.displayName}';
                            }
                            return null;
                          }
                        : null,
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                if (requiresSecond) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Second Password (must be different)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _secondPasswordController,
                    obscureText: _obscureSecond,
                    decoration: InputDecoration(
                      labelText: 'Second Password',
                      hintText: 'Different from your main password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.security),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSecond
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() =>
                              _obscureSecond = !_obscureSecond);
                        },
                      ),
                    ),
                    validator: requiresSecond
                        ? (v) {
                            if (v == null || v.isEmpty) return 'Required for ${_selectedRole.displayName}';
                            if (v.length < 6)
                              return 'At least 6 characters';
                            if (v == _passwordController.text)
                              return 'Must be different from main password';
                            return null;
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmSecondPasswordController,
                    obscureText: _obscureConfirmSecond,
                    decoration: InputDecoration(
                      labelText: 'Confirm Second Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmSecond
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmSecond =
                              !_obscureConfirmSecond);
                        },
                      ),
                    ),
                    validator: requiresSecond
                        ? (v) {
                            if (v != _secondPasswordController.text)
                              return 'Passwords do not match';
                            return null;
                          }
                        : null,
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _register,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForRole(UserRole r) {
    switch (r) {
      case UserRole.patient:
        return Icons.person;
      case UserRole.doctor:
        return Icons.medical_services;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }
}

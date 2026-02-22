import 'dart:async';

import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:flutter/material.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _authService = AuthService();
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _authService.currentUser?.reload();
      final user = _authService.currentUser;
      if (user?.emailVerified ?? false) {
        timer.cancel();
        if (!mounted) return;
        final role = await _authService.getCurrentUserRole();
        if (role != null && role.requiresSecondPassword) {
          AppRouter.goToSecondPassword(context);
        } else {
          AppRouter.goToHome(context);
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    _timer?.cancel();
    await _authService.signOut();
    if (!mounted) return;
    AppRouter.goToStart(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          TextButton(onPressed: _signOut, child: const Text('Sign Out')),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 100,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'ve sent a verification email to:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _authService.currentUser?.email ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Please check your inbox and click the verification link to continue.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Checking verification status...',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Didn\'t receive the email?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Verification Email'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

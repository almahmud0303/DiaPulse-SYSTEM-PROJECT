import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:flutter/material.dart';

/// First screen when user opens the app. Offers Login and Registration.
/// Redirects to home or second-password if already logged in.
class StartingPage extends StatefulWidget {
  const StartingPage({super.key});

  @override
  State<StartingPage> createState() => _StartingPageState();
}

class _StartingPageState extends State<StartingPage> {
  final _authService = AuthService();
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    final user = _authService.currentUser;
    if (user == null || !mounted) {
      if (mounted) setState(() => _checkingAuth = false);
      return;
    }
    if (!user.emailVerified) {
      if (mounted) setState(() => _checkingAuth = false);
      return;
    }
    final role = await _authService.getCurrentUserRole();
    if (!mounted) return;
    setState(() => _checkingAuth = false);
    if (role != null && role.requiresSecondPassword) {
      AppRouter.goToSecondPassword(context);
    } else {
      AppRouter.goToHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dia Plus',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome. Sign in or create an account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => AppRouter.pushLogin(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => AppRouter.pushRegister(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

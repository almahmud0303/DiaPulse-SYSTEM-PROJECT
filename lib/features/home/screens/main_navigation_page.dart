import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/features/admin/screens/admin_home_page.dart';
import 'package:dia_plus/features/doctor/screens/doctor_home_page.dart';
import 'package:dia_plus/features/patient/screens/patient_home_page.dart';
import 'package:dia_plus/features/shared/screens/settings_page.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main navigation with bottom bar. Content varies by user role.
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final _authService = AuthService();
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getAppUser();
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final existingName = prefs.getString('userName');
      if (existingName == null || existingName.isEmpty) {
        await prefs.setString('userName', user.displayName);
        if (user.initials.isNotEmpty) {
          await prefs.setString('userInitials', user.initials);
        }
      }
    }
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'Session expired. Please log in again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => AppRouter.goToStart(context),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final homePage = user.isPatient
        ? const PatientHomePage()
        : user.isDoctor
            ? const DoctorHomePage()
            : const AdminHomePage();

    final List<Widget> pages = [
      homePage,
      Center(
        child: Text(
          user.isPatient ? 'Readings' : 'Data',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const Center(child: Text('History - Coming Soon')),
      SettingsPage(user: user),
    ];

    return _NavScaffold(
      user: user,
      pages: pages,
    );
  }
}

class _NavScaffold extends StatefulWidget {
  const _NavScaffold({
    required this.user,
    required this.pages,
  });

  final AppUser user;
  final List<Widget> pages;

  @override
  State<_NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<_NavScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Readings'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

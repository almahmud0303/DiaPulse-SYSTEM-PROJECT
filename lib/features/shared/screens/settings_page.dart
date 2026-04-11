import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/features/shared/screens/emergency_settings_page.dart';
import 'package:dia_plus/features/shared/screens/reminder_settings_page.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.user});

  final AppUser? user;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  AppUser? _currentUser;

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final latestUser = await _authService.getAppUser();
    final user = latestUser ?? widget.user;
    setState(() {
      _currentUser = user;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('darkModeEnabled', _darkModeEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppTheme.primaryMint,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    AppRouter.goToStart(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser ?? widget.user;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                _buildSectionTitle('Account'),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(
                    Icons.badge,
                    color: AppTheme.textSecondary,
                  ),
                  title: Text('Role: ${user.role.displayName}'),
                  subtitle: Text(user.email),
                ),
                const SizedBox(height: 20),
              ],
              _buildSectionTitle('App Preferences'),
              const SizedBox(height: 15),
              _buildPreferencesCard(),
              const SizedBox(height: 30),
              _buildSectionTitle('About'),
              const SizedBox(height: 15),
              _buildAboutCard(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveSettings,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.softError,
                    side: const BorderSide(color: AppTheme.softError),
                  ),
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardTintLavender,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Receive health reminders'),
            value: _notificationsEnabled,
            activeThumbColor: AppTheme.primaryMint,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Coming soon'),
            value: _darkModeEnabled,
            activeThumbColor: AppTheme.primaryMint,
            onChanged: (value) => setState(() => _darkModeEnabled = value),
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.alarm, color: AppTheme.textSecondary),
            title: const Text('Reminder Settings'),
            subtitle: const Text('Manage smart reminders & notifications'),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderSettingsPage()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.emergency, color: AppTheme.softError),
            title: const Text('Emergency Settings'),
            subtitle: const Text(
              'Configure critical low/high emergency alerts',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencySettingsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardTintMint,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAboutItem(Icons.info, 'App Version', '1.0.0'),
          const Divider(),
          _buildAboutItem(Icons.privacy_tip, 'Privacy Policy', ''),
          const Divider(),
          _buildAboutItem(Icons.description, 'Terms of Service', ''),
          const Divider(),
          _buildAboutItem(Icons.help, 'Help & Support', ''),
        ],
      ),
    );
  }

  Widget _buildAboutItem(IconData icon, String title, String? trailing) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      trailing: trailing != null && trailing.isNotEmpty
          ? Text(trailing, style: const TextStyle(color: Colors.grey))
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title - Coming soon!')));
      },
    );
  }
}

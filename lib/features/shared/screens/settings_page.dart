import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/features/doctor/screens/doctor_profile_setup_page.dart';
import 'package:dia_plus/features/patient/screens/profile_page.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialsController = TextEditingController();
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
      _nameController.text =
          user?.displayName ?? prefs.getString('userName') ?? '';
      _initialsController.text =
          prefs.getString('userInitials') ?? user?.initials ?? '';
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userInitials', _initialsController.text);
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
    _nameController.dispose();
    _initialsController.dispose();
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
              _buildSectionTitle('Profile Information'),
              const SizedBox(height: 15),
              if (user?.isPatient ?? false)
                ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text('Edit Profile'),
                  subtitle: const Text(
                    'Name, age, weight, height, diabetes type',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () async {
                    final u = user;
                    if (u == null) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(user: u),
                      ),
                    );
                    await _loadSettings();
                  },
                ),
              if (user?.isPatient ?? false) const SizedBox(height: 12),
              if (user?.isDoctor ?? false)
                ListTile(
                  leading: const Icon(
                    Icons.medical_information,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text('Edit Doctor Profile'),
                  subtitle: const Text(
                    'Specialization, clinic, availability, fees',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorProfileSetupPage(),
                      ),
                    );
                    await _loadSettings();
                  },
                ),
              if (user?.isDoctor ?? false) const SizedBox(height: 12),
              _buildProfileCard(),
              const SizedBox(height: 30),
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

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardTintMint,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryMint,
                  child: Text(
                    _initialsController.text.isNotEmpty
                        ? _initialsController.text.toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryLavender,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _initialsController,
              maxLength: 3,
              decoration: const InputDecoration(
                labelText: 'Short Name / Initials',
                prefixIcon: Icon(Icons.badge),
                fillColor: Colors.white,
                helperText: 'Max 3 characters (e.g., JD for John Doe)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your initials';
                }
                if (value.length > 3) return 'Maximum 3 characters allowed';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardTintLavender,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 5),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 5),
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

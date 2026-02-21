import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialsController = TextEditingController();

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('userName') ?? '';
      _initialsController.text = prefs.getString('userInitials') ?? '';
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text);
      await prefs.setString('userInitials', _initialsController.text);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setBool('darkModeEnabled', _darkModeEnabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              _buildSectionTitle('Profile Information'),
              const SizedBox(height: 15),
              _buildProfileCard(),
              const SizedBox(height: 30),

              // App Preferences
              _buildSectionTitle('App Preferences'),
              const SizedBox(height: 15),
              _buildPreferencesCard(),
              const SizedBox(height: 30),

              // About Section
              _buildSectionTitle('About'),
              const SizedBox(height: 15),
              _buildAboutCard(),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile picture placeholder
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal,
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
                      color: Colors.teal,
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

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Initials/Short Name field
            TextFormField(
              controller: _initialsController,
              maxLength: 3,
              decoration: InputDecoration(
                labelText: 'Short Name / Initials',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                helperText: 'Max 3 characters (e.g., JD for John Doe)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your initials';
                }
                if (value.length > 3) {
                  return 'Maximum 3 characters allowed';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {});
              },
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
            activeColor: Colors.teal,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Coming soon'),
            value: _darkModeEnabled,
            activeColor: Colors.teal,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
            secondary: const Icon(Icons.dark_mode),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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

import 'package:dia_plus/models/emergency_settings.dart';
import 'package:dia_plus/services/emergency_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencySettingsPage extends StatefulWidget {
  const EmergencySettingsPage({super.key});

  @override
  State<EmergencySettingsPage> createState() => _EmergencySettingsPageState();
}

class _EmergencySettingsPageState extends State<EmergencySettingsPage> {
  final _service = EmergencySettingsService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _lowController;
  late final TextEditingController _highController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _messageTemplateController;

  EmergencySettings _settings = const EmergencySettings();
  bool _loading = true;
  bool _saving = false;

  bool get _isEmergencyContactEnabled => _settings.notifyEmergencyContact;

  @override
  void initState() {
    super.initState();
    _lowController = TextEditingController();
    _highController = TextEditingController();
    _contactNameController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _messageTemplateController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _lowController.dispose();
    _highController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _messageTemplateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await _service.getSettings();
    if (!mounted) {
      return;
    }

    setState(() {
      _settings = loaded;
      _lowController.text = loaded.lowThreshold.toStringAsFixed(0);
      _highController.text = loaded.highThreshold.toStringAsFixed(0);
      _contactNameController.text = loaded.emergencyContactName;
      _contactPhoneController.text = loaded.emergencyContactPhone;
      _messageTemplateController.text = loaded.emergencyMessageTemplate;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final low =
        double.tryParse(_lowController.text.trim()) ??
        EmergencySettings.defaultLowThreshold;
    final high =
        double.tryParse(_highController.text.trim()) ??
        EmergencySettings.defaultHighThreshold;

    final updated = _settings.copyWith(
      lowThreshold: low,
      highThreshold: high,
      emergencyContactName: _contactNameController.text.trim(),
      emergencyContactPhone: _contactPhoneController.text.trim(),
      emergencyMessageTemplate: _messageTemplateController.text.trim(),
    );

    setState(() => _saving = true);
    await _service.saveSettings(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = updated;
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency settings saved successfully.')),
    );
  }

  Future<void> _resetDefaults() async {
    setState(() => _saving = true);
    await _service.resetToDefaults();

    if (!mounted) {
      return;
    }

    await _load();
    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency settings reset to defaults.')),
    );
  }

  String? _thresholdValidator(String? value, {required bool isLow}) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }

    if (parsed < 30 || parsed > 500) {
      return 'Value must be between 30 and 500';
    }

    final low = isLow
        ? parsed
        : (double.tryParse(_lowController.text.trim()) ??
              EmergencySettings.defaultLowThreshold);
    final high = isLow
        ? (double.tryParse(_highController.text.trim()) ??
              EmergencySettings.defaultHighThreshold)
        : parsed;

    if (low >= high) {
      return 'Low threshold must be less than high threshold';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Emergency Settings'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _saving ? null : _resetDefaults,
            tooltip: 'Reset defaults',
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Emergency Detection', textTheme),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Enable emergency alerts'),
                      subtitle: const Text(
                        'Turn critical low/high glucose emergency detection on or off.',
                      ),
                      value: _settings.isEmergencyAlertsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(
                            isEmergencyAlertsEnabled: value,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _lowController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            enabled: _settings.isEmergencyAlertsEnabled,
                            decoration: const InputDecoration(
                              labelText: 'Low threshold (mg/dL)',
                              hintText: 'Default: 60',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.arrow_downward_rounded),
                            ),
                            validator: (value) =>
                                _thresholdValidator(value, isLow: true),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _highController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            enabled: _settings.isEmergencyAlertsEnabled,
                            decoration: const InputDecoration(
                              labelText: 'High threshold (mg/dL)',
                              hintText: 'Default: 300',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.arrow_upward_rounded),
                            ),
                            validator: (value) =>
                                _thresholdValidator(value, isLow: false),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Emergency triggers when glucose is below low threshold or above high threshold.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSectionTitle('Emergency Contact', textTheme),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Notify emergency contact'),
                          subtitle: const Text(
                            'Enable simulated contact notification in emergencies.',
                          ),
                          value: _settings.notifyEmergencyContact,
                          onChanged: _settings.isEmergencyAlertsEnabled
                              ? (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      notifyEmergencyContact: value,
                                    );
                                  });
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Notify doctor'),
                          subtitle: const Text(
                            'Enable simulated doctor notification in emergencies.',
                          ),
                          value: _settings.notifyDoctor,
                          onChanged: _settings.isEmergencyAlertsEnabled
                              ? (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      notifyDoctor: value,
                                    );
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _contactNameController,
                            enabled:
                                _settings.isEmergencyAlertsEnabled &&
                                _isEmergencyContactEnabled,
                            decoration: const InputDecoration(
                              labelText: 'Emergency contact name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (_isEmergencyContactEnabled &&
                                  (value ?? '').trim().isEmpty) {
                                return 'Contact name is required when emergency contact notifications are enabled';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contactPhoneController,
                            keyboardType: TextInputType.phone,
                            enabled:
                                _settings.isEmergencyAlertsEnabled &&
                                _isEmergencyContactEnabled,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\-\s()]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Emergency contact phone',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (_isEmergencyContactEnabled && text.isEmpty) {
                                return 'Phone number is required when emergency contact notifications are enabled';
                              }
                              if (text.isNotEmpty && text.length < 8) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSectionTitle('Alert Message & Behavior', textTheme),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _messageTemplateController,
                            maxLines: 3,
                            enabled: _settings.isEmergencyAlertsEnabled,
                            decoration: const InputDecoration(
                              labelText: 'Emergency message template',
                              border: OutlineInputBorder(),
                              helperText: 'Use placeholders: {glucose}, {type}',
                            ),
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Sound'),
                            value: _settings.soundEnabled,
                            onChanged: _settings.isEmergencyAlertsEnabled
                                ? (value) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        soundEnabled: value,
                                      );
                                    });
                                  }
                                : null,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Vibration'),
                            value: _settings.vibrationEnabled,
                            onChanged: _settings.isEmergencyAlertsEnabled
                                ? (value) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        vibrationEnabled: value,
                                      );
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Emergency Settings',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
      ),
    );
  }
}

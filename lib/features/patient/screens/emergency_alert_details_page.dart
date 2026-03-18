import 'package:dia_plus/models/emergency_alert.dart';
import 'package:dia_plus/models/emergency_alert_type.dart';
import 'package:dia_plus/features/patient/widgets/emergency_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmergencyAlertDetailsPage extends StatefulWidget {
  const EmergencyAlertDetailsPage({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.onNotifyEmergencyContact,
    this.onNotifyDoctor,
  });

  final EmergencyAlert alert;
  final Future<void> Function(EmergencyAlert alert)? onAcknowledge;
  final Future<void> Function(EmergencyAlert alert)? onNotifyEmergencyContact;
  final Future<void> Function(EmergencyAlert alert)? onNotifyDoctor;

  @override
  State<EmergencyAlertDetailsPage> createState() =>
      _EmergencyAlertDetailsPageState();
}

class _EmergencyAlertDetailsPageState extends State<EmergencyAlertDetailsPage> {
  late EmergencyAlert _alert;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _alert = widget.alert;
  }

  Future<void> _runAction(
    Future<void> Function(EmergencyAlert alert)? action,
    EmergencyAlert Function(EmergencyAlert current) localUpdater, {
    required String successMessage,
  }) async {
    if (action == null || _processing) {
      return;
    }

    setState(() => _processing = true);
    try {
      await action(_alert);
      if (!mounted) {
        return;
      }
      setState(() {
        _alert = localUpdater(_alert);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLow = _alert.alertType == EmergencyAlertType.criticalLow;
    final accentColor = isLow ? Colors.orange.shade700 : Colors.red.shade700;
    final subTextColor = Colors.grey.shade700;
    final dateFmt = DateFormat('MMM d, y • h:mm a');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Emergency Alert Details'),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      EmergencyStatusChip(
                        type: _alert.alertType,
                        label: '${_alert.alertType.label} • ${_alert.severityLabel}',
                      ),
                      const Spacer(),
                      Text(
                        dateFmt.format(_alert.timestamp),
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _alert.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _alert.glucoseValue.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'mg/dL',
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _alert.message,
                    style: TextStyle(color: subTextColor),
                  ),
                  if ((_alert.readingId ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Reading ID: ${_alert.readingId}',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ..._alert.recommendedActions.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final action = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$index',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(action)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _statusRow('Acknowledged', _alert.wasAcknowledged),
                  _statusRow(
                    'Emergency contact notified',
                    _alert.emergencyContactNotified,
                  ),
                  _statusRow('Doctor notified', _alert.doctorNotified),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _alert.wasAcknowledged
                          ? null
                          : () => _runAction(
                                widget.onAcknowledge,
                                (current) =>
                                    current.copyWith(wasAcknowledged: true),
                                successMessage: 'Alert acknowledged.',
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                      ),
                      icon: _processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Acknowledge Alert'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _alert.emergencyContactNotified
                              ? null
                              : () => _runAction(
                                    widget.onNotifyEmergencyContact,
                                    (current) => current.copyWith(
                                      emergencyContactNotified: true,
                                    ),
                                    successMessage:
                                        'Emergency contact notification simulated.',
                                  ),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Notify Contact'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _alert.doctorNotified
                              ? null
                              : () => _runAction(
                                    widget.onNotifyDoctor,
                                    (current) =>
                                        current.copyWith(doctorNotified: true),
                                    successMessage:
                                        'Doctor notification simulated.',
                                  ),
                          icon: const Icon(Icons.local_hospital_outlined),
                          label: const Text('Notify Doctor'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.radio_button_unchecked,
            color: value ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

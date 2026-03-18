import 'package:dia_plus/models/emergency_alert.dart';
import 'package:dia_plus/models/emergency_alert_type.dart';
import 'package:flutter/material.dart';

class EmergencyAlertBanner extends StatelessWidget {
  const EmergencyAlertBanner({
    super.key,
    required this.alert,
    this.onViewDetails,
    this.onAcknowledge,
  });

  final EmergencyAlert alert;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final isLow = alert.alertType == EmergencyAlertType.criticalLow;
    final color = isLow ? Colors.orange.shade700 : Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${alert.glucoseValue.toStringAsFixed(0)} mg/dL • ${alert.alertType.label}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(alert.message),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onViewDetails,
                child: const Text('View Details'),
              ),
              FilledButton(
                onPressed: onAcknowledge,
                style: FilledButton.styleFrom(backgroundColor: color),
                child: const Text('Acknowledge'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

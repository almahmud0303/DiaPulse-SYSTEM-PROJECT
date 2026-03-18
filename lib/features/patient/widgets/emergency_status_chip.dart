import 'package:dia_plus/models/emergency_alert_type.dart';
import 'package:flutter/material.dart';

class EmergencyStatusChip extends StatelessWidget {
  const EmergencyStatusChip({
    super.key,
    required this.type,
    this.label,
  });

  final EmergencyAlertType type;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isLow = type == EmergencyAlertType.criticalLow;
    final background = isLow ? Colors.orange.shade100 : Colors.red.shade100;
    final foreground = isLow ? Colors.orange.shade900 : Colors.red.shade900;

    return Chip(
      label: Text(label ?? type.label),
      backgroundColor: background,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: foreground),
      side: BorderSide(color: foreground.withValues(alpha: 0.3)),
    );
  }
}

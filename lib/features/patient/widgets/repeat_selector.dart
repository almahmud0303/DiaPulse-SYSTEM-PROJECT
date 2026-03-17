import 'package:dia_plus/models/reminder_repeat_mode.dart';
import 'package:flutter/material.dart';

class RepeatSelector extends StatelessWidget {
  const RepeatSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'Repeat',
    this.validator,
    this.isDense = false,
  });

  final ReminderRepeatMode value;
  final ValueChanged<ReminderRepeatMode> onChanged;
  final String labelText;
  final String? Function(ReminderRepeatMode?)? validator;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ReminderRepeatMode>(
      initialValue: value,
      isDense: isDense,
      decoration: InputDecoration(labelText: labelText),
      items: ReminderRepeatMode.values
          .map(
            (mode) => DropdownMenuItem<ReminderRepeatMode>(
              value: mode,
              child: Text(mode.label),
            ),
          )
          .toList(),
      validator: validator,
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }
}

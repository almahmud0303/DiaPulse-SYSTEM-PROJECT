import 'package:flutter/material.dart';

class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selectedWeekdays,
    required this.onToggle,
    this.showFullLabels = false,
    this.enabled = true,
  });

  final List<int> selectedWeekdays;
  final ValueChanged<int> onToggle;
  final bool showFullLabels;
  final bool enabled;

  static const List<String> _shortLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> _fullLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List<Widget>.generate(7, (index) {
        final weekday = index + 1;
        final isSelected = selectedWeekdays.contains(weekday);
        return FilterChip(
          label: Text(
            showFullLabels ? _fullLabels[index] : _shortLabels[index],
          ),
          selected: isSelected,
          onSelected: enabled ? (_) => onToggle(weekday) : null,
        );
      }),
    );
  }
}

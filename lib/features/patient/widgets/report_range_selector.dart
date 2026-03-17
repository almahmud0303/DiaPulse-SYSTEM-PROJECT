import 'package:dia_plus/features/patient/history/models/history_date_range.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Chip-based date-range selector for the report export screen.
///
/// Shows preset options (Last 7 Days, Last 30 Days, This Month, Today) and a
/// "Custom Range" action chip. When a custom range is active its dates are
/// displayed inline.
class ReportRangeSelector extends StatelessWidget {
  const ReportRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeSelected,
    required this.onCustomRangePressed,
  });

  final HistoryDateRange selectedRange;
  final ValueChanged<HistoryDateRange> onRangeSelected;
  final VoidCallback onCustomRangePressed;

  static List<HistoryDateRange> get _presets => [
    HistoryDateRange.last7Days(),
    HistoryDateRange.last30Days(),
    HistoryDateRange.thisMonth(),
    HistoryDateRange.today(),
  ];

  bool _isPresetSelected(HistoryDateRange preset) =>
      !selectedRange.isCustom && selectedRange.label == preset.label;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date Range',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._presets.map((range) {
                final selected = _isPresetSelected(range);
                return ChoiceChip(
                  label: Text(range.label),
                  selected: selected,
                  onSelected: (_) => onRangeSelected(range),
                  selectedColor: Colors.teal,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.grey[700],
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: selected
                      ? BorderSide.none
                      : BorderSide(color: Colors.grey.shade300),
                );
              }),
              ActionChip(
                label: const Text('Custom Range'),
                avatar: Icon(
                  Icons.date_range,
                  size: 16,
                  color: selectedRange.isCustom
                      ? Colors.teal.shade700
                      : Colors.grey[600],
                ),
                onPressed: onCustomRangePressed,
                backgroundColor: selectedRange.isCustom
                    ? Colors.teal.shade50
                    : null,
                side: selectedRange.isCustom
                    ? BorderSide(color: Colors.teal.shade300)
                    : BorderSide(color: Colors.grey.shade300),
              ),
            ],
          ),
          if (selectedRange.isCustom) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onCustomRangePressed,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${df.format(selectedRange.startDate)} – ${df.format(selectedRange.endDate)}',
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Colors.teal.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:dia_plus/features/patient/history/models/history_date_range.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryDateFilterBar extends StatelessWidget {
  const HistoryDateFilterBar({
    super.key,
    required this.selectedRange,
    required this.onRangeSelected,
    required this.onCustomRangePressed,
  });

  final HistoryDateRange selectedRange;
  final ValueChanged<HistoryDateRange> onRangeSelected;
  final VoidCallback onCustomRangePressed;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d MMM yyyy');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.teal.shade600),
              const SizedBox(width: 10),
              const Text(
                'Date Range',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onCustomRangePressed,
                icon: const Icon(Icons.tune),
                label: const Text('Custom'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HistoryDateRange.quickOptions().map((option) {
                final isSelected =
                    !selectedRange.isCustom &&
                    selectedRange.label == option.label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option.label),
                    selected: isSelected,
                    onSelected: (_) => onRangeSelected(option),
                    selectedColor: Colors.teal.shade100,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.teal.shade800
                          : Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedRange.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(selectedRange.normalizedStart)} - ${formatter.format(selectedRange.normalizedEnd)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

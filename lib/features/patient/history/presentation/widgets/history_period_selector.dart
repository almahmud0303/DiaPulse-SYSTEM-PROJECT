import 'package:dia_plus/features/patient/history/models/glucose_trend_period.dart';
import 'package:flutter/material.dart';

class HistoryPeriodSelector extends StatelessWidget {
  const HistoryPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  final GlucoseTrendPeriod selectedPeriod;
  final ValueChanged<GlucoseTrendPeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final period = GlucoseTrendPeriod.values[index];
          final isSelected = period == selectedPeriod;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal.shade600 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onPeriodSelected(period),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  period.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: GlucoseTrendPeriod.values.length,
      ),
    );
  }
}

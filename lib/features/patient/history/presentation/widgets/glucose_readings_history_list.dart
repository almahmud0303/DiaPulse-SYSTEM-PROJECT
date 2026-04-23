import 'package:dia_plus/features/patient/history/presentation/widgets/glucose_reading_history_tile.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GlucoseReadingsHistoryList extends StatelessWidget {
  const GlucoseReadingsHistoryList({super.key, required this.groupedReadings});

  final Map<DateTime, List<GlucoseReading>> groupedReadings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previous Readings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final entry in groupedReadings.entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _sectionLabel(entry.key),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
            for (final reading in entry.value)
              GlucoseReadingHistoryTile(reading: reading),
          ],
        ],
      ),
    );
  }

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (normalizedDate == today) {
      return 'Today';
    }
    if (normalizedDate == yesterday) {
      return 'Yesterday';
    }
    return DateFormat('EEEE, d MMM yyyy').format(date);
  }
}

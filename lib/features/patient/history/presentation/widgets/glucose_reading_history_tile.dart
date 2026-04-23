import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GlucoseReadingHistoryTile extends StatelessWidget {
  const GlucoseReadingHistoryTile({super.key, required this.reading});

  final GlucoseReading reading;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(reading.glucoseLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardTintMintColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                reading.glucoseLevel.round().toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reading.mealTime,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        reading.getStatus(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('h:mm a').format(reading.date),
                  style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                ),
                if (reading.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    reading.notes,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('mg/dL', style: TextStyle(color: AppTheme.textSecondaryColor(context))),
        ],
      ),
    );
  }

  Color _statusColor(double glucoseLevel) {
    if (glucoseLevel < 70) {
      return AppTheme.secondaryLavender;
    }
    if (glucoseLevel <= 180) {
      return AppTheme.primaryMint;
    }
    return AppTheme.accentPeach;
  }
}

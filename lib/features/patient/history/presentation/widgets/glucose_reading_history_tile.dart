import 'package:dia_plus/models/glucose_reading.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
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
                        color: color.withOpacity(0.12),
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
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (reading.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    reading.notes,
                    style: TextStyle(
                      color: Colors.grey.shade700,
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
          Text('mg/dL', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Color _statusColor(double glucoseLevel) {
    if (glucoseLevel < 70) {
      return Colors.blue;
    }
    if (glucoseLevel <= 180) {
      return Colors.green;
    }
    return Colors.orange;
  }
}

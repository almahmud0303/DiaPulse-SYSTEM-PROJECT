import 'package:flutter/material.dart';
import 'package:dia_plus/core/theme/app_theme.dart';

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.cardTintLavender,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.query_stats,
              color: AppTheme.secondaryLavender,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No readings found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different date range to review your glucose history.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

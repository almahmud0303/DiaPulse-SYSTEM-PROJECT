import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/features/patient/screens/step_history_page.dart';
import 'package:dia_plus/services/step_counter_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientStepCard extends StatefulWidget {
  const PatientStepCard({super.key});

  @override
  State<PatientStepCard> createState() => _PatientStepCardState();
}

class _PatientStepCardState extends State<PatientStepCard>
    with WidgetsBindingObserver {
  static const int _dailyGoal = 10000;

  final StepCounterService _steps = StepCounterService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _steps.setUserId(uid);
    _steps.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _steps.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _steps.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardTintMintColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.secondaryLavender.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMint.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_walk_rounded,
                    color: AppTheme.textPrimaryColor(context),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Steps today',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StepHistoryPage()),
                  ),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('History', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Count or status message ──────────────────────
            ValueListenableBuilder<String?>(
              valueListenable: _steps.statusMessage,
              builder: (context, msg, _) {
                if (msg != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor(context),
                        height: 1.35,
                      ),
                    ),
                  );
                }
                return ValueListenableBuilder<int>(
                  valueListenable: _steps.todaySteps,
                  builder: (context, steps, _) {
                    final pct = (steps / _dailyGoal).clamp(0.0, 1.0);
                    final goalMet = steps >= _dailyGoal;
                    final barColor = goalMet
                        ? Colors.teal
                        : steps >= 5000
                            ? Colors.orange
                            : AppTheme.primaryMint;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Count
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              NumberFormat('#,###').format(steps),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'steps',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              goalMet
                                  ? '🎯 Goal reached!'
                                  : '${NumberFormat('#,###').format(_dailyGoal - steps)} left',
                              style: TextStyle(
                                fontSize: 12,
                                color: goalMet
                                    ? Colors.teal
                                    : AppTheme.textSecondaryColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 7,
                            backgroundColor:
                                barColor.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Goal label
                        Row(
                          children: [
                            Text(
                              '0',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    AppTheme.textSecondaryColor(context),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Goal: ${NumberFormat('#,###').format(_dailyGoal)}',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    AppTheme.textSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Carried in a pocket works best. Updates every few steps.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
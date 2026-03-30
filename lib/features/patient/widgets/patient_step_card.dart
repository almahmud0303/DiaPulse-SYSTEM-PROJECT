import 'package:dia_plus/services/step_counter_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Today’s step count from the device pedometer (patients only).
class PatientStepCard extends StatefulWidget {
  const PatientStepCard({super.key});

  @override
  State<PatientStepCard> createState() => _PatientStepCardState();
}

class _PatientStepCardState extends State<PatientStepCard>
    with WidgetsBindingObserver {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_walk, color: Colors.teal, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Steps today',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<String?>(
              valueListenable: _steps.statusMessage,
              builder: (context, msg, _) {
                if (msg != null) {
                  return Text(
                    msg,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
                  );
                }
                return ValueListenableBuilder<int>(
                  valueListenable: _steps.todaySteps,
                  builder: (context, steps, _) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$steps',
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
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Uses your phone’s motion sensors. Carried in a pocket works best.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

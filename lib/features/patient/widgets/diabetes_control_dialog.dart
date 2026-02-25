import 'package:flutter/material.dart';

/// Beautiful dialog showing diabetes control status after saving a reading
class DiabetesControlDialog extends StatelessWidget {
  final double glucoseLevel;
  final String mealTime;

  const DiabetesControlDialog({
    super.key,
    required this.glucoseLevel,
    required this.mealTime,
  });

  String _getControlStatus() {
    if (glucoseLevel < 70) {
      return 'Low Blood Sugar';
    } else if (glucoseLevel >= 70 && glucoseLevel <= 140) {
      return 'Well Controlled';
    } else if (glucoseLevel > 140 && glucoseLevel <= 200) {
      return 'Needs Attention';
    } else {
      return 'Critical Level';
    }
  }

  String _getDetailedMessage() {
    if (glucoseLevel < 70) {
      return 'Your blood sugar is lower than normal. Consider eating a fast-acting carbohydrate like fruit juice or glucose tablets.';
    } else if (glucoseLevel >= 70 && glucoseLevel <= 140) {
      return 'Excellent! Your diabetes is well controlled. Keep up the good work with your diet and medication routine.';
    } else if (glucoseLevel > 140 && glucoseLevel <= 200) {
      return 'Your blood sugar is slightly elevated. Review your diet, exercise, and medication with your doctor if this persists.';
    } else {
      return 'Your blood sugar is very high. Please consult your doctor immediately and monitor your levels closely.';
    }
  }

  Color _getStatusColor() {
    if (glucoseLevel < 70) {
      return Colors.blue;
    } else if (glucoseLevel >= 70 && glucoseLevel <= 140) {
      return Colors.green;
    } else if (glucoseLevel > 140 && glucoseLevel <= 200) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    if (glucoseLevel < 70) {
      return Icons.arrow_downward_rounded;
    } else if (glucoseLevel >= 70 && glucoseLevel <= 140) {
      return Icons.check_circle;
    } else if (glucoseLevel > 140 && glucoseLevel <= 200) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  List<String> _getRecommendations() {
    if (glucoseLevel < 70) {
      return [
        'Eat 15-20g of fast-acting carbs',
        'Recheck in 15 minutes',
        'Rest and avoid exercise',
      ];
    } else if (glucoseLevel >= 70 && glucoseLevel <= 140) {
      return [
        'Maintain your current routine',
        'Continue regular monitoring',
        'Keep up healthy eating habits',
      ];
    } else if (glucoseLevel > 140 && glucoseLevel <= 200) {
      return [
        'Review your meal portions',
        'Stay hydrated with water',
        'Consider light exercise',
      ];
    } else {
      return [
        'Contact your healthcare provider',
        'Check for ketones if needed',
        'Stay well hydrated',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final controlStatus = _getControlStatus();
    final detailedMessage = _getDetailedMessage();
    final recommendations = _getRecommendations();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.white, statusColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with animated icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.withOpacity(0.8), statusColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(statusIcon, size: 48, color: statusColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reading Saved!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          glucoseLevel.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'mg/dL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        mealTime,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Status and message
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monitor_heart,
                                color: statusColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                controlStatus,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            detailedMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Recommendations
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recommendations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...recommendations.map(
                            (rec) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      rec,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show the dialog
  static Future<void> show(
    BuildContext context, {
    required double glucoseLevel,
    required String mealTime,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          DiabetesControlDialog(glucoseLevel: glucoseLevel, mealTime: mealTime),
    );
  }
}

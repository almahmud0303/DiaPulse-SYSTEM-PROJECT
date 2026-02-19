import 'package:flutter/material.dart';

class DiabetesEssentialsPage extends StatelessWidget {
  const DiabetesEssentialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Diabetes Essentials'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.book, color: Colors.white, size: 48),
                SizedBox(height: 15),
                Text(
                  'Learn About Diabetes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Everything you need to know to manage your diabetes effectively',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Understanding Diabetes Section
          _buildSection('Understanding Diabetes', Icons.info_outline, Colors.orange, [
            _buildContentCard(
              'What is Diabetes?',
              'Diabetes is a chronic condition that affects how your body processes blood sugar (glucose). Glucose is vital for your health as it\'s an important source of energy for cells.',
              Icons.help_outline,
              Colors.orange,
            ),
            _buildContentCard(
              'Types of Diabetes',
              'Type 1: The body doesn\'t produce insulin.\nType 2: The body doesn\'t use insulin well.\nGestational: Occurs during pregnancy.',
              Icons.category,
              Colors.orange,
            ),
            _buildContentCard(
              'Symptoms to Watch',
              '• Increased thirst and urination\n• Fatigue\n• Blurred vision\n• Slow healing wounds\n• Unexplained weight loss',
              Icons.warning,
              Colors.orange,
            ),
          ]),

          const SizedBox(height: 20),

          // Diet & Nutrition Section
          _buildSection('Diet & Nutrition', Icons.restaurant_menu, Colors.green, [
            _buildContentCard(
              'Healthy Eating Tips',
              '• Choose fiber-rich foods\n• Eat at regular times\n• Control portion sizes\n• Limit processed foods\n• Stay hydrated',
              Icons.eco,
              Colors.green,
            ),
            _buildContentCard(
              'Foods to Include',
              '• Whole grains\n• Leafy vegetables\n• Lean proteins\n• Fruits (in moderation)\n• Healthy fats (nuts, avocados)',
              Icons.check_circle,
              Colors.green,
            ),
            _buildContentCard(
              'Foods to Limit',
              '• Sugary drinks\n• White bread and pasta\n• Fried foods\n• High-sodium foods\n• Processed snacks',
              Icons.cancel,
              Colors.green,
            ),
          ]),

          const SizedBox(height: 20),

          // Exercise Section
          _buildSection('Exercise Tips', Icons.fitness_center, Colors.red, [
            _buildContentCard(
              'Benefits of Exercise',
              'Regular physical activity helps lower blood sugar, improves insulin sensitivity, manages weight, and reduces stress.',
              Icons.favorite,
              Colors.red,
            ),
            _buildContentCard(
              'Recommended Activities',
              '• Walking (30 min daily)\n• Swimming\n• Cycling\n• Yoga\n• Strength training (2-3x/week)',
              Icons.directions_walk,
              Colors.red,
            ),
            _buildContentCard(
              'Exercise Safety',
              '• Check blood sugar before and after\n• Stay hydrated\n• Wear proper footwear\n• Start slowly\n• Carry fast-acting carbs',
              Icons.security,
              Colors.red,
            ),
          ]),

          const SizedBox(height: 20),

          // Medication Section
          _buildSection('Medication Guide', Icons.medication, Colors.blue, [
            _buildContentCard(
              'Common Medications',
              'Metformin: First-line oral medication\nInsulin: Hormone therapy for blood sugar control\nSGLT2 inhibitors: Help kidneys remove sugar',
              Icons.medical_services,
              Colors.blue,
            ),
            _buildContentCard(
              'Taking Medications',
              '• Follow prescribed schedule\n• Don\'t skip doses\n• Store properly\n• Track side effects\n• Refill on time',
              Icons.schedule,
              Colors.blue,
            ),
            _buildContentCard(
              'Important Reminders',
              '• Never adjust doses without consulting your doctor\n• Keep a medication list\n• Know interactions\n• Inform all healthcare providers',
              Icons.notification_important,
              Colors.blue,
            ),
          ]),

          const SizedBox(height: 20),

          // Monitoring Section
          _buildSection('Blood Sugar Monitoring', Icons.analytics, Colors.teal, [
            _buildContentCard(
              'Target Levels',
              'Before meals: 80-130 mg/dL\nAfter meals (2hr): <180 mg/dL\nA1C: <7%\n*Consult your doctor for personalized targets',
              Icons.track_changes,
              Colors.teal,
            ),
            _buildContentCard(
              'When to Test',
              '• Before meals\n• Before/after exercise\n• Before bed\n• When feeling unwell\n• As recommended by doctor',
              Icons.schedule,
              Colors.teal,
            ),
            _buildContentCard(
              'Record Keeping',
              'Keep a log of readings, meals, activities, and medications to identify patterns and trends.',
              Icons.note_add,
              Colors.teal,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...children,
      ],
    );
  }

  Widget _buildContentCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

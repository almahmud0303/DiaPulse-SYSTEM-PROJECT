import 'package:flutter/material.dart';

/// Placeholder for Take Medicine / log medicine taken - full feature in Medication todo.
class TakeMedicinePage extends StatelessWidget {
  const TakeMedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Medicine'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 80, color: Colors.purple.shade300),
            const SizedBox(height: 24),
            Text(
              'Log medicine taken',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Full medicine log & reminders in Medication feature',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

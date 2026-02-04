import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'starting_page.dart';

/// Screen shown after successful login/registration.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dia Plus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const StartingPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
              const SizedBox(height: 24),
              Text(
                'Welcome${user?.displayName != null && user!.displayName!.isNotEmpty ? ', ${user.displayName}' : ''}!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 8),
                Text(
                  user!.email!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

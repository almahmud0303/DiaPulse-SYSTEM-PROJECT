import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const DiaPlusApp());
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    runApp(_FirebaseErrorApp(error: e.toString()));
  }
}

/// Shown when Firebase fails to initialize.
class _FirebaseErrorApp extends StatelessWidget {
  const _FirebaseErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 24),
                Text(
                  'Unable to start app',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DiaPlusApp extends StatelessWidget {
  const DiaPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dia Plus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.start,
      routes: AppRouter.routes,
    );
  }
}

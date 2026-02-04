import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/starting_page.dart';
import 'screens/home_page.dart';
import 'screens/email_verification_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      // For web, Firebase is initialized via index.html scripts
      // But we still need to call initializeApp() for Flutter
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // For mobile platforms (Android/iOS)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase not configured yet - app will still run but auth won't work
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Firebase initialization error: $e');
    if (kIsWeb) {
      debugPrint('');
      debugPrint('⚠️  WEB FIREBASE CONFIG MISSING!');
      debugPrint('');
      debugPrint('To fix:');
      debugPrint('1. Go to Firebase Console → Project Overview');
      debugPrint('2. Click Web icon (</>) or "Add app" → Web');
      debugPrint('3. Register your web app');
      debugPrint('4. Copy apiKey and appId from the config');
      debugPrint('5. Update lib/firebase_options.dart (lines 26-27)');
      debugPrint('6. Update web/index.html (lines 51, 56)');
      debugPrint('');
      debugPrint('See WEB_LOGIN_FIX.md for detailed instructions');
    } else {
      debugPrint(
        'For Android: Ensure google-services.json is in android/app/ folder',
      );
    }
    debugPrint('═══════════════════════════════════════════════════════');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dia Plus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            // Check if email is verified
            if (snapshot.data!.emailVerified) {
              return const HomePage();
            } else {
              return const EmailVerificationPage();
            }
          }
          return const StartingPage();
        },
      ),
    );
  }
}

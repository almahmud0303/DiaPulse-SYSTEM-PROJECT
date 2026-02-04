// File generated to support Firebase initialization
// For web: Update web/index.html with your Firebase config from Firebase Console
// For Android: Use google-services.json (already configured)
// For iOS: Use GoogleService-Info.plist (if needed)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web platform - Firebase config from Firebase Console
      return const FirebaseOptions(
        apiKey: 'AIzaSyDM3xd7boFM7RNrO8GmktpUj0IINWR-l94',
        appId: '1:284015189329:web:a7daf89f25b454717b8770',
        messagingSenderId: '284015189329',
        projectId: 'dia-plus-7c78c',
        authDomain: 'dia-plus-7c78c.firebaseapp.com',
        storageBucket: 'dia-plus-7c78c.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android uses google-services.json
        return const FirebaseOptions(
          apiKey: 'AIzaSyALzg3GX-CjSIhXQTD1ugMR_9aDItiBIyc',
          appId: '1:284015189329:android:d0b7c50ec1df95ee7b8770',
          messagingSenderId: '284015189329',
          projectId: 'dia-plus-7c78c',
          storageBucket: 'dia-plus-7c78c.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        // iOS - update with your iOS config if needed
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}

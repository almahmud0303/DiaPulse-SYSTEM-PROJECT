import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles Firebase Authentication and user info in Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Register with email and password and save user info to Firestore.
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String? phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        await cred.user!.updateDisplayName(displayName);
        await _saveUserInfo(
          uid: cred.user!.uid,
          email: email.trim(),
          displayName: displayName,
          phone: phone,
        );
      }
      return cred;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Save user profile to Firestore (users collection).
  Future<void> _saveUserInfo({
    required String uid,
    required String email,
    required String displayName,
    String? phone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'phone': phone ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get current user profile from Firestore.
  Future<Map<String, dynamic>?> getUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Send email verification to current user.
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        // Configure action code settings for better link handling
        final actionCodeSettings = ActionCodeSettings(
          // URL to redirect to after verification
          // Replace with your app's URL or use a custom domain
          url: 'https://diapulse-project.firebaseapp.com/__/auth/action',
          // This must be true for email link sign-in
          handleCodeInApp: false,
          // iOS bundle ID
          iOSBundleId: 'com.example.diapulse',
          // Android package name
          androidPackageName: 'com.example.diapulse',
          // Install app if not already installed
          androidInstallApp: true,
          // Minimum version of the app
          androidMinimumVersion: '12',
        );

        await user.sendEmailVerification(actionCodeSettings);
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }
}

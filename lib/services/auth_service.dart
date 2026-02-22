import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/user_role.dart';
import 'package:dia_plus/services/invite_code_service.dart';
import 'package:dia_plus/services/role_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles Firebase Authentication and user info in Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();
  final InviteCodeService _inviteCodeService = InviteCodeService();

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

  /// Register with email and password and save user info in Firestore.
  /// Doctor and Admin require a valid [inviteCode] from an admin.
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phone,
    String? secondPassword,
    String? inviteCode,
  }) async {
    try {
      if (role.requiresSecondPassword) {
        if (inviteCode == null || inviteCode.trim().isEmpty) {
          throw ArgumentError(
            'An invite code is required to register as ${role.displayName}. '
            'Please obtain one from your administrator.',
          );
        }
        final valid = await _inviteCodeService.validateCode(
          code: inviteCode.trim(),
          role: role,
        );
        if (!valid) {
          throw ArgumentError(
            'Invalid or expired invite code. Please check and try again.',
          );
        }
      }
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
          role: role,
          phone: phone,
        );
        if (role.requiresSecondPassword && secondPassword != null && secondPassword.isNotEmpty) {
          await _roleService.setSecondPassword(
            uid: cred.user!.uid,
            secondPassword: secondPassword,
            primaryPassword: password,
          );
        }
        if (role.requiresSecondPassword && inviteCode != null) {
          await _inviteCodeService.consumeCode(
            code: inviteCode.trim(),
            usedByUid: cred.user!.uid,
            usedByEmail: email.trim(),
          );
        }
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
    required UserRole role,
    String? phone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'phone': phone ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get current user profile as AppUser from Firestore.
  Future<AppUser?> getAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap(user.uid, data);
  }

  /// Get user role for current user.
  Future<UserRole?> getCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _roleService.getUserRole(uid);
  }

  /// Check if doctor/admin has set second password.
  Future<bool> hasSecondPassword() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return _roleService.hasSecondPassword(uid);
  }

  /// Verify second password for doctor/admin.
  Future<bool> verifySecondPassword(String secondPassword) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return _roleService.verifySecondPassword(uid: uid, secondPassword: secondPassword);
  }

  /// Set up second password for doctor/admin (when missing). Verifies primary password first.
  Future<void> setupSecondPassword({
    required String primaryPassword,
    required String secondPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null || user.email!.isEmpty) {
      throw ArgumentError('Not logged in or email missing');
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: primaryPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await _roleService.setSecondPassword(
      uid: user.uid,
      secondPassword: secondPassword,
      primaryPassword: primaryPassword,
    );
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
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }
}

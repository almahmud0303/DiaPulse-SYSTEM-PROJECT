import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/user_role.dart';
import 'package:dia_plus/services/invite_access_request_service.dart';
import 'package:dia_plus/services/role_service.dart';
import 'package:dia_plus/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles Firebase Authentication and user info in Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();
  final InviteAccessRequestService _inviteAccessRequestService =
      InviteAccessRequestService();
  final ReminderService _reminderService = ReminderService();

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
  /// Doctor and Admin register in two steps: this call creates the account only;
  /// then apply for access; after an admin approves, they finish on
  /// [CompleteProfessionalRegistrationPage] (second password only).
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
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
          role: role,
          phone: phone,
          professionalInvitePending: role.requiresSecondPassword,
        );
      }
      return cred;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// After admin approves the access request: reauthenticate, set second password, clear pending flag.
  Future<void> completeProfessionalRegistration({
    required String primaryPassword,
    required String secondPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null || user.email!.isEmpty) {
      throw ArgumentError('Not signed in or email missing.');
    }
    final me = await getAppUser();
    if (me == null) {
      throw ArgumentError('User profile not found.');
    }
    if (!me.role.requiresSecondPassword) {
      throw ArgumentError('This account does not require this step.');
    }
    if (!me.professionalInvitePending) {
      throw ArgumentError(
        'Setup is already complete. Sign in with your second password.',
      );
    }
    final latestRequest =
        await _inviteAccessRequestService.fetchLatestForUser(user.uid);
    if (latestRequest == null || !latestRequest.isApproved) {
      throw ArgumentError(
        'An administrator must approve your access request before you can continue.',
      );
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
      clearProfessionalInvitePending: true,
    );
  }

  /// Save user profile to Firestore (users collection).
  Future<void> _saveUserInfo({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
    String? phone,
    bool professionalInvitePending = false,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'phone': phone ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (professionalInvitePending) {
      data['professionalInvitePending'] = true;
    }
    await _firestore.collection('users').doc(uid).set(data);
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
    await _reminderService.cancelAllNotifications();
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

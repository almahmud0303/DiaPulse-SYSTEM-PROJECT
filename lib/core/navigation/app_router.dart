import 'package:flutter/material.dart';

import 'package:dia_plus/core/utils/page_transitions.dart';
import 'package:dia_plus/features/auth/screens/complete_professional_registration_page.dart';
import 'package:dia_plus/features/auth/screens/email_verification_page.dart';
import 'package:dia_plus/features/auth/screens/login_page.dart';
import 'package:dia_plus/features/auth/screens/professional_access_request_page.dart';
import 'package:dia_plus/features/auth/screens/registration_page.dart';
import 'package:dia_plus/features/auth/screens/second_password_page.dart';
import 'package:dia_plus/features/auth/screens/starting_page.dart';
import 'package:dia_plus/features/home/screens/main_navigation_page.dart';

/// Centralized route names and navigation helpers.
class AppRouter {
  AppRouter._();

  static const String start = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String professionalAccessRequest = '/professional-access-request';
  static const String completeProfessionalRegistration =
      '/complete-professional-registration';
  static const String secondPassword = '/second-password';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
        start: (_) => const StartingPage(),
        login: (_) => const LoginPage(),
        register: (_) => const RegistrationPage(),
        emailVerification: (_) => const EmailVerificationPage(),
        professionalAccessRequest: (_) =>
            const ProfessionalAccessRequestPage(),
        completeProfessionalRegistration: (_) =>
            const CompleteProfessionalRegistrationPage(),
        secondPassword: (_) => const SecondPasswordPage(),
        home: (_) => const MainNavigationPage(),
      };

  /// Push to login with slide transition.
  static Future<T?> pushLogin<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      PageTransitions.slideRight(const LoginPage()),
    );
  }

  /// Push to register with slide transition.
  static Future<T?> pushRegister<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      PageTransitions.slideRight(const RegistrationPage()),
    );
  }

  /// Navigate to email verification and clear stack.
  static void goToEmailVerification(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageTransitions.slideRight(const EmailVerificationPage()),
      (route) => false,
    );
  }

  /// Navigate to second password and clear stack.
  static void goToSecondPassword(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageTransitions.slideRight(const SecondPasswordPage()),
      (route) => false,
    );
  }

  /// Doctor/Admin: apply for access; after admin approves, user sets second password.
  static void goToProfessionalAccessRequest(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageTransitions.slideRight(const ProfessionalAccessRequestPage()),
      (route) => false,
    );
  }

  /// Doctor/Admin: confirm password and set second password after admin approved the request.
  static void goToCompleteProfessionalRegistration(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageTransitions.slideRight(
        const CompleteProfessionalRegistrationPage(),
      ),
      (route) => false,
    );
  }

  /// Navigate to home and clear stack.
  static void goToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageTransitions.fade(const MainNavigationPage()),
      (route) => false,
    );
  }

  /// Navigate back to start (after sign out).
  static void goToStart(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(start, (route) => false);
  }
}

/// User roles in the Dia Plus application.
/// Add new roles here and update [displayName] and [requiresSecondPassword].
enum UserRole {
  patient,
  doctor,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Doctor and Admin require a second password for extra security.
  bool get requiresSecondPassword =>
      this == UserRole.doctor || this == UserRole.admin;

  /// API/Firestore string value. Use this when persisting.
  String get value => name;

  static UserRole? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return UserRole.values.firstWhere(
        (r) => r.name == value.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse from dynamic (JSON, Firestore, etc.).
  static UserRole? fromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is UserRole) return value;
    return fromString(value.toString());
  }
}

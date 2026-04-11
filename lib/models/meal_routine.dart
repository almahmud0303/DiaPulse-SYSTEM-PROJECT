/// Patient-defined usual meal times (HH:mm). Used with meal-relative medicine
/// instructions (before/after breakfast, lunch, dinner) to compute reminder times.
class MealRoutine {
  const MealRoutine({
    this.breakfast,
    this.lunch,
    this.dinner,
    this.snack,
  });

  /// Each value is "HH:mm" in 24h local time, or null to use app defaults.
  final String? breakfast;
  final String? lunch;
  final String? dinner;
  final String? snack;

  static const int defaultBreakfastMins = 8 * 60;
  static const int defaultLunchMins = 12 * 60 + 30;
  static const int defaultDinnerMins = 19 * 60;
  static const int defaultSnackMins = 15 * 60 + 30;

  static int? _parseHm(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  /// Minute-of-day (0–1439) for the meal that anchors [doseKey] (e.g. before_lunch → lunch).
  int anchorMinutesForDoseKey(String doseKey) {
    if (doseKey.contains('breakfast')) {
      return _parseHm(breakfast) ?? defaultBreakfastMins;
    }
    if (doseKey.contains('lunch')) {
      return _parseHm(lunch) ?? defaultLunchMins;
    }
    if (doseKey.contains('dinner')) {
      return _parseHm(dinner) ?? defaultDinnerMins;
    }
    if (doseKey.contains('snack')) {
      return _parseHm(snack) ?? defaultSnackMins;
    }
    return defaultBreakfastMins;
  }

  factory MealRoutine.fromMap(Map<String, dynamic> map) {
    return MealRoutine(
      breakfast: map['breakfast']?.toString(),
      lunch: map['lunch']?.toString(),
      dinner: map['dinner']?.toString(),
      snack: map['snack']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (breakfast != null && breakfast!.trim().isNotEmpty) 'breakfast': breakfast!.trim(),
      if (lunch != null && lunch!.trim().isNotEmpty) 'lunch': lunch!.trim(),
      if (dinner != null && dinner!.trim().isNotEmpty) 'dinner': dinner!.trim(),
      if (snack != null && snack!.trim().isNotEmpty) 'snack': snack!.trim(),
    };
  }

  bool get hasAny =>
      (breakfast != null && breakfast!.isNotEmpty) ||
      (lunch != null && lunch!.isNotEmpty) ||
      (dinner != null && dinner!.isNotEmpty) ||
      (snack != null && snack!.isNotEmpty);
}

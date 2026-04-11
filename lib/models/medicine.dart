import 'package:dia_plus/models/meal_routine.dart';

/// Known meal-relative timing keys stored in [Medicine.time].
/// Otherwise [time] is a clock time "HH:mm".
const List<Map<String, String>> medicineTimeOptions = [
  {'value': 'specific', 'label': 'Specific time'},
  {'value': 'before_breakfast', 'label': 'Before breakfast'},
  {'value': 'after_breakfast', 'label': 'After breakfast'},
  {'value': 'before_lunch', 'label': 'Before lunch'},
  {'value': 'after_lunch', 'label': 'After lunch'},
  {'value': 'before_dinner', 'label': 'Before dinner'},
  {'value': 'after_dinner', 'label': 'After dinner'},
];

/// A medicine schedule (name, dosage, time, frequency).
/// [time] is either a clock time "HH:mm" or a meal-relative key (e.g. after_lunch, before_dinner).
/// For multi-dose frequencies (e.g. twice_daily), use [times] to store all doses.
/// Optional insulin-specific fields for adjustment in prescription flow.
class Medicine {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String time; // "09:00" or "after_lunch", "before_dinner", etc.
  /// Optional list of dose times/keys (e.g. ["after_breakfast","after_dinner"]).
  /// If present and non-empty, this is the source of truth for scheduling/display.
  final List<String>? times;
  final String frequency; // daily, twice_daily, weekly
  final DateTime createdAt;

  /// Optional. When set, this medicine belongs to a prescription group (same save session).
  final String? prescriptionId;

  /// True if this prescription is for insulin (enables type and adjustment fields).
  final bool isInsulin;

  /// Insulin type when [isInsulin] is true: rapid_acting, short_acting, intermediate_acting, long_acting, mixed.
  final String? insulinType;

  /// Doctor's instructions for dose adjustment (e.g. based on glucose).
  final String? adjustmentInstructions;

  /// Minutes before (before_*) or after (after_*) the anchored meal for meal-relative doses.
  /// Ignored for fixed clock times ("HH:mm"). Typical prescription: 30.
  final int mealOffsetMinutes;

  Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.time,
    this.times,
    required this.frequency,
    required this.createdAt,
    this.prescriptionId,
    this.isInsulin = false,
    this.insulinType,
    this.adjustmentInstructions,
    this.mealOffsetMinutes = 30,
  });

  /// All dose times for this medicine (falls back to single [time]).
  List<String> get effectiveTimes {
    final t = times;
    if (t != null && t.isNotEmpty) return t;
    return [time];
  }

  bool get hasMealRelativeDose => effectiveTimes.any(isMealRelativeTime);

  Map<String, dynamic> toMap() {
    final effective = effectiveTimes;
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      // Keep legacy single 'time' field for backward compatibility and simple queries.
      'time': effective.first,
      if (effective.length > 1) 'times': effective,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
      if (prescriptionId != null && prescriptionId!.isNotEmpty) 'prescriptionId': prescriptionId,
      'isInsulin': isInsulin,
      if (insulinType != null) 'insulinType': insulinType,
      if (adjustmentInstructions != null && adjustmentInstructions!.isNotEmpty)
        'adjustmentInstructions': adjustmentInstructions,
      'mealOffsetMinutes': mealOffsetMinutes,
    };
  }

  /// [documentId] is the Firestore document id when `id` is missing from stored fields.
  factory Medicine.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final dynamic rawTimes = map['times'];
    List<String>? times;
    if (rawTimes is List) {
      times = rawTimes.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      if (times.isEmpty) times = null;
    }
    final time = map['time'] as String? ?? '09:00';
    final rawId = map['id'];
    final idStr = rawId == null ? '' : rawId.toString().trim();
    final id = idStr.isNotEmpty ? idStr : (documentId ?? '');
    return Medicine(
      id: id,
      userId: map['userId'] == null ? '' : map['userId'].toString(),
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      time: time,
      // If 'times' exists but legacy 'time' isn't included, prepend it so older docs still behave.
      times: times != null
          ? (times.contains(time) ? times : [time, ...times])
          : null,
      frequency: map['frequency'] as String? ?? 'daily',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      prescriptionId: map['prescriptionId'] as String?,
      isInsulin: map['isInsulin'] as bool? ?? false,
      insulinType: map['insulinType'] as String?,
      adjustmentInstructions: map['adjustmentInstructions'] as String?,
      mealOffsetMinutes: _parseMealOffsetMinutes(map['mealOffsetMinutes']),
    );
  }

  static int _parseMealOffsetMinutes(dynamic raw) {
    if (raw is int) return raw.clamp(0, 180);
    if (raw is num) return raw.toInt().clamp(0, 180);
    final s = raw?.toString();
    if (s != null && s.isNotEmpty) {
      final v = int.tryParse(s);
      if (v != null) return v.clamp(0, 180);
    }
    return 30;
  }

  /// Human-readable label for [insulinType].
  static String insulinTypeLabel(String? type) {
    if (type == null || type.isEmpty) return 'Insulin';
    switch (type) {
      case 'rapid_acting':
        return 'Rapid-acting';
      case 'short_acting':
        return 'Short-acting';
      case 'intermediate_acting':
        return 'Intermediate-acting';
      case 'long_acting':
        return 'Long-acting';
      case 'mixed':
        return 'Mixed';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  /// True if [time] is a meal-relative key (e.g. after_lunch), not a clock time.
  static bool isMealRelativeTime(String time) {
    if (time.isEmpty) return false;
    if (time.contains(':')) return false; // "HH:mm"
    return time == 'before_breakfast' ||
        time == 'after_breakfast' ||
        time == 'before_lunch' ||
        time == 'after_lunch' ||
        time == 'before_dinner' ||
        time == 'after_dinner';
  }

  /// Human-readable label for when to take (e.g. "After lunch" or "09:00").
  static String timeDisplayLabel(String time) {
    if (isMealRelativeTime(time)) {
      switch (time) {
        case 'before_breakfast':
          return 'Before breakfast';
        case 'after_breakfast':
          return 'After breakfast';
        case 'before_lunch':
          return 'Before lunch';
        case 'after_lunch':
          return 'After lunch';
        case 'before_dinner':
          return 'Before dinner';
        case 'after_dinner':
          return 'After dinner';
        default:
          return time.replaceAll('_', ' ');
      }
    }
    return time; // "09:00" etc.
  }

  static int _normMinutesOfDay(int minutes) {
    var m = minutes % (24 * 60);
    if (m < 0) m += 24 * 60;
    return m;
  }

  /// Minute-of-day (0–1439) for a single dose key, using [routine] meal anchors when set.
  static int reminderTotalMinutes(
    String doseKey,
    MealRoutine? routine,
    int mealOffsetMinutes,
  ) {
    if (!isMealRelativeTime(doseKey)) {
      final parts = doseKey.split(':');
      final h = parts.isNotEmpty ? (int.tryParse(parts[0].trim()) ?? 9) : 9;
      final mm = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
      return _normMinutesOfDay(h * 60 + mm);
    }
    final anchor = (routine ?? const MealRoutine()).anchorMinutesForDoseKey(doseKey);
    final before = doseKey.startsWith('before_');
    final delta = before ? -mealOffsetMinutes : mealOffsetMinutes;
    return _normMinutesOfDay(anchor + delta);
  }

  /// Local clock for notifications and sorting.
  static (int hour, int minute) reminderClockForDose(
    String doseKey,
    MealRoutine? routine,
    int mealOffsetMinutes,
  ) {
    final t = reminderTotalMinutes(doseKey, routine, mealOffsetMinutes);
    return (t ~/ 60, t % 60);
  }

  /// First dose of the day in minutes-from-midnight (for sorting / next dose).
  static int firstDoseMinutesOf(Medicine m, MealRoutine? routine) {
    final mins = m.effectiveTimes
        .map((d) => reminderTotalMinutes(d, routine, m.mealOffsetMinutes))
        .toList()
      ..sort();
    return mins.isNotEmpty ? mins.first : 0;
  }

  /// Hour and minute for reminder scheduling (uses default meal anchors when [routine] is null).
  static (int hour, int minute) reminderTimeFrom(String time) {
    return reminderClockForDose(time, null, 30);
  }

  /// Display label for a whole medicine (single or multi-dose).
  static String medicineTimesLabel(Medicine m) {
    final parts = m.effectiveTimes.map(timeDisplayLabel).toList();
    return parts.join(' / ');
  }
}

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
  });

  /// All dose times for this medicine (falls back to single [time]).
  List<String> get effectiveTimes {
    final t = times;
    if (t != null && t.isNotEmpty) return t;
    return [time];
  }

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
    );
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

  /// Hour and minute to use for reminder scheduling. For meal-relative times uses defaults.
  static (int hour, int minute) reminderTimeFrom(String time) {
    if (!isMealRelativeTime(time)) {
      final parts = time.split(':');
      final h = parts.isNotEmpty ? (int.tryParse(parts[0].trim()) ?? 9) : 9;
      final m = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
      return (h, m);
    }
    switch (time) {
      case 'before_breakfast':
        return (7, 0);
      case 'after_breakfast':
        return (8, 30);
      case 'before_lunch':
        return (12, 0);
      case 'after_lunch':
        return (13, 30);
      case 'before_dinner':
        return (18, 0);
      case 'after_dinner':
        return (19, 30);
      default:
        return (9, 0);
    }
  }

  /// Display label for a whole medicine (single or multi-dose).
  static String medicineTimesLabel(Medicine m) {
    final parts = m.effectiveTimes.map(timeDisplayLabel).toList();
    return parts.join(' / ');
  }
}

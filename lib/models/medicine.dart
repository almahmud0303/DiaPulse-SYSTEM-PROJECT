/// A medicine schedule (name, dosage, time, frequency).
/// Optional insulin-specific fields for adjustment in prescription flow.
class Medicine {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String time; // "09:00", "21:00"
  final String frequency; // daily, twice_daily, weekly
  final DateTime createdAt;

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
    required this.frequency,
    required this.createdAt,
    this.isInsulin = false,
    this.insulinType,
    this.adjustmentInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'time': time,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
      'isInsulin': isInsulin,
      if (insulinType != null) 'insulinType': insulinType,
      if (adjustmentInstructions != null && adjustmentInstructions!.isNotEmpty)
        'adjustmentInstructions': adjustmentInstructions,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      time: map['time'] as String? ?? '09:00',
      frequency: map['frequency'] as String? ?? 'daily',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
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
}

import 'package:dia_plus/models/reminder_repeat_mode.dart';
import 'package:dia_plus/models/reminder_type.dart';

class Reminder {
  final String id;
  final String title;
  final String description;
  final ReminderType reminderType;
  final DateTime date;
  final DateTime time;
  final ReminderRepeatMode repeatMode;
  final List<int> selectedWeekdays;
  final bool isEnabled;
  final DateTime createdAt;
  final String? relatedEntityId;
  final List<int> notificationIds;

  Reminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.reminderType,
    required this.date,
    required this.time,
    this.repeatMode = ReminderRepeatMode.once,
    this.selectedWeekdays = const [],
    this.isEnabled = true,
    required this.createdAt,
    this.relatedEntityId,
    this.notificationIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reminderType': reminderType.key,
      'date': date.toIso8601String(),
      'time': time.toIso8601String(),
      'repeatMode': repeatMode.key,
      'selectedWeekdays': selectedWeekdays,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'relatedEntityId': relatedEntityId,
      'notificationIds': notificationIds,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      reminderType: ReminderTypeX.fromKey(map['reminderType'] as String? ?? ''),
      date: DateTime.parse(map['date'] as String),
      time: DateTime.parse(map['time'] as String),
      repeatMode: ReminderRepeatModeX.fromKey(
        map['repeatMode'] as String? ?? '',
      ),
      selectedWeekdays: ((map['selectedWeekdays'] as List?) ?? const [])
          .whereType<num>()
          .map((v) => v.toInt())
          .toList(),
      isEnabled: map['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      relatedEntityId: map['relatedEntityId'] as String?,
      notificationIds: ((map['notificationIds'] as List?) ?? const [])
          .whereType<num>()
          .map((v) => v.toInt())
          .toList(),
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    ReminderType? reminderType,
    DateTime? date,
    DateTime? time,
    ReminderRepeatMode? repeatMode,
    List<int>? selectedWeekdays,
    bool? isEnabled,
    DateTime? createdAt,
    String? relatedEntityId,
    List<int>? notificationIds,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderType: reminderType ?? this.reminderType,
      date: date ?? this.date,
      time: time ?? this.time,
      repeatMode: repeatMode ?? this.repeatMode,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      notificationIds: notificationIds ?? this.notificationIds,
    );
  }
}

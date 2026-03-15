enum ReminderRepeatMode { once, daily, weekly, selectedWeekdays }

extension ReminderRepeatModeX on ReminderRepeatMode {
  String get label {
    switch (this) {
      case ReminderRepeatMode.once:
        return 'Once';
      case ReminderRepeatMode.daily:
        return 'Daily';
      case ReminderRepeatMode.weekly:
        return 'Weekly';
      case ReminderRepeatMode.selectedWeekdays:
        return 'Selected Weekdays';
    }
  }

  String get key {
    return name;
  }

  static ReminderRepeatMode fromKey(String value) {
    return ReminderRepeatMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ReminderRepeatMode.once,
    );
  }
}

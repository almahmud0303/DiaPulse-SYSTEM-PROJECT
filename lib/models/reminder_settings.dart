class ReminderSettings {
  final bool allRemindersEnabled;
  final bool medicineRemindersEnabled;
  final bool glucoseRemindersEnabled;
  final bool exerciseRemindersEnabled;
  final bool appointmentRemindersEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const ReminderSettings({
    this.allRemindersEnabled = true,
    this.medicineRemindersEnabled = true,
    this.glucoseRemindersEnabled = true,
    this.exerciseRemindersEnabled = true,
    this.appointmentRemindersEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'allRemindersEnabled': allRemindersEnabled,
      'medicineRemindersEnabled': medicineRemindersEnabled,
      'glucoseRemindersEnabled': glucoseRemindersEnabled,
      'exerciseRemindersEnabled': exerciseRemindersEnabled,
      'appointmentRemindersEnabled': appointmentRemindersEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      allRemindersEnabled: map['allRemindersEnabled'] as bool? ?? true,
      medicineRemindersEnabled:
          map['medicineRemindersEnabled'] as bool? ?? true,
      glucoseRemindersEnabled: map['glucoseRemindersEnabled'] as bool? ?? true,
      exerciseRemindersEnabled:
          map['exerciseRemindersEnabled'] as bool? ?? true,
      appointmentRemindersEnabled:
          map['appointmentRemindersEnabled'] as bool? ?? true,
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
    );
  }

  ReminderSettings copyWith({
    bool? allRemindersEnabled,
    bool? medicineRemindersEnabled,
    bool? glucoseRemindersEnabled,
    bool? exerciseRemindersEnabled,
    bool? appointmentRemindersEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return ReminderSettings(
      allRemindersEnabled: allRemindersEnabled ?? this.allRemindersEnabled,
      medicineRemindersEnabled:
          medicineRemindersEnabled ?? this.medicineRemindersEnabled,
      glucoseRemindersEnabled:
          glucoseRemindersEnabled ?? this.glucoseRemindersEnabled,
      exerciseRemindersEnabled:
          exerciseRemindersEnabled ?? this.exerciseRemindersEnabled,
      appointmentRemindersEnabled:
          appointmentRemindersEnabled ?? this.appointmentRemindersEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

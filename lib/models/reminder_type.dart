enum ReminderType { medicine, glucoseTest, exercise, appointment }

extension ReminderTypeX on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.medicine:
        return 'Medicine';
      case ReminderType.glucoseTest:
        return 'Glucose Test';
      case ReminderType.exercise:
        return 'Exercise';
      case ReminderType.appointment:
        return 'Appointment';
    }
  }

  String get key {
    return name;
  }

  static ReminderType fromKey(String value) {
    return ReminderType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ReminderType.medicine,
    );
  }
}

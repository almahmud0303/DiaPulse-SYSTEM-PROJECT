/// User-configurable settings for emergency glucose handling.
class EmergencySettings {
  static const double defaultLowThreshold = 60;
  static const double defaultHighThreshold = 300;
  static const String defaultEmergencyMessageTemplate =
      'Emergency alert from DiaPulse: glucose level is {glucose} mg/dL ({type}).';

  final bool isEmergencyAlertsEnabled;
  final double lowThreshold;
  final double highThreshold;
  final bool notifyEmergencyContact;
  final bool notifyDoctor;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyMessageTemplate;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const EmergencySettings({
    this.isEmergencyAlertsEnabled = true,
    this.lowThreshold = defaultLowThreshold,
    this.highThreshold = defaultHighThreshold,
    this.notifyEmergencyContact = false,
    this.notifyDoctor = false,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyMessageTemplate = defaultEmergencyMessageTemplate,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  bool get hasValidThresholds => lowThreshold < highThreshold;

  Map<String, dynamic> toMap() {
    return {
      'isEmergencyAlertsEnabled': isEmergencyAlertsEnabled,
      'lowThreshold': lowThreshold,
      'highThreshold': highThreshold,
      'notifyEmergencyContact': notifyEmergencyContact,
      'notifyDoctor': notifyDoctor,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyMessageTemplate': emergencyMessageTemplate,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory EmergencySettings.fromMap(Map<String, dynamic> map) {
    return EmergencySettings(
      isEmergencyAlertsEnabled:
          map['isEmergencyAlertsEnabled'] as bool? ?? true,
      lowThreshold:
          (map['lowThreshold'] as num?)?.toDouble() ?? defaultLowThreshold,
      highThreshold:
          (map['highThreshold'] as num?)?.toDouble() ?? defaultHighThreshold,
      notifyEmergencyContact: map['notifyEmergencyContact'] as bool? ?? false,
      notifyDoctor: map['notifyDoctor'] as bool? ?? false,
      emergencyContactName: map['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] as String? ?? '',
      emergencyMessageTemplate:
          map['emergencyMessageTemplate'] as String? ??
          defaultEmergencyMessageTemplate,
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
    );
  }

  EmergencySettings copyWith({
    bool? isEmergencyAlertsEnabled,
    double? lowThreshold,
    double? highThreshold,
    bool? notifyEmergencyContact,
    bool? notifyDoctor,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyMessageTemplate,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return EmergencySettings(
      isEmergencyAlertsEnabled:
          isEmergencyAlertsEnabled ?? this.isEmergencyAlertsEnabled,
      lowThreshold: lowThreshold ?? this.lowThreshold,
      highThreshold: highThreshold ?? this.highThreshold,
      notifyEmergencyContact:
          notifyEmergencyContact ?? this.notifyEmergencyContact,
      notifyDoctor: notifyDoctor ?? this.notifyDoctor,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyMessageTemplate:
          emergencyMessageTemplate ?? this.emergencyMessageTemplate,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

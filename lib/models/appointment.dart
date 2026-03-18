/// Status of an appointment request.
enum AppointmentStatus {
  requested,
  accepted,
  rejected;

  String get value => name;

  static AppointmentStatus? fromString(String? v) {
    if (v == null) return null;
    switch (v) {
      case 'requested':
        return AppointmentStatus.requested;
      case 'accepted':
        return AppointmentStatus.accepted;
      case 'rejected':
        return AppointmentStatus.rejected;
      default:
        return null;
    }
  }

  String get displayLabel {
    switch (this) {
      case AppointmentStatus.requested:
        return 'Pending';
      case AppointmentStatus.accepted:
        return 'Accepted';
      case AppointmentStatus.rejected:
        return 'Rejected';
    }
  }
}

/// An appointment request from patient to doctor.
class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.status,
    required this.requestedAt,
    this.patientName,
    this.doctorName,
    this.message,
    this.respondedAt,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final AppointmentStatus status;
  final DateTime requestedAt;
  final String? patientName;
  final String? doctorName;
  final String? message;
  final DateTime? respondedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'status': status.value,
      'requestedAt': requestedAt.toIso8601String(),
      if (patientName != null) 'patientName': patientName,
      if (doctorName != null) 'doctorName': doctorName,
      if (message != null && message!.isNotEmpty) 'message': message,
      if (respondedAt != null) 'respondedAt': respondedAt!.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      doctorId: map['doctorId'] as String,
      status: AppointmentStatus.fromString(map['status'] as String?) ??
          AppointmentStatus.requested,
      requestedAt: DateTime.tryParse(map['requestedAt'] as String? ?? '') ??
          DateTime.now(),
      patientName: map['patientName'] as String?,
      doctorName: map['doctorName'] as String?,
      message: map['message'] as String?,
      respondedAt: map['respondedAt'] != null
          ? DateTime.tryParse(map['respondedAt'] as String)
          : null,
    );
  }
}


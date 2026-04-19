import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/appointment.dart';
import 'package:dia_plus/services/notification_service.dart';

/// Service for appointment requests: patient sends, doctor accepts/rejects.
class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'appointments';
  final NotificationService _notificationService = NotificationService();

  /// Patient sends an appointment request to a doctor.
  Future<void> createRequest({
    required String patientId,
    required String doctorId,
    required DateTime preferredConsultationAt,
    String? patientName,
    String? doctorName,
    String? message,
  }) async {
    final id = '${patientId}_${doctorId}_${DateTime.now().millisecondsSinceEpoch}';
    final appointment = Appointment(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      status: AppointmentStatus.requested,
      requestedAt: DateTime.now(),
      preferredConsultationAt: preferredConsultationAt,
      patientName: patientName,
      doctorName: doctorName,
      message: message,
    );
    await _firestore.collection(_collection).doc(id).set(appointment.toMap());

    // Notify doctor in-app.
    await _notificationService.createAppointmentRequestedNotification(
      doctorId: doctorId,
      patientId: patientId,
      appointmentId: id,
      patientName: patientName,
    );
  }

  /// All appointment requests for a doctor (any status), newest first.
  Future<List<Appointment>> getForDoctor(String doctorId) async {
    final snapshot =
        await _firestore.collection(_collection).where('doctorId', isEqualTo: doctorId).get();
    final list =
        snapshot.docs.map((d) => Appointment.fromMap(d.data())).toList();
    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return list;
  }

  /// All appointments for a patient (any status), newest first.
  Future<List<Appointment>> getForPatient(String patientId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .get();
    final list =
        snapshot.docs.map((d) => Appointment.fromMap(d.data())).toList();
    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return list;
  }

  /// Doctor accepts an appointment request.
  Future<void> accept(String appointmentId) async {
    final doc = await _firestore.collection(_collection).doc(appointmentId).get();
    final data = doc.data();
    if (data == null) return;
    final a = Appointment.fromMap(data);
    await _firestore.collection(_collection).doc(appointmentId).update({
      'status': AppointmentStatus.accepted.value,
      'respondedAt': DateTime.now().toIso8601String(),
    });

    // Notify patient in-app.
    await _notificationService.createAppointmentStatusNotification(
      patientId: a.patientId,
      doctorId: a.doctorId,
      appointmentId: appointmentId,
      status: AppointmentStatus.accepted.value,
      doctorName: a.doctorName,
    );
  }

  /// Doctor rejects an appointment request.
  Future<void> reject(String appointmentId) async {
    final doc = await _firestore.collection(_collection).doc(appointmentId).get();
    final data = doc.data();
    if (data == null) return;
    final a = Appointment.fromMap(data);
    await _firestore.collection(_collection).doc(appointmentId).update({
      'status': AppointmentStatus.rejected.value,
      'respondedAt': DateTime.now().toIso8601String(),
    });

    // Notify patient in-app.
    await _notificationService.createAppointmentStatusNotification(
      patientId: a.patientId,
      doctorId: a.doctorId,
      appointmentId: appointmentId,
      status: AppointmentStatus.rejected.value,
      doctorName: a.doctorName,
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/appointment.dart';

/// Service for appointment requests: patient sends, doctor accepts/rejects.
class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'appointments';

  /// Patient sends an appointment request to a doctor.
  Future<void> createRequest({
    required String patientId,
    required String doctorId,
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
      patientName: patientName,
      doctorName: doctorName,
      message: message,
    );
    await _firestore.collection(_collection).doc(id).set(appointment.toMap());
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
    await _firestore.collection(_collection).doc(appointmentId).update({
      'status': AppointmentStatus.accepted.value,
      'respondedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Doctor rejects an appointment request.
  Future<void> reject(String appointmentId) async {
    await _firestore.collection(_collection).doc(appointmentId).update({
      'status': AppointmentStatus.rejected.value,
      'respondedAt': DateTime.now().toIso8601String(),
    });
  }
}


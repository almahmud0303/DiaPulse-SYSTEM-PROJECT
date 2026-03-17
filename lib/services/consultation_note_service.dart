import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/consultation_note.dart';

/// Service for doctor consultation notes and diagnosis (Firestore).
class ConsultationNoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'consultation_notes';

  Future<void> addNote(ConsultationNote note) async {
    await _firestore.collection(_collection).doc(note.id).set(note.toMap());
  }

  Future<void> updateNote(ConsultationNote note) async {
    final updatedAt = DateTime.now();
    await _firestore.collection(_collection).doc(note.id).update({
      'note': note.note,
      'diagnosis': note.diagnosis,
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _firestore.collection(_collection).doc(noteId).delete();
  }

  /// All consultation notes for a patient, newest first.
  Future<List<ConsultationNote>> getNotesForPatient(String patientId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .get();

    final list = snapshot.docs.map((doc) => ConsultationNote.fromMap(doc.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/medicine_entry.dart';
import 'package:dia_plus/models/prescription.dart';

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _medicinesCollection = 'medicines';
  static const String _entriesCollection = 'medicine_entries';
  static const String _prescriptionsCollection = 'prescriptions';

  Future<void> addMedicine(Medicine medicine) async {
    await _firestore
        .collection(_medicinesCollection)
        .doc(medicine.id)
        .set(medicine.toMap());
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _firestore
        .collection(_medicinesCollection)
        .doc(medicine.id)
        .update(medicine.toMap());
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _firestore.collection(_medicinesCollection).doc(medicineId).delete();
  }

  /// Adds medicines into an existing prescription group.
  Future<void> addMedicinesToPrescription({
    required String patientId,
    required String prescriptionId,
    required List<Medicine> medicines,
  }) async {
    if (medicines.isEmpty) return;
    for (final m in medicines) {
      final medWithGroup = Medicine(
        id: m.id,
        userId: m.userId,
        name: m.name,
        dosage: m.dosage,
        time: m.time,
        times: m.times,
        frequency: m.frequency,
        createdAt: m.createdAt,
        prescriptionId: prescriptionId,
        isInsulin: m.isInsulin,
        insulinType: m.insulinType,
        adjustmentInstructions: m.adjustmentInstructions,
      );
      await addMedicine(medWithGroup);
    }
  }

  /// Deletes a whole prescription group and all its medicines.
  Future<void> deletePrescription({
    required String prescriptionId,
    required String patientId,
  }) async {
    // Delete medicines in this prescription (single where; filter by patient in Dart).
    final medsSnap = await _firestore
        .collection(_medicinesCollection)
        .where('prescriptionId', isEqualTo: prescriptionId)
        .get();

    final batch = _firestore.batch();
    for (final doc in medsSnap.docs) {
      final data = doc.data();
      if (data['userId'] == patientId) {
        batch.delete(doc.reference);
      }
    }
    // Delete prescription doc.
    batch.delete(_firestore.collection(_prescriptionsCollection).doc(prescriptionId));
    await batch.commit();
  }

  /// Saves one prescription group (one or more medicines from one save action).
  /// Returns the created [Prescription], or null if medicines was empty.
  Future<Prescription?> addPrescriptionWithMedicines(String patientId, List<Medicine> medicines) async {
    if (medicines.isEmpty) return null;
    final prescriptionId = '${patientId}_rx_${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now();
    final prescription = Prescription(
      id: prescriptionId,
      patientId: patientId,
      createdAt: createdAt,
    );
    await _firestore
        .collection(_prescriptionsCollection)
        .doc(prescriptionId)
        .set(prescription.toMap());
    for (final m in medicines) {
      final medWithGroup = Medicine(
        id: m.id,
        userId: m.userId,
        name: m.name,
        dosage: m.dosage,
        time: m.time,
        times: m.times,
        frequency: m.frequency,
        createdAt: m.createdAt,
        prescriptionId: prescriptionId,
        isInsulin: m.isInsulin,
        insulinType: m.insulinType,
        adjustmentInstructions: m.adjustmentInstructions,
      );
      await addMedicine(medWithGroup);
    }
    return prescription;
  }

  /// Medicines belonging to a prescription group.
  Future<List<Medicine>> getMedicinesForPrescription(String patientId, String prescriptionId) async {
    final snap = await _firestore
        .collection(_medicinesCollection)
        .where('prescriptionId', isEqualTo: prescriptionId)
        .get();
    final list = snap.docs
        .map((d) => Medicine.fromMap(d.data()))
        .where((m) => m.userId == patientId)
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Prescriptions for a patient (newest first).
  Future<List<Prescription>> getPrescriptions(String patientId) async {
    final snapshot = await _firestore
        .collection(_prescriptionsCollection)
        .where('patientId', isEqualTo: patientId)
        .get();
    final list = snapshot.docs
        .map((d) => Prescription.fromMap(d.data()))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<Medicine>> getMedicines(String userId) async {
    final snapshot = await _firestore
        .collection(_medicinesCollection)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snapshot.docs.map((d) => Medicine.fromMap(d.data())).toList();
    int firstDoseMinutes(Medicine m) {
      final mins = m.effectiveTimes
          .map((t) {
            final (h, mm) = Medicine.reminderTimeFrom(t);
            return h * 60 + mm;
          })
          .toList()
        ..sort();
      return mins.isNotEmpty ? mins.first : 0;
    }
    list.sort((a, b) => firstDoseMinutes(a).compareTo(firstDoseMinutes(b)));
    return list;
  }

  /// Real-time stream of medicines for a user.
  Stream<List<Medicine>> getMedicinesStream(String userId) {
    return _firestore
        .collection(_medicinesCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((d) => Medicine.fromMap(d.data())).toList();
      int firstDoseMinutes(Medicine m) {
        final mins = m.effectiveTimes
            .map((t) {
              final (h, mm) = Medicine.reminderTimeFrom(t);
              return h * 60 + mm;
            })
            .toList()
          ..sort();
        return mins.isNotEmpty ? mins.first : 0;
      }
      list.sort((a, b) => firstDoseMinutes(a).compareTo(firstDoseMinutes(b)));
      return list;
    });
  }

  /// Next medicine by time today (for reminder).
  Future<Medicine?> getNextMedicineToday(String userId) async {
    final list = await getMedicines(userId);
    if (list.isEmpty) return null;
    final now = DateTime.now();
    final currentMins = now.hour * 60 + now.minute;
    Medicine? best;
    int? bestMins;
    int? bestMinsTomorrow;
    for (final m in list) {
      final doseMinutes = m.effectiveTimes
          .map((t) {
            final (h, mm) = Medicine.reminderTimeFrom(t);
            return h * 60 + mm;
          })
          .toList();
      if (doseMinutes.isEmpty) continue;
      doseMinutes.sort();
      final nextToday = doseMinutes.firstWhere(
        (mins) => mins >= currentMins,
        orElse: () => -1,
      );
      if (nextToday != -1) {
        if (bestMins == null || nextToday < bestMins) {
          bestMins = nextToday;
          best = m;
        }
      } else {
        final firstTomorrow = doseMinutes.first + 24 * 60;
        if (bestMins == null) {
          if (bestMinsTomorrow == null || firstTomorrow < bestMinsTomorrow) {
            bestMinsTomorrow = firstTomorrow;
            best = m;
          }
        }
      }
    }
    return best ?? list.first;
  }

  Future<void> markTaken({
    required String userId,
    required Medicine medicine,
    required String date,
  }) async {
    final id = '${medicine.id}_$date';
    final entry = MedicineEntry(
      id: id,
      userId: userId,
      medicineId: medicine.id,
      medicineName: medicine.name,
      date: date,
      taken: true,
      takenAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(_entriesCollection)
        .doc(id)
        .set(entry.toMap());
  }

  Future<void> markMissed({
    required String userId,
    required Medicine medicine,
    required String date,
  }) async {
    final id = '${medicine.id}_$date';
    final entry = MedicineEntry(
      id: id,
      userId: userId,
      medicineId: medicine.id,
      medicineName: medicine.name,
      date: date,
      taken: false,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(_entriesCollection)
        .doc(id)
        .set(entry.toMap());
  }

  Future<MedicineEntry?> getEntry(String medicineId, String date) async {
    final id = '${medicineId}_$date';
    final doc = await _firestore.collection(_entriesCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return MedicineEntry.fromMap(doc.data()!);
  }

  Future<List<MedicineEntry>> getEntries(
    String userId, {
    String? fromDate,
    String? toDate,
    bool? takenOnly,
    bool? missedOnly,
  }) async {
    final snapshot = await _firestore
        .collection(_entriesCollection)
        .where('userId', isEqualTo: userId)
        .get();

    var list = snapshot.docs.map((d) => MedicineEntry.fromMap(d.data())).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    if (list.length > 200) list = list.take(200).toList();
    if (fromDate != null) list = list.where((e) => e.date.compareTo(fromDate) >= 0).toList();
    if (toDate != null) list = list.where((e) => e.date.compareTo(toDate) <= 0).toList();
    if (takenOnly == true) list = list.where((e) => e.taken).toList();
    if (missedOnly == true) list = list.where((e) => !e.taken).toList();
    return list;
  }
}

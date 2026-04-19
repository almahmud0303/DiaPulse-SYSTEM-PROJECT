import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/meal_routine.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/medicine_entry.dart';
import 'package:dia_plus/models/prescription.dart';
import 'package:dia_plus/services/meal_routine_service.dart';

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MealRoutineService _mealRoutineService = MealRoutineService();

  static const String _medicinesCollection = 'medicines';
  static const String _entriesCollection = 'medicine_entries';
  static const String _prescriptionsCollection = 'prescriptions';

  Map<String, dynamic> _docMap(DocumentSnapshot d) {
    final data = d.data();
    if (data is Map<String, dynamic>) return Map<String, dynamic>.from(data);
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  Medicine _medicineFromDoc(DocumentSnapshot d) {
    return Medicine.fromMap(_docMap(d), documentId: d.id);
  }

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
        dosageValue: m.dosageValue,
        dosageUnit: m.dosageUnit,
        time: m.time,
        times: m.times,
        frequency: m.frequency,
        createdAt: m.createdAt,
        prescriptionId: prescriptionId,
        isInsulin: m.isInsulin,
        insulinType: m.insulinType,
        adjustmentInstructions: m.adjustmentInstructions,
        mealOffsetMinutes: m.mealOffsetMinutes,
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
  Future<Prescription?> addPrescriptionWithMedicines(
    String patientId,
    List<Medicine> medicines, {
    String? issuedByUid,
    String? issuedByName,
  }) async {
    if (medicines.isEmpty) return null;
    final prescriptionId = '${patientId}_rx_${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now();
    final prescription = Prescription(
      id: prescriptionId,
      patientId: patientId,
      createdAt: createdAt,
      issuedByUid: issuedByUid,
      issuedByName: issuedByName,
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
        dosageValue: m.dosageValue,
        dosageUnit: m.dosageUnit,
        time: m.time,
        times: m.times,
        frequency: m.frequency,
        createdAt: m.createdAt,
        prescriptionId: prescriptionId,
        isInsulin: m.isInsulin,
        insulinType: m.insulinType,
        adjustmentInstructions: m.adjustmentInstructions,
        mealOffsetMinutes: m.mealOffsetMinutes,
      );
      await addMedicine(medWithGroup);
    }
    return prescription;
  }

  /// Medicines belonging to a prescription group (newest-added last).
  ///
  /// Must filter by [patientId] (`userId`) **and** [prescriptionId] so Firestore
  /// security rules can prove every matching doc belongs to the signed-in patient.
  Future<List<Medicine>> getMedicinesForPrescription(String patientId, String prescriptionId) async {
    if (prescriptionId.isEmpty || patientId.isEmpty) return [];
    final snap = await _firestore
        .collection(_medicinesCollection)
        .where('userId', isEqualTo: patientId)
        .where('prescriptionId', isEqualTo: prescriptionId)
        .get();
    var list = snap.docs
        .map(_medicineFromDoc)
        .where((m) => m.userId == patientId && m.id.isNotEmpty)
        .toList();
    // Fallback if query/index mismatch or legacy docs: scan patient's medicines.
    if (list.isEmpty) {
      final all = await getMedicines(patientId);
      list = all
          .where((m) => (m.prescriptionId ?? '') == prescriptionId)
          .toList();
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// All medicines for [patientId] grouped by [Medicine.prescriptionId] (non-null ids only).
  Future<Map<String, List<Medicine>>> getMedicinesGroupedByPrescription(String patientId) async {
    final all = await getMedicines(patientId);
    final map = <String, List<Medicine>>{};
    for (final m in all) {
      final pid = m.prescriptionId;
      if (pid == null || pid.isEmpty) continue;
      map.putIfAbsent(pid, () => []).add(m);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return map;
  }

  /// Prescriptions for a patient (newest first).
  Future<List<Prescription>> getPrescriptions(String patientId) async {
    final snapshot = await _firestore
        .collection(_prescriptionsCollection)
        .where('patientId', isEqualTo: patientId)
        .get();
    final list = snapshot.docs
        .map((d) => Prescription.fromMap(_docMap(d), documentId: d.id))
        .where((p) => p.id.isNotEmpty)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _sortMedicinesByFirstDose(List<Medicine> list, MealRoutine? routine) {
    list.sort(
      (a, b) => Medicine.firstDoseMinutesOf(a, routine).compareTo(
            Medicine.firstDoseMinutesOf(b, routine),
          ),
    );
  }

  Future<List<Medicine>> getMedicines(String userId) async {
    final routine = await _mealRoutineService.getRoutine(userId);
    final snapshot = await _firestore
        .collection(_medicinesCollection)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snapshot.docs.map(_medicineFromDoc).where((m) => m.id.isNotEmpty).toList();
    _sortMedicinesByFirstDose(list, routine);
    return list;
  }

  /// Real-time stream of medicines for a user.
  Stream<List<Medicine>> getMedicinesStream(String userId) {
    return _firestore
        .collection(_medicinesCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final routine = await _mealRoutineService.getRoutine(userId);
      final list =
          snapshot.docs.map(_medicineFromDoc).where((m) => m.id.isNotEmpty).toList();
      _sortMedicinesByFirstDose(list, routine);
      return list;
    });
  }

  /// Next medicine by time today (for reminder).
  Future<Medicine?> getNextMedicineToday(String userId) async {
    final routine = await _mealRoutineService.getRoutine(userId);
    final snapshot = await _firestore
        .collection(_medicinesCollection)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snapshot.docs.map(_medicineFromDoc).where((m) => m.id.isNotEmpty).toList();
    _sortMedicinesByFirstDose(list, routine);
    if (list.isEmpty) return null;
    final now = DateTime.now();
    final currentMins = now.hour * 60 + now.minute;
    Medicine? best;
    int? bestMins;
    int? bestMinsTomorrow;
    for (final m in list) {
      final doseMinutes = m.effectiveTimes
          .map((t) {
            return Medicine.reminderTotalMinutes(t, routine, m.mealOffsetMinutes);
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

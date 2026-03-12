import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/medicine_entry.dart';

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _medicinesCollection = 'medicines';
  static const String _entriesCollection = 'medicine_entries';

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

  Future<List<Medicine>> getMedicines(String userId) async {
    final snapshot = await _firestore
        .collection(_medicinesCollection)
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((d) => Medicine.fromMap(d.data()))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// Next medicine by time today (for reminder).
  Future<Medicine?> getNextMedicineToday(String userId) async {
    final list = await getMedicines(userId);
    if (list.isEmpty) return null;
    final now = DateTime.now();
    final current = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    for (final m in list) {
      if (m.time.compareTo(current) >= 0) return m;
    }
    return list.isNotEmpty ? list.first : null;
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

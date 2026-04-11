import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/meal_routine.dart';

/// Loads and saves the patient's usual meal times under `users/{uid}.mealRoutine`.
class MealRoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MealRoutine?> getRoutine(String userId) async {
    if (userId.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return null;
    final raw = data['mealRoutine'];
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final routine = MealRoutine.fromMap(map);
    return routine.hasAny ? routine : null;
  }

  /// Persists routine; pass empty strings to clear a slot.
  Future<void> saveRoutine(String userId, MealRoutine routine) async {
    await _firestore.collection('users').doc(userId).set(
      {
        'mealRoutine': routine.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

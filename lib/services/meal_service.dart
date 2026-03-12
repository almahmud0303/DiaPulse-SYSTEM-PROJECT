import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/meal.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'meals';

  Future<void> addMeal(Meal meal) async {
    await _firestore.collection(_collection).doc(meal.id).set(meal.toMap());
  }

  Future<void> updateMeal(Meal meal) async {
    await _firestore.collection(_collection).doc(meal.id).update(meal.toMap());
  }

  Future<void> deleteMeal(String mealId) async {
    await _firestore.collection(_collection).doc(mealId).delete();
  }

  /// Get meals for a user in a date range (inclusive). Dates in yyyy-MM-dd.
  /// Filtering by date is done in Dart to avoid composite index.
  Future<List<Meal>> getMeals({
    required String userId,
    String? fromDate,
    String? toDate,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    var list = snapshot.docs.map((d) => Meal.fromMap(d.data())).toList();
    if (fromDate != null) list = list.where((m) => m.date.compareTo(fromDate) >= 0).toList();
    if (toDate != null) list = list.where((m) => m.date.compareTo(toDate) <= 0).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Meals for a single day.
  Future<List<Meal>> getMealsForDay(String userId, String date) async {
    return getMeals(userId: userId, fromDate: date, toDate: date);
  }
}

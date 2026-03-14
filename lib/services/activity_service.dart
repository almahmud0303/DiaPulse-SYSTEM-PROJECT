import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/activity.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'activities';

  Future<void> addActivity(Activity activity) async {
    await _firestore.collection(_collection).doc(activity.id).set(activity.toMap());
  }

  Future<void> updateActivity(Activity activity) async {
    await _firestore.collection(_collection).doc(activity.id).update(activity.toMap());
  }

  Future<void> deleteActivity(String activityId) async {
    await _firestore.collection(_collection).doc(activityId).delete();
  }

  /// Get activities for a user in a date range (inclusive). Dates in yyyy-MM-dd.
  Future<List<Activity>> getActivities({
    required String userId,
    String? fromDate,
    String? toDate,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    var list = snapshot.docs.map((d) => Activity.fromMap(d.data())).toList();
    if (fromDate != null) list = list.where((a) => a.date.compareTo(fromDate) >= 0).toList();
    if (toDate != null) list = list.where((a) => a.date.compareTo(toDate) <= 0).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<List<Activity>> getActivitiesForDay(String userId, String date) async {
    return getActivities(userId: userId, fromDate: date, toDate: date);
  }
}

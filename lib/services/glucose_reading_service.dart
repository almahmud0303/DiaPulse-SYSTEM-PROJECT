import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/glucose_reading.dart';

/// Service for managing glucose readings in Firestore
class GlucoseReadingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'glucose_readings';

  /// Save a new glucose reading to Firestore
  Future<void> saveReading(GlucoseReading reading) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(reading.id)
          .set(reading.toMap());
    } catch (e) {
      throw Exception('Failed to save reading: $e');
    }
  }

  /// Get all readings for a specific user.
  /// Sorted by date descending in Dart to avoid Firestore composite index.
  Future<List<GlucoseReading>> getUserReadings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => GlucoseReading.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      throw Exception('Failed to fetch readings: $e');
    }
  }

  /// Get readings for a specific date range.
  /// Filtering and sort done in Dart to avoid Firestore composite index.
  Future<List<GlucoseReading>> getReadingsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final startStr = startDate.toIso8601String();
      final endStr = endDate.toIso8601String();
      final list = snapshot.docs
          .map((doc) => GlucoseReading.fromMap(doc.data()))
          .where((r) {
            final d = r.date.toIso8601String();
            return d.compareTo(startStr) >= 0 && d.compareTo(endStr) <= 0;
          })
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      throw Exception('Failed to fetch readings: $e');
    }
  }

  /// Delete a reading
  Future<void> deleteReading(String readingId) async {
    try {
      await _firestore.collection(_collection).doc(readingId).delete();
    } catch (e) {
      throw Exception('Failed to delete reading: $e');
    }
  }

  /// Update an existing reading
  Future<void> updateReading(GlucoseReading reading) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(reading.id)
          .update(reading.toMap());
    } catch (e) {
      throw Exception('Failed to update reading: $e');
    }
  }

  /// Stream of user's readings (real-time updates)
  Stream<List<GlucoseReading>> getUserReadingsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final readings = snapshot.docs
              .map((doc) => GlucoseReading.fromMap(doc.data()))
              .toList();
          // Sort on client side to avoid composite index requirement
          readings.sort((a, b) => b.date.compareTo(a.date));
          return readings;
        });
  }

  /// Get readings for today (client-side filter)
  Future<List<GlucoseReading>> getTodayReadings(String userId) async {
    final all = await getUserReadings(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((r) {
      final d = r.date;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).toList();
  }

  /// Get readings for the last 7 days (client-side filter)
  Future<List<GlucoseReading>> getReadingsForLast7Days(String userId) async {
    final all = await getUserReadings(userId);
    final now = DateTime.now();
    final startOf7DaysAgo =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    return all.where((r) => !r.date.isBefore(startOf7DaysAgo)).toList();
  }

  /// Get latest reading for a user.
  /// Uses userId-only query and sorts in Dart to avoid composite index.
  Future<GlucoseReading?> getLatestReading(String userId) async {
    final list = await getLatestReadings(userId, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  /// Get the N most recent readings for a user (for dashboard summary).
  /// Uses userId-only query and sorts in Dart to avoid composite index.
  Future<List<GlucoseReading>> getLatestReadings(String userId, {int limit = 3}) async {
    try {
      final all = await getUserReadings(userId);
      return all.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch latest readings: $e');
    }
  }
}

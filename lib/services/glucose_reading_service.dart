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

  /// Get all readings for a specific user
  Future<List<GlucoseReading>> getUserReadings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GlucoseReading.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch readings: $e');
    }
  }

  /// Get readings for a specific date range
  Future<List<GlucoseReading>> getReadingsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GlucoseReading.fromMap(doc.data()))
          .toList();
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

  /// Get latest reading for a user
  Future<GlucoseReading?> getLatestReading(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return GlucoseReading.fromMap(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to fetch latest reading: $e');
    }
  }
}

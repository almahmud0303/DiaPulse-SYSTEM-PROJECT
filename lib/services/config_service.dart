import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_config_item.dart';

/// User-facing read-only service for dynamic app configuration.
///
/// Streams active config items from `app_config/{collection}` sub-collections.
/// Includes in-memory caching to reduce Firestore reads: the first call for a
/// given collection opens a real-time listener, and subsequent calls reuse the
/// cached stream. The cache is automatically refreshed by the listener.
class ConfigService {
  ConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// In-memory stream cache keyed by collection name.
  final Map<String, Stream<List<AppConfigItem>>> _cache = {};

  static const String _root = 'app_config';

  // ── Public collection keys ───────────────────────────────────────────

  static const String mealCategories = 'meal_categories';
  static const String activityTypes = 'activity_types';
  static const String mealTimes = 'meal_times';
  static const String diabetesEssentials = 'diabetes_essentials';

  // ── Convenience getters ──────────────────────────────────────────────

  /// Active meal categories (e.g. Breakfast, Lunch, Dinner, Snack).
  Stream<List<AppConfigItem>> getMealCategories() => _stream(mealCategories);

  /// Active activity/exercise types (e.g. Walking, Running, Cycling).
  Stream<List<AppConfigItem>> getActivityTypes() => _stream(activityTypes);

  /// Active meal-time labels for glucose readings (e.g. Fasting, Before meal).
  Stream<List<AppConfigItem>> getMealTimes() => _stream(mealTimes);

  /// Active diabetes essentials content (educational tips, thresholds).
  Stream<List<AppConfigItem>> getDiabetesEssentials() =>
      _stream(diabetesEssentials);

  // ── One-shot fetch (for rare non-streaming usage) ────────────────────

  /// Fetches active items once (no real-time updates).
  Future<List<AppConfigItem>> fetchOnce(String collection) async {
    final snap = await _firestore
        .collection(_root)
        .doc(collection)
        .collection('items')
        .orderBy('order')
        .get();
    return snap.docs
        .map((d) => AppConfigItem.fromMap(d.id, d.data()))
        .where((item) => item.isActive)
        .toList();
  }

  // ── Internal ─────────────────────────────────────────────────────────

  /// Returns a broadcast stream of active items for [collection], cached.
  Stream<List<AppConfigItem>> _stream(String collection) {
    return _cache.putIfAbsent(collection, () {
      return _firestore
          .collection(_root)
          .doc(collection)
          .collection('items')
          .orderBy('order')
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => AppConfigItem.fromMap(d.id, d.data()))
                .where((item) => item.isActive)
                .toList(),
          )
          .asBroadcastStream();
    });
  }
}

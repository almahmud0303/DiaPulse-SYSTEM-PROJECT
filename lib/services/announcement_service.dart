import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/announcement.dart';

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String announcementsCollection = 'announcements';

  /// Published feed for the signed-in user's role.
  ///
  /// Uses only `where('published' == true)` so no composite index is required (unlike
  /// `orderBy('publishedAt')`, which breaks until an index exists). Sorting is done here.
  static bool _visibleForRole(Announcement a, String roleLower) {
    final t = a.targetRole?.trim();
    if (t == null || t.isEmpty) return true;
    final tl = t.toLowerCase();
    if (tl == 'all' || tl == 'everyone') return true;
    return tl == roleLower;
  }

  Stream<List<Announcement>> streamPublished({required String role}) {
    final roleLower = role.toLowerCase().trim();
    return _firestore
        .collection(announcementsCollection)
        .where('published', isEqualTo: true)
        .limit(200)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Announcement.fromMap(d.id, d.data()))
          .where((a) => _visibleForRole(a, roleLower))
          .toList()
        ..sort((a, b) {
          final da = a.publishedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.publishedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      return list;
    });
  }

  CollectionReference<Map<String, dynamic>> _readsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('announcement_reads');
  }

  Stream<Set<String>> streamReadAnnouncementIds(String uid) {
    return _readsRef(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }

  Future<void> markRead({
    required String uid,
    required String announcementId,
  }) async {
    await _readsRef(uid).doc(announcementId).set({
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> streamUnreadCount({
    required String uid,
    required String role,
  }) {
    return streamPublished(role: role).asyncMap((announcements) async {
      // Convert reads snapshot to a set (single read per change).
      final readsSnap = await _readsRef(uid).get();
      final readIds = readsSnap.docs.map((d) => d.id).toSet();
      return announcements.where((a) => !readIds.contains(a.id)).length;
    });
  }
}


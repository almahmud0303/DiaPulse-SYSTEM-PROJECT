import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/announcement.dart';

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String announcementsCollection = 'announcements';

  /// Client-side feed. Pulls latest published announcements and filters by role in Dart
  /// to support legacy docs where `targetRole` might be null.
  Stream<List<Announcement>> streamPublished({required String role}) {
    return _firestore
        .collection(announcementsCollection)
        .where('published', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Announcement.fromMap(d.id, d.data()))
          .where((a) {
        final t = a.targetRole;
        if (t == null || t.isEmpty) return true; // legacy: treat as all
        if (t == 'all') return true;
        return t == role;
      }).toList();
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


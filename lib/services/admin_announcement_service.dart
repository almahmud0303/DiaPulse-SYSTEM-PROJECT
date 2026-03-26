import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/announcement.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAnnouncementService {
  AdminAnnouncementService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String collectionName = 'announcements';

  Stream<List<Announcement>> watchAll() {
    return _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Announcement.fromMap(d.id, d.data())).toList());
  }

  Future<void> create({
    required String title,
    required String body,
    String? targetRole,
    bool published = true,
  }) async {
    final uid = _auth.currentUser?.uid;
    await _firestore.collection(collectionName).add({
      'title': title.trim(),
      'body': body.trim(),
      'targetRole': targetRole?.trim().isEmpty == true ? null : targetRole?.trim(),
      'published': published,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (published) 'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String body,
    String? targetRole,
  }) async {
    await _firestore.collection(collectionName).doc(id).update({
      'title': title.trim(),
      'body': body.trim(),
      'targetRole': targetRole?.trim().isEmpty == true ? null : targetRole?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setPublished({
    required String id,
    required bool published,
  }) async {
    await _firestore.collection(collectionName).doc(id).update({
      'published': published,
      'updatedAt': FieldValue.serverTimestamp(),
      if (published) 'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }
}

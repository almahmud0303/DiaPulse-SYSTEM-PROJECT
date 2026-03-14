import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Updates patient profile fields in Firestore users collection.
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Update patient profile. Only provided fields are updated.
  Future<void> updatePatientProfile(String uid, {
    String? displayName,
    int? age,
    double? weight,
    double? height,
    String? diabetesType,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) data['displayName'] = displayName;
    if (age != null) data['age'] = age;
    if (weight != null) data['weight'] = weight;
    if (height != null) data['height'] = height;
    if (diabetesType != null) data['diabetesType'] = diabetesType;

    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
    if (displayName != null) {
      await _auth.currentUser?.updateProfile(displayName: displayName);
    }
  }
}

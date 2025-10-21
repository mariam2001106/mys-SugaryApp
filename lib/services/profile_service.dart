import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> createIfMissing(String uid) async {
    final ref = _userDoc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(UserProfile.initial(uid).toMap(), SetOptions(merge: true));
    }
  }

  Stream<UserProfile?> streamProfile(String uid) {
    return _userDoc(uid).snapshots().map((s) {
      if (!s.exists) return null;
      return UserProfile.fromDoc(s);
    });
  }

  Future<void> updatePartial(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _userDoc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> completeOnboarding(String uid) async {
    await updatePartial(uid, {'onboardingComplete': true});
  }
}

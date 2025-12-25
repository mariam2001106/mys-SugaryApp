import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Creates an initial profile document if missing, with defensive defaults.
  Future<void> createIfMissing(String uid) async {
    final ref = _userDoc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final initial = UserProfile.initial(uid).toMap();
      initial['onboardingComplete'] = false;
      initial['onboardingStep'] = 0;
      initial['locale'] = 'ar';
      initial['createdAt'] = FieldValue.serverTimestamp();
      initial['updatedAt'] = FieldValue.serverTimestamp();
      await ref.set(initial, SetOptions(merge: true));
    }
  }

  /// Get the user doc (default get - with persistence disabled this is server).
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _userDoc(uid).get();
  }

  /// Force reading the document from the SERVER explicitly.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocFromServer(
    String uid,
  ) {
    return _userDoc(uid).get(GetOptions(source: Source.server));
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

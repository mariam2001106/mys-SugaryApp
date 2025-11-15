import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Creates an initial profile document if missing.
  /// Throws on failure so callers can observe the exact exception.
  Future<void> createIfMissing(String uid) async {
    try {
      final ref = _userDoc(uid);
      final snap = await ref.get();
      if (!snap.exists) {
        final initial = UserProfile.initial(uid).toMap();
        // Use server timestamps for createdAt/updatedAt
        initial['createdAt'] = FieldValue.serverTimestamp();
        initial['updatedAt'] = FieldValue.serverTimestamp();
        await ref.set(initial, SetOptions(merge: true));
        // ignore: avoid_print
        print('[ProfileService] Created users/$uid');
      } else {
        // ignore: avoid_print
        print('[ProfileService] users/$uid already exists');
      }
    } on FirebaseException catch (e, st) {
      // ignore: avoid_print
      print('[ProfileService] FirebaseException in createIfMissing: ${e.code} ${e.message}');
      // ignore: avoid_print
      print(st);
      rethrow;
    } catch (e, st) {
      // ignore: avoid_print
      print('[ProfileService] Unknown error in createIfMissing: $e');
      // ignore: avoid_print
      print(st);
      rethrow;
    }
  }

  Stream<UserProfile?> streamProfile(String uid) {
    // Log snapshot errors so StreamBuilder can surface them
    return _userDoc(uid)
        .snapshots()
        .handleError((e, st) {
          // ignore: avoid_print
          print('[ProfileService] streamProfile error: $e');
          // ignore: avoid_print
          print(st);
        })
        .map((s) {
      if (!s.exists) return null;
      try {
        return UserProfile.fromDoc(s);
      } catch (e, st) {
        // ignore: avoid_print
        print('[ProfileService] Failed to parse profile doc: $e');
        // ignore: avoid_print
        print(st);
        return null;
      }
    });
  }

  Future<void> updatePartial(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _userDoc(uid).set(data, SetOptions(merge: true));
      // ignore: avoid_print
      print('[ProfileService] Updated users/$uid with: $data');
    } on FirebaseException catch (e, st) {
      // ignore: avoid_print
      print('[ProfileService] FirebaseException in updatePartial: ${e.code} ${e.message}');
      // ignore: avoid_print
      print(st);
      rethrow;
    } catch (e, st) {
      // ignore: avoid_print
      print('[ProfileService] Unknown error in updatePartial: $e');
      // ignore: avoid_print
      print(st);
      rethrow;
    }
  }

  Future<void> completeOnboarding(String uid) async {
    await updatePartial(uid, {'onboardingComplete': true});
    // ignore: avoid_print
    print('[ProfileService] Completed onboarding for $uid');
  }
}

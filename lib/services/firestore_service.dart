import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save initial health setup to user doc
  Future<void> saveHealthSetup(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Add glucose entry
  Future<void> addGlucose(
    String uid,
    num value,
    DateTime timestamp,
    String context, {
    String? note,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .doc();
    await docRef.set({
      'value': value,
      'unit': 'mg/dL',
      'timestamp': Timestamp.fromDate(timestamp.toUtc()),
      'context': context,
      'note': note ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Query latest readings
  Stream<QuerySnapshot> glucoseStream(String uid, {int limit = 50}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}

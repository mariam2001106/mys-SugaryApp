import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mysugaryapp/models/glucose_entry_model.dart';

class GlucoseService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addEntry({
    required num value,
    required DateTime timestamp,
    required GlucoseContext context,
    String? note,
    String unit = 'mg/dL',
  }) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    final doc = _db
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .doc();
    await doc.set({
      'value': value,
      'unit': unit,
      'timestamp': Timestamp.fromDate(timestamp.toUtc()),
      'context': context.name,
      'note': note ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEntry(
    String id, {
    num? value,
    DateTime? timestamp,
    GlucoseContext? context,
    String? note,
    String? unit,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final updateData = <String, dynamic>{
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp.toUtc()),
      if (context != null) 'context': context.name,
      if (note != null) 'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (updateData.length <= 1) {
      return; // only updatedAt without other fields is pointless
    }

    await _db
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .doc(id)
        .update(updateData);
  }

  Future<void> deleteEntry(String id) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }

    await _db
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .doc(id)
        .delete();
  }

  Stream<List<GlucoseEntry>> recentStream({int limit = 30}) {
    final uid = _uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(GlucoseEntry.fromDoc).toList());
  }

  Stream<List<GlucoseEntry>> rangeStream({int days = 30, int? hours}) {
    final uid = _uid;
    if (uid == null) {
      return const Stream.empty();
    }
    final since = (hours != null)
        ? DateTime.now().toUtc().subtract(Duration(hours: hours))
        : DateTime.now().toUtc().subtract(Duration(days: days));
    return _db
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(GlucoseEntry.fromDoc).toList());
  }

  Future<Map<String, int>?> fetchUserTargets() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final d = doc.data() ?? {};
    return {
      'veryHigh': (d['veryHigh'] as num?)?.toInt() ?? 180,
      'targetMin': (d['targetMin'] as num?)?.toInt() ?? 80,
      'targetMax': (d['targetMax'] as num?)?.toInt() ?? 130,
      'veryLow': (d['veryLow'] as num?)?.toInt() ?? 70,
    };
  }
}

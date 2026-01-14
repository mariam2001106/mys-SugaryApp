import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mysugaryapp/models/reminder_models.dart' as rem; // ReminderItemDto, ReminderType
import 'package:mysugaryapp/models/medicationreminder_model.dart'; // MedicationReminder, GlucoseCheckReminder

class ReminderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _itemsCol(String uid) =>
      _userDoc(uid).collection('reminders').doc('items').collection('list');

  // Doc-per-reminder CRUD (with IDs)
  Future<List<rem.ReminderItemDto>> listReminders(String uid) async {
    final snap = await _itemsCol(
      uid,
    ).orderBy('createdAt', descending: false).get();
    return snap.docs.map(rem.ReminderItemDto.fromDoc).toList();
  }

  Future<String> addReminder(String uid, rem.ReminderItemDto dto) async {
    final ref = await _itemsCol(uid).add(dto.toMap());
    return ref.id;
  }

  Future<void> updateReminder(String uid, rem.ReminderItemDto dto) async {
    await _itemsCol(uid).doc(dto.id).update(dto.toMap());
  }

  Future<void> deleteReminder(String uid, String id) async {
    await _itemsCol(uid).doc(id).delete();
  }

  // SmartAssist flags
  Future<bool> isSmartAssistComplete(String uid) async {
    final doc = await _userDoc(
      uid,
    ).get(const GetOptions(source: Source.server));
    return (doc.data()?['smartAssistComplete'] ?? false) as bool;
  }

  Future<void> setSmartAssistComplete(String uid, {bool value = true}) async {
    await _userDoc(uid).set({
      'smartAssistComplete': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Legacy array-based helpers (used by SmartAssist)
  Future<void> addMedicationReminder(String uid, MedicationReminder r) async {
    await _userDoc(uid).collection('reminders').doc('medications').set({
      'items': FieldValue.arrayUnion([r.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setGlucoseReminders(
    String uid,
    List<GlucoseCheckReminder> reminders,
  ) async {
    await _userDoc(uid).collection('reminders').doc('glucose_checks').set({
      'items': reminders.map((r) => r.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<MedicationReminder>> getMedicationReminders(String uid) async {
    final snap = await _userDoc(uid)
        .collection('reminders')
        .doc('medications')
        .get(const GetOptions(source: Source.server));
    final data = snap.data();
    final items = (data?['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(MedicationReminder.fromMap)
        .toList();
  }

  Future<List<GlucoseCheckReminder>> getGlucoseReminders(String uid) async {
    final snap = await _userDoc(uid)
        .collection('reminders')
        .doc('glucose_checks')
        .get(const GetOptions(source: Source.server));
    final data = snap.data();
    final items = (data?['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(GlucoseCheckReminder.fromMap)
        .toList();
  }
}

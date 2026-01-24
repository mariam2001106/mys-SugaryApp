import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mysugaryapp/models/reminder_models.dart'
    as rem; // ReminderItemDto, ReminderType
import 'package:mysugaryapp/services/notification_service.dart'; // MedicationReminder, GlucoseCheckReminder

final FirebaseFirestore _db = FirebaseFirestore.instance;

class ReminderService {
  final NotificationsService _notifier = NotificationsService();

  Future<List<rem.ReminderItemDto>> listReminders(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .doc('items')
        .collection('list')
        .orderBy('time')
        .get();

    // Return a growable list so the UI can add/remove items safely.
    return snapshot.docs.map((d) => rem.ReminderItemDto.fromDoc(d)).toList();
  }

  /// Adds a reminder document and schedules notification.
  Future<String> addReminder(String uid, rem.ReminderItemDto dto) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .doc('items')
        .collection('list')
        .doc();

    await docRef.set(dto.toMap());

    final id = docRef.id;
    final created = dto.copyWith(id: id);

    return id;
  }

  /// Updates an existing reminder document and (re)schedules notification.
  Future<void> updateReminder(String uid, rem.ReminderItemDto dto) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .doc('items')
        .collection('list')
        .doc(dto.id);

    await docRef.set(dto.toMap(), SetOptions(merge: true));

    // No notification logic here; handled by NotificationsService
  }

  /// Deletes the reminder document and cancels its scheduled notification.
  Future<void> deleteReminder(String uid, String id) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .doc('items')
        .collection('list')
        .doc(id);

    await docRef.delete();

    // No notification logic here; handled by NotificationsService
  }
}

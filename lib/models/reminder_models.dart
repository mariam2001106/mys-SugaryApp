import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType { medication, glucose, appointment }

class ReminderItemDto {
  ReminderItemDto({
    required this.id,
    required this.type,
    required this.title,
    required this.time, // "08:00"
    required this.frequency, // e.g., "reminders.freq_daily"
    required this.enabled,
  });

  final String id;
  final ReminderType type;
  final String title;
  final String time;
  final String frequency;
  final bool enabled;

  ReminderItemDto copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? time,
    String? frequency,
    bool? enabled,
  }) {
    return ReminderItemDto(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'title': title,
    'time': time,
    'frequency': frequency,
    'enabled': enabled,
    'createdAt': DateTime.now().toIso8601String(),
  };

  static ReminderType _typeFromKey(String? k) {
    switch (k) {
      case 'glucose':
        return ReminderType.glucose;
      case 'appointment':
        return ReminderType.appointment;
      case 'medication':
      default:
        return ReminderType.medication;
    }
  }

  static ReminderItemDto fromMap(String id, Map<String, dynamic> d) {
    return ReminderItemDto(
      id: id,
      type: _typeFromKey(d['type'] as String?),
      title: d['title'] as String? ?? '',
      time: d['time'] as String? ?? '',
      frequency: d['frequency'] as String? ?? 'reminders.freq_daily',
      enabled: (d['enabled'] as bool?) ?? true,
    );
  }

  static ReminderItemDto fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return fromMap(doc.id, d);
  }
}

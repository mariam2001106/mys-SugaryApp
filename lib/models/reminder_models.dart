import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType { medication, glucose, appointment }

enum ReminderFrequency { daily, weekly, monthly }

class ReminderItemDto {
  ReminderItemDto({
    required this.id,
    required this.type,
    required this.title,
    required this.time, // "08:00"
    required this.frequency, // periodic frequency
    required this.enabled,
  });

  final String id;
  final ReminderType type;
  final String title;
  final String time;
  final ReminderFrequency frequency;
  final bool enabled;

  ReminderItemDto copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? time,
    ReminderFrequency? frequency,
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
    'frequency': frequency.name, // store as "daily" | "weekly" | "monthly"
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
      frequency: _freqFromKey(d['frequency'] as String?),
      enabled: (d['enabled'] as bool?) ?? true,
    );
  }

  static ReminderItemDto fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return fromMap(doc.id, d);
  }

  static ReminderFrequency _freqFromKey(String? k) {
    switch (k) {
      case 'weekly':
      case 'reminders.freq_weekly':
        return ReminderFrequency.weekly;
      case 'monthly':
      case 'reminders.freq_monthly':
        return ReminderFrequency.monthly;
      case 'daily':
      case 'reminders.freq_daily':
      default:
        return ReminderFrequency.daily;
    }
  }
}

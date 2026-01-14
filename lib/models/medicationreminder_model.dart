import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationReminder {
  final String name;
  final String unit;
  final String time; // formatted, e.g. "08:00"
  final DateTime createdAt;

  MedicationReminder({
    required this.name,
    required this.unit,
    required this.time,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'name': name,
    'unit': unit,
    'time': time,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory MedicationReminder.fromMap(Map<String, dynamic> m) {
    return MedicationReminder(
      name: m['name'] as String? ?? '',
      unit: m['unit'] as String? ?? '',
      time: m['time'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class GlucoseCheckReminder {
  final String label;
  final String time; // formatted, e.g. "07:00"
  final DateTime createdAt;

  GlucoseCheckReminder({
    required this.label,
    required this.time,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'label': label,
    'time': time,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory GlucoseCheckReminder.fromMap(Map<String, dynamic> m) {
    return GlucoseCheckReminder(
      label: m['label'] as String? ?? '',
      time: m['time'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

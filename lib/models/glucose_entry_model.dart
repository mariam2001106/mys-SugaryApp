import 'package:cloud_firestore/cloud_firestore.dart';

enum GlucoseContext {
  fasting,
  beforeMeal,
  afterMeal,
  beforeSleep,
  afterExercise,
  duringStress,
  whenSick,
  other,
}

class GlucoseEntry {
  GlucoseEntry({
    required this.id,
    required this.value,
    required this.timestamp,
    required this.context,
    this.note = '',
    this.unit = 'mg/dL',
  });

  final String id;
  final num value;
  final DateTime
  timestamp; // stored UTC in Firestore; convert to local when displaying
  final GlucoseContext context;
  final String note;
  final String unit;

  GlucoseEntry copyWith({
    String? id,
    num? value,
    DateTime? timestamp,
    GlucoseContext? context,
    String? note,
    String? unit,
  }) {
    return GlucoseEntry(
      id: id ?? this.id,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      note: note ?? this.note,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() => {
    'value': value,
    'unit': unit,
    'timestamp': Timestamp.fromDate(timestamp.toUtc()),
    'context': context.name,
    'note': note,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static GlucoseContext _ctxFrom(String? s) {
    return GlucoseContext.values.firstWhere(
      (c) => c.name == s,
      orElse: () => GlucoseContext.other,
    );
  }

  static GlucoseEntry fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts =
        (d['timestamp'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now();
    return GlucoseEntry(
      id: doc.id,
      value: d['value'] as num? ?? 0,
      unit: d['unit'] as String? ?? 'mg/dL',
      timestamp: ts,
      context: _ctxFrom(d['context'] as String?),
      note: d['note'] as String? ?? '',
    );
  }
}

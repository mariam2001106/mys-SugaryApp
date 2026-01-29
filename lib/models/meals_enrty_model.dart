import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType { breakfast, lunch, dinner, snack, other }

class MealEntry {
  final String id;
  final String name; // meal name or description (e.g., "Chicken Salad")
  final MealType type;
  final DateTime
  timestamp; // stored in UTC in Firestore; convert to local when displaying
  final num totalCarbs; // derived total carbs of all items (grams)
  final num? totalCalories; // derived total calories (optional)
  final num? insulinUnitsSuggested; // carbs / carbRatio (if ratio is available)
  final String? note;

  final DateTime createdAt;
  final DateTime updatedAt;

  const MealEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.timestamp,
    required this.totalCarbs,
    this.totalCalories,
    this.insulinUnitsSuggested,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  MealEntry copyWith({
    String? id,
    String? name,
    MealType? type,
    DateTime? timestamp,
    num? totalCarbs,
    num? totalCalories,
    num? insulinUnitsSuggested,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalCalories: totalCalories ?? this.totalCalories,
      insulinUnitsSuggested:
          insulinUnitsSuggested ?? this.insulinUnitsSuggested,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'timestamp': Timestamp.fromDate(timestamp.toUtc()),
    'totalCarbs': totalCarbs,
    'totalCalories': totalCalories,
    'insulinUnitsSuggested': insulinUnitsSuggested,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static MealType _mealTypeFromString(String? v) {
    switch (v) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
        return MealType.snack;
      default:
        return MealType.other;
    }
  }

  factory MealEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    return MealEntry(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      type: _mealTypeFromString(d['type'] as String?),
      timestamp:
          (d['timestamp'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      totalCarbs: (d['totalCarbs'] ?? 0) as num,
      totalCalories: d['totalCalories'] == null
          ? null
          : (d['totalCalories'] as num),
      insulinUnitsSuggested: d['insulinUnitsSuggested'] == null
          ? null
          : (d['insulinUnitsSuggested'] as num),
      note: d['note'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

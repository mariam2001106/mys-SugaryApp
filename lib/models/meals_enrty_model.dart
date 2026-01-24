import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType { breakfast, lunch, dinner, snack, other }

class FoodItem {
  final String name;
  final num carbsGrams; // grams of carbs for the specified quantity
  final num? calories; // optional calories for the specified quantity
  final num
  quantity; // user-specified quantity for this item (e.g., 1 cup, 2 slices)
  final String? unit; // optional display unit (cup, slice, tbsp, etc.)

  const FoodItem({
    required this.name,
    required this.carbsGrams,
    required this.quantity,
    this.calories,
    this.unit,
  });

  FoodItem copyWith({
    String? name,
    num? carbsGrams,
    num? calories,
    num? quantity,
    String? unit,
  }) {
    return FoodItem(
      name: name ?? this.name,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      calories: calories ?? this.calories,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'carbsGrams': carbsGrams,
    'calories': calories,
    'quantity': quantity,
    'unit': unit,
  };

  factory FoodItem.fromMap(Map<String, dynamic> m) {
    return FoodItem(
      name: (m['name'] ?? '') as String,
      carbsGrams: (m['carbsGrams'] ?? 0) as num,
      calories: m['calories'] == null ? null : (m['calories'] as num),
      quantity: (m['quantity'] ?? 1) as num,
      unit: m['unit'] as String?,
    );
  }
}

class MealEntry {
  final String id;
  final String name; // meal name or description (e.g., "Chicken Salad")
  final MealType type;
  final DateTime
  timestamp; // stored in UTC in Firestore; convert to local when displaying
  final List<FoodItem> items;
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
    required this.items,
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
    List<FoodItem>? items,
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
      items: items ?? this.items,
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
    'items': items.map((i) => i.toMap()).toList(),
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
    final itemsList = (d['items'] as List?) ?? const [];
    return MealEntry(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      type: _mealTypeFromString(d['type'] as String?),
      timestamp:
          (d['timestamp'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      items: itemsList
          .map((e) => FoodItem.fromMap(e as Map<String, dynamic>))
          .toList(),
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

  /// Utility to derive totals from items list.
  static ({num carbs, num? calories}) deriveTotals(List<FoodItem> items) {
    num carbs = 0;
    num? calories;
    for (final i in items) {
      carbs += i.carbsGrams;
      if (i.calories != null) {
        calories = (calories ?? 0) + i.calories!;
      }
    }
    return (carbs: carbs, calories: calories);
  }
}

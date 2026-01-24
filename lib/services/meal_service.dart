import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mysugaryapp/models/meals_enrty_model.dart';

/// Service for meal logging and retrieval.
/// Storage layout:
/// users/{uid}/meals/logs/{mealId}
/// Optional: users/{uid}/meals/common/{foodId} for common foods (if you add UI)
class MealService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Create a meal log and compute insulin suggestion if carbRatio exists.
  /// carbRatio is "grams per insulin unit". InsulinUnits = totalCarbs / carbRatio.
  Future<String?> addMeal({
    required String name,
    required MealType type,
    required DateTime timestamp,
    required List<FoodItem> items,
    String? note,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    final totals = MealEntry.deriveTotals(items);
    final carbRatio = await _fetchCarbRatio(uid); // dynamic; no fallback default

    num? insulinUnits;
    if (carbRatio != null && carbRatio > 0) {
      insulinUnits = totals.carbs / carbRatio;
    }

    final ref = _db.collection('users').doc(uid).collection('meals').doc('logs').collection('list').doc();
    final entry = MealEntry(
      id: ref.id,
      name: name,
      type: type,
      timestamp: timestamp,
      items: items,
      totalCarbs: totals.carbs,
      totalCalories: totals.calories,
      insulinUnitsSuggested: insulinUnits,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.set(entry.toMap());
    return ref.id;
  }

  Future<void> updateMeal(MealEntry entry) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc('logs')
        .collection('list')
        .doc(entry.id);

    final data = entry.copyWith(updatedAt: DateTime.now()).toMap();
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> deleteMeal(String id) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc('logs')
        .collection('list')
        .doc(id);

    await ref.delete();
  }

  /// Stream meals within a time range (hours or days).
  Stream<List<MealEntry>> rangeStream({int days = 30, int? hours}) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    final sinceUtc = (hours != null)
        ? DateTime.now().toUtc().subtract(Duration(hours: hours))
        : DateTime.now().toUtc().subtract(Duration(days: days));

    return _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc('logs')
        .collection('list')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sinceUtc))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MealEntry.fromDoc).toList());
  }

  /// Recent meals stream (limit N).
  Stream<List<MealEntry>> recentStream({int limit = 20}) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc('logs')
        .collection('list')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(MealEntry.fromDoc).toList());
  }

  /// Attempt to read carb-to-insulin ratio from user doc.
  /// Expected locations:
  /// - users/{uid}.insulinSettings.carbRatio
  /// - users/{uid}.carbRatio (legacy/simple)
  ///
  /// Returns null if not set (no hardcoded default).
  Future<num?> _fetchCarbRatio(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final d = doc.data() ?? {};

    // Try nested map "insulinSettings": { carbRatio: num }
    final settings = d['insulinSettings'];
    if (settings is Map<String, dynamic>) {
      final r = settings['carbRatio'];
      if (r is num) return r;
    }

    // Fallback to top-level "carbRatio" if present
    final r2 = d['carbRatio'];
    if (r2 is num) return r2;

    return null;
  }

  // Optional: common foods helpers (if you store a user-specific common foods list)
  Future<void> upsertCommonFood({
    required String name,
    required num carbsGrams,
    num? calories,
    String? unit,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final col = _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc('common')
        .collection('foods');

    final ref = col.doc(name.trim().toLowerCase().replaceAll(' ', '_'));
    await ref.set({
      'name': name,
      'carbsGrams': carbsGrams,
      'calories': calories,
      'unit': unit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<FoodItem>> commonFoodsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc('common')
        .collection('foods')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              return FoodItem.fromMap(m);
            }).toList());
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mysugaryapp/models/meals_enrty_model.dart';

/// Service for meal logging and retrieval.
/// Storage layout:
/// users/{uid}/meals/logs/{mealId}
class MealService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Create a meal log and compute insulin suggestion if carbRatio exists.
  /// carbRatio is "grams per insulin unit". InsulinUnits = totalCarbs / carbRatio.
  /// If items list is empty, use direct carbs/calories values.
  /// Returns a map with 'id' and 'insulinUnits' keys.
  Future<Map<String, dynamic>?> addMeal({
    required String name,
    required MealType type,
    required DateTime timestamp,
    num? directCarbs,
    num? directCalories,
    String? note,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    // Use direct values if provided, otherwise derive from items

    num totalCarbs;
    num? totalCalories;

    totalCarbs = directCarbs ?? 0;
    totalCalories = directCalories;

    final carbRatio = await _fetchCarbRatio(
      uid,
    ); // dynamic; no fallback default

    num? insulinUnits;
    if (carbRatio != null && carbRatio > 0 && totalCarbs > 0) {
      insulinUnits = totalCarbs / carbRatio;
    }

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc('logs')
        .collection('list')
        .doc();
    final entry = MealEntry(
      id: ref.id,
      name: name,
      type: type,
      timestamp: timestamp,

      totalCarbs: totalCarbs,
      totalCalories: totalCalories,
      insulinUnitsSuggested: insulinUnits,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.set(entry.toMap());
    return {
      'id': ref.id,
      'insulinUnits': insulinUnits,
      'totalCarbs': totalCarbs,
    };
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
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sinceUtc),
        )
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
}

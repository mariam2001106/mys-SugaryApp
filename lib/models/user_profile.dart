import 'package:cloud_firestore/cloud_firestore.dart';

enum DiabetesType { type1, type2, lada, type3, other }

enum InsulinMethod { penSyringe, pump, none }

enum MedTime { morning, afternoon, evening, night, other }

class GlucoseRanges {
  final int veryHigh;
  final int targetMin;
  final int targetMax;
  final int veryLow;

  const GlucoseRanges({
    required this.veryHigh,
    required this.targetMin,
    required this.targetMax,
    required this.veryLow,
  });

  Map<String, dynamic> toMap() => {
    'veryHigh': veryHigh,
    'targetMin': targetMin,
    'targetMax': targetMax,
    'veryLow': veryLow,
  };

  factory GlucoseRanges.fromMap(Map<String, dynamic>? m) {
    final d = m ?? {};
    return GlucoseRanges(
      veryHigh: (d['veryHigh'] ?? 250) as int,
      targetMin: (d['targetMin'] ?? 80) as int,
      targetMax: (d['targetMax'] ?? 130) as int,
      veryLow: (d['veryLow'] ?? 60) as int,
    );
  }
}

class UserProfile {
  final String uid;
  final String? displayName;
  final DiabetesType diabetesType;
  final bool takesPills;
  final InsulinMethod insulinMethod;
  final DateTime? dateOfBirth;
  final int? age;
  final String? medicationName;
  final List<MedTime> medicationTimes;
  final GlucoseRanges glucoseRanges;
  final bool onboardingComplete;
  final int onboardingStep;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    this.displayName,
    required this.diabetesType,
    required this.takesPills,
    required this.insulinMethod,
    required this.dateOfBirth,
    required this.age,
    this.medicationName,
    required this.medicationTimes,
    required this.glucoseRanges,
    required this.onboardingComplete,
    required this.onboardingStep,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.initial(String uid) => UserProfile(
    uid: uid,
    displayName: null,
    diabetesType: DiabetesType.other,
    takesPills: false,
    insulinMethod: InsulinMethod.none,
    dateOfBirth: null,
    age: null,
    medicationName: null,
    medicationTimes: const [],
    glucoseRanges: const GlucoseRanges(
      veryHigh: 250,
      targetMin: 80,
      targetMax: 130,
      veryLow: 60,
    ),
    onboardingComplete: false,
    onboardingStep: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'diabetesType': diabetesType.name,
    'takesPills': takesPills,
    'insulinMethod': insulinMethod.name,
    'dateOfBirth': dateOfBirth == null
        ? null
        : Timestamp.fromDate(dateOfBirth!),
    'age': age,
    'medicationName': medicationName,
    'medicationTimes': medicationTimes.map((e) => e.name).toList(),
    'glucoseRanges': glucoseRanges.toMap(),
    'onboardingComplete': onboardingComplete,
    'onboardingStep': onboardingStep,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: d['displayName'] as String?,
      diabetesType: _diabetesFromString(d['diabetesType'] as String?),
      takesPills: (d['takesPills'] ?? false) as bool,
      insulinMethod: _insulinFromString(d['insulinMethod'] as String?),
      dateOfBirth: (d['dateOfBirth'] as Timestamp?)?.toDate(),
      age: d['age'] == null ? null : (d['age'] as num).toInt(),
      medicationName: d['medicationName'] as String?,
      medicationTimes: ((d['medicationTimes'] as List?) ?? const [])
          .map((e) => _medTimeFromString('$e'))
          .toList(),
      glucoseRanges: GlucoseRanges.fromMap(
        d['glucoseRanges'] as Map<String, dynamic>?,
      ),
      onboardingComplete: (d['onboardingComplete'] ?? false) as bool,
      onboardingStep: (d['onboardingStep'] ?? 0) as int,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static DiabetesType _diabetesFromString(String? v) {
    switch (v) {
      case 'type1':
        return DiabetesType.type1;
      case 'type2':
        return DiabetesType.type2;
      case 'lada':
        return DiabetesType.lada;
      case 'type3':
        return DiabetesType.type3;
      default:
        return DiabetesType.other;
    }
  }

  static InsulinMethod _insulinFromString(String? v) {
    switch (v) {
      case 'penSyringe':
        return InsulinMethod.penSyringe;
      case 'pump':
        return InsulinMethod.pump;
      default:
        return InsulinMethod.none;
    }
  }

  static MedTime _medTimeFromString(String v) {
    switch (v) {
      case 'morning':
        return MedTime.morning;
      case 'afternoon':
        return MedTime.afternoon;
      case 'evening':
        return MedTime.evening;
      case 'night':
        return MedTime.night;
      default:
        return MedTime.other;
    }
  }
}

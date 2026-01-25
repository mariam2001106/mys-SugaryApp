// Note: kept original filename to match your imports.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    as fr; // avoid shadowing issues with TextDirection
import 'package:easy_localization/easy_localization.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../home/home_screen.dart';

class PersonalSetupWizard extends StatefulWidget {
  final String uid;
  const PersonalSetupWizard({super.key, required this.uid});

  @override
  State<PersonalSetupWizard> createState() => _PersonalSetupWizardState();
}

class _PersonalSetupWizardState extends State<PersonalSetupWizard> {
  // 0..6 (7 steps)
  int step = 0;
  bool saving = false;

  // Step 0
  DiabetesType? _type;
  // Step 1
  bool? _takesPills;
  // Step 2
  InsulinMethod? _insulin;
  // Step 3
  DateTime? _dob;
  // Step 4
  final TextEditingController _medName = TextEditingController();
  // Step 5
  final Set<MedTime> _times = {};
  // Step 6
  final TextEditingController _veryHigh = TextEditingController(text: '250');
  final TextEditingController _targetMin = TextEditingController(text: '80');
  final TextEditingController _targetMax = TextEditingController(text: '130');
  final TextEditingController _veryLow = TextEditingController(text: '60');

  final svc = ProfileService();

  @override
  void dispose() {
    _medName.dispose();
    _veryHigh.dispose();
    _targetMin.dispose();
    _targetMax.dispose();
    _veryLow.dispose();
    super.dispose();
  }

  static const int totalSteps = 7;

  int get _progressNumerator => step + 1;

  Future<void> onContinue() async {
    if (!validateStep(step)) return;
    setState(() => saving = true);
    try {
      switch (step) {
        case 0:
          await svc.updatePartial(widget.uid, {
            'diabetesType': (_type ?? DiabetesType.other).name,
            'onboardingStep': step,
          });
          break;
        case 1:
          await svc.updatePartial(widget.uid, {
            'takesPills': _takesPills ?? false,
            'onboardingStep': step,
          });
          break;
        case 2:
          await svc.updatePartial(widget.uid, {
            'insulinMethod': (_insulin ?? InsulinMethod.none).name,
            'onboardingStep': step,
          });
          break;
        case 3:
          final age = _dob == null ? null : _computeAge(_dob!);
          await svc.updatePartial(widget.uid, {
            'dateOfBirth': _dob,
            'age': age,
            'onboardingStep': step,
          });
          break;
        case 4:
          await svc.updatePartial(widget.uid, {
            'medicationName': _medName.text.trim().isEmpty
                ? null
                : _medName.text.trim(),
            'onboardingStep': step,
          });
          break;
        case 5:
          await svc.updatePartial(widget.uid, {
            'medicationTimes': _times.map((e) => e.name).toList(),
            'onboardingStep': step,
          });
          break;
        case 6:
          // validation already checked in validateStep, but be defensive here
          final vh = int.tryParse(_veryHigh.text.trim());
          final tmin = int.tryParse(_targetMin.text.trim());
          final tmax = int.tryParse(_targetMax.text.trim());
          final vl = int.tryParse(_veryLow.text.trim());
          if (vh == null || tmin == null || tmax == null || vl == null) {
            toast('errors.unexpected'.tr());
            return;
          }
          await svc.updatePartial(widget.uid, {
            'glucoseRanges': {
              'veryHigh': vh,
              'targetMin': tmin,
              'targetMax': tmax,
              'veryLow': vl,
            },
            'onboardingStep': step,
          });
          await svc.completeOnboarding(widget.uid);
          if (!mounted) return;
          // navigate directly to HomeScreen (no named route dependency)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          return;
      }

      if (mounted) setState(() => step += 1);
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'errors.unexpected'.tr()} — $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void onBack() {
    if (step > 0) setState(() => step -= 1);
  }

  bool validateStep(int s) {
    switch (s) {
      case 0:
        if (_type == null) {
          toast('setup.diabetes_type'.tr());
          return false;
        }
        return true;
      case 1:
        if (_takesPills == null) {
          toast('setup.takes_pills'.tr());
          return false;
        }
        return true;
      case 2:
        if (_insulin == null) {
          toast('setup.insulin_method'.tr());
          return false;
        }
        return true;
      case 3:
        if (_dob == null) {
          toast('setup.age_error'.tr());
          return false;
        }
        return true;
      case 6:
        final vh = int.tryParse(_veryHigh.text.trim());
        final tmin = int.tryParse(_targetMin.text.trim());
        final tmax = int.tryParse(_targetMax.text.trim());
        final vl = int.tryParse(_veryLow.text.trim());
        final ok =
            vh != null &&
            tmin != null &&
            tmax != null &&
            vl != null &&
            tmin < tmax &&
            vl >= 40 &&
            vh >= 150;
        if (!ok) toast('setup.range_error'.tr());
        return ok;
      default:
        return true;
    }
  }

  void toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic text direction based on locale (RTL for Arabic, LTR otherwise)
    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? fr.TextDirection.rtl
          : fr.TextDirection.ltr,
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          final bg = cs.surface;

          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(title: Text('setup.title'.tr())),
            body: SafeArea(
              child: Column(
                children: [
                  // Top progress
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressNumerator / totalSteps,
                        minHeight: 6,
                        color: cs.primary,
                        backgroundColor: cs.onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._buildStepContent(cs),
                            const SizedBox(height: 28),
                            // Continue
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  minimumSize: const Size.fromHeight(54),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: saving ? null : onContinue,
                                child: saving
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : Text(
                                        step == totalSteps - 1
                                            ? 'setup.finish'.tr()
                                            : 'setup.next'.tr(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom bar: Back + step indicator
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: cs.onSurface.withValues(
                              alpha: 0.06,
                            ),
                            shape: const StadiumBorder(),
                            foregroundColor: cs.onSurface,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          onPressed: step == 0 ? null : onBack,
                          child: Text('setup.back'.tr()),
                        ),
                        const Spacer(),
                        Text(
                          'الخطوة $_progressNumerator من $totalSteps •',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildStepContent(ColorScheme cs) {
    switch (step) {
      case 0:
        return _section(
          title: 'setup.diabetes_type'.tr(),
          subtitle: 'setup.diabetes_type'.tr(),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              textDirection: Directionality.of(context),
              children: DiabetesType.values.map((t) {
                final label = switch (t) {
                  DiabetesType.type1 => 'setup.type1'.tr(),
                  DiabetesType.type2 => 'setup.type2'.tr(),
                  DiabetesType.lada => 'setup.lada'.tr(),
                  DiabetesType.type3 => 'setup.type3'.tr(),
                  DiabetesType.other => 'setup.other'.tr(),
                };
                final sel = _type == t;
                return _choicePill(
                  label: label,
                  selected: sel,
                  onTap: () => setState(() => _type = t),
                );
              }).toList(),
            ),
          ],
        );
      case 1:
        return _section(
          title: 'setup.takes_pills'.tr(),
          subtitle: 'setup.takes_pills'.tr(),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              textDirection: Directionality.of(context),
              children: [
                _choicePill(
                  label: 'setup.yes'.tr(),
                  selected: _takesPills == true,
                  onTap: () => setState(() => _takesPills = true),
                ),
                _choicePill(
                  label: 'setup.no'.tr(),
                  selected: _takesPills == false,
                  onTap: () => setState(() => _takesPills = false),
                ),
              ],
            ),
          ],
        );
      case 2:
        return _section(
          title: 'setup.insulin_method'.tr(),
          subtitle: 'setup.insulin_method'.tr(),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              textDirection: Directionality.of(context),
              children: InsulinMethod.values.map((m) {
                final label = switch (m) {
                  InsulinMethod.penSyringe => 'setup.pen_syringe'.tr(),
                  InsulinMethod.pump => 'setup.pump'.tr(),
                  InsulinMethod.none => 'setup.none'.tr(),
                };
                final sel = _insulin == m;
                return _choicePill(
                  label: label,
                  selected: sel,
                  onTap: () => setState(() => _insulin = m),
                );
              }).toList(),
            ),
          ],
        );
      case 3:
        final today = DateTime.now();
        final initial =
            _dob ?? DateTime(today.year - 30, today.month, today.day);
        return _section(
          title: 'setup.age'.tr(),
          subtitle: 'setup.age'.tr(),
          children: [
            CalendarDatePicker(
              initialDate: initial,
              firstDate: DateTime(1900),
              lastDate: today,
              onDateChanged: (d) => setState(() => _dob = d),
            ),
          ],
        );
      case 4:
        return _section(
          title: 'setup.medication_name'.tr(),
          subtitle: 'setup.medication_name'.tr(),
          children: [
            TextField(
              controller: _medName,
              textDirection: Directionality.of(context),
              decoration: InputDecoration(
                hintText: 'setup.medication_name'.tr(),
              ),
            ),
          ],
        );
      case 5:
        return _section(
          title: 'setup.medication_times'.tr(),
          subtitle: 'setup.medication_times'.tr(),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              textDirection: Directionality.of(context),
              children: MedTime.values.map((t) {
                final label = switch (t) {
                  MedTime.morning => 'setup.time.morning'.tr(),
                  MedTime.afternoon => 'setup.time.afternoon'.tr(),
                  MedTime.evening => 'setup.time.evening'.tr(),
                  MedTime.night => 'setup.time.night'.tr(),
                  MedTime.other => 'setup.time.other'.tr(),
                };
                final sel = _times.contains(t);
                return _choicePill(
                  label: label,
                  selected: sel,
                  onTap: () {
                    setState(() {
                      if (sel) {
                        _times.remove(t);
                      } else {
                        _times.add(t);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      case 6:
        return _section(
          title: 'setup.target_min'.tr(),
          subtitle: 'setup.target_max'.tr(),
          children: [
            Row(
              textDirection: Directionality.of(context),
              children: [
                Expanded(
                  child: TextField(
                    controller: _veryHigh,
                    keyboardType: TextInputType.number,
                    textDirection: Directionality.of(context),
                    decoration: InputDecoration(
                      labelText: 'setup.very_high'.tr(),
                      suffixText: 'home.mg_dl_unit'.tr(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _veryLow,
                    keyboardType: TextInputType.number,
                    textDirection: Directionality.of(context),
                    decoration: InputDecoration(
                      labelText: 'setup.very_low'.tr(),
                      suffixText: 'home.mg_dl_unit'.tr(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              textDirection: Directionality.of(context),
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetMin,
                    keyboardType: TextInputType.number,
                    textDirection: Directionality.of(context),
                    decoration: InputDecoration(
                      labelText: 'setup.target_min'.tr(),
                      suffixText: 'home.mg_dl_unit'.tr(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _targetMax,
                    keyboardType: TextInputType.number,
                    textDirection: Directionality.of(context),
                    decoration: InputDecoration(
                      labelText: 'setup.target_max'.tr(),
                      suffixText: 'home.mg_dl_unit'.tr(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return [const SizedBox()];
    }
  }

  List<Widget> _section({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    return [
      const SizedBox(height: 10),
      Text(
        title,
        textAlign: Directionality.of(context) == fr.TextDirection.rtl
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        textAlign: Directionality.of(context) == fr.TextDirection.rtl
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          fontSize: 14,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
      const SizedBox(height: 18),
      ...children,
    ];
  }

  Widget _choicePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : cs.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          textDirection: Directionality.of(context),
          style: TextStyle(
            color: selected ? Colors.white : cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

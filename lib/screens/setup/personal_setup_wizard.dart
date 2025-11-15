import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

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
  static const Color accent = Color(0xFF5B5CE6);

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
            'medicationName': _medName.text.trim().isEmpty ? null : _medName.text.trim(),
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
          final vh = int.parse(_veryHigh.text.trim());
          final tmin = int.parse(_targetMin.text.trim());
          final tmax = int.parse(_targetMax.text.trim());
          final vl = int.parse(_veryLow.text.trim());
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
          Navigator.of(context).pushReplacementNamed('/home');
          return;
      }
      if (mounted) setState(() => step += 1);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع. حاول مرة أخرى.')),
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
          toast('الرجاء اختيار نوع السكري.');
          return false;
        }
        return true;
      case 1:
        if (_takesPills == null) {
          toast('الرجاء اختيار نعم أو لا.');
          return false;
        }
        return true;
      case 2:
        if (_insulin == null) {
          toast('الرجاء اختيار طريقة العلاج بالأنسولين.');
          return false;
        }
        return true;
      case 3:
        if (_dob == null) {
          toast('الرجاء اختيار تاريخ الميلاد.');
          return false;
        }
        return true;
      case 6:
        final vh = int.tryParse(_veryHigh.text.trim());
        final tmin = int.tryParse(_targetMin.text.trim());
        final tmax = int.tryParse(_targetMax.text.trim());
        final vl = int.tryParse(_veryLow.text.trim());
        final ok = vh != null &&
            tmin != null &&
            tmax != null &&
            vl != null &&
            tmin < tmax &&
            vl >= 40 &&
            vh >= 150;
        if (!ok) toast('رجاءً أدخل قيم جلوكوز صحيحة.');
        return ok;
      default:
        return true;
    }
  }

  void toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F141A)
        : cs.surface;

    final content = Column(
      children: [
        // Top progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressNumerator / totalSteps,
              minHeight: 6,
              color: accent,
              backgroundColor: cs.onSurface.withValues(alpha:  0.12),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._buildStepContent(cs),
                  const SizedBox(height: 28),
                  // Continue
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: saving ? null : onContinue,
                      child: saving
                          ? const SizedBox(
                              height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                          : const Text('متابعة', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  backgroundColor: cs.onSurface.withValues(alpha: .06),
                  shape: const StadiumBorder(),
                  foregroundColor: cs.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: step == 0 ? null : onBack,
                child: const Text('رجوع'),
              ),
              const Spacer(),
              Text('الخطوة $_progressNumerator من $totalSteps •',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        )
      ],
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: isRTL
            ? content
            : Directionality( // force RTL when Arabic locale isn’t applied globally
                textDirection: TextDirection.rtl,
                child: content,
              ),
      ),
    );
  }

  List<Widget> _buildStepContent(ColorScheme cs) {
    switch (step) {
      case 0:
        return _section(
          title: 'ما نوع السكري لديك؟',
          subtitle: 'يساعدنا هذا في تقديم توصيات مخصصة لإدارة صحتك.',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _choicePill(
                  label: 'النوع الأول',
                  selected: _type == DiabetesType.type1,
                  onTap: () => setState(() => _type = DiabetesType.type1),
                ),
                _choicePill(
                  label: 'النوع الثاني',
                  selected: _type == DiabetesType.type2,
                  onTap: () => setState(() => _type = DiabetesType.type2),
                ),
                _choicePill(
                  label: 'LADA',
                  selected: _type == DiabetesType.lada,
                  onTap: () => setState(() => _type = DiabetesType.lada),
                ),
                _choicePill(
                  label: 'النوع الثالث',
                  selected: _type == DiabetesType.type3,
                  onTap: () => setState(() => _type = DiabetesType.type3),
                ),
                _choicePill(
                  label: 'أخرى',
                  selected: _type == DiabetesType.other,
                  onTap: () => setState(() => _type = DiabetesType.other),
                ),
              ],
            ),
          ],
        );
      case 1:
        return _section(
          title: 'هل تتناول أي حبوب للسكري؟',
          subtitle: 'يساعدنا هذا في تقديم توصيات مخصصة لإدارة صحتك.',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _choicePill(
                  label: 'نعم',
                  selected: _takesPills == true,
                  onTap: () => setState(() => _takesPills = true),
                ),
                _choicePill(
                  label: 'لا',
                  selected: _takesPills == false,
                  onTap: () => setState(() => _takesPills = false),
                ),
              ],
            ),
          ],
        );
      case 2:
        return _section(
          title: 'ما هي طريقة علاج الأنسولين لديك؟',
          subtitle: 'يساعدنا هذا في تقديم توصيات مخصصة لإدارة صحتك.',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // FIX: one chip for Pen/Syringe so only one can be selected
                _choicePill(
                  label: 'قلم/حقنة',
                  selected: _insulin == InsulinMethod.penSyringe,
                  onTap: () => setState(() => _insulin = InsulinMethod.penSyringe),
                ),
                _choicePill(
                  label: 'مضخة',
                  selected: _insulin == InsulinMethod.pump,
                  onTap: () => setState(() => _insulin = InsulinMethod.pump),
                ),
                _choicePill(
                  label: 'بدون',
                  selected: _insulin == InsulinMethod.none,
                  onTap: () => setState(() => _insulin = InsulinMethod.none),
                ),
              ],
            ),
          ],
        );
      case 3:
        final today = DateTime.now();
        final firstDate = DateTime(1900);
        final initial = _dob ?? DateTime(today.year - 30, today.month, today.day);
        return _section(
          title: 'تاريخ الميلاد',
          subtitle: 'يساعدنا هذا في تقديم توصيات مخصصة لإدارة صحتك.',
          children: [
            CalendarDatePicker(
              initialDate: initial,
              firstDate: firstDate,
              lastDate: today,
              onDateChanged: (d) => setState(() => _dob = d),
            ),
          ],
        );
      case 4:
        return _section(
          title: 'ما اسم دوائك؟',
          subtitle: 'أدخل اسم الدواء الذي تتناوله (اختياري).',
          children: [
            TextField(
              controller: _medName,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(hintText: 'مثال: Metformin'),
            ),
          ],
        );
      case 5:
        return _section(
          title: 'متى تتناول دواءك؟',
          subtitle: 'اختر كل ما ينطبق.',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: MedTime.values.map((t) {
                final label = switch (t) {
                  MedTime.morning => 'صباحًا',
                  MedTime.afternoon => 'ظهرًا',
                  MedTime.evening => 'مساءً',
                  MedTime.night => 'ليلًا',
                  MedTime.other => 'أخرى',
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
          title: 'ما هي حدود الجلوكوز لديك؟',
          subtitle: 'عيِّن مرتفع جدًا، والمدى المستهدف، ومنخفض جدًا (mg/dL).',
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _veryHigh,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(labelText: 'مرتفع جدًا', suffixText: 'mg/dL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _veryLow,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(labelText: 'منخفض جدًا', suffixText: 'mg/dL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetMin,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(labelText: 'المدى المستهدف (أدنى)', suffixText: 'mg/dL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _targetMax,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(labelText: 'المدى المستهدف (أعلى)', suffixText: 'mg/dL'),
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
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        textAlign: TextAlign.center,
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
          color: selected ? accent : cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? Colors.transparent : cs.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          textDirection: TextDirection.rtl,
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
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mysugaryapp/models/medicationreminder_model.dart';
import 'package:mysugaryapp/services/reminder_service.dart';

class SmartAssist extends StatefulWidget {
  final VoidCallback onFinished; // called when overlay is done (or dismissed)
  const SmartAssist({super.key, required this.onFinished});

  @override
  State<SmartAssist> createState() => _SmartAssistState();
}

class _SmartAssistState extends State<SmartAssist> {
  final ReminderService svc = ReminderService();

  int step = 0;
  bool saving = false;

  // Medication
  String medName = '';
  String medUnit = '';
  TimeOfDay? medTime;

  // Glucose reminders (list of {label, time})
  final List<Map<String, dynamic>> glucose = [
    {'label': '', 'time': (null as TimeOfDay?)},
  ];

  ColorScheme get cs => Theme.of(context).colorScheme;
  ThemeData get theme => Theme.of(context);

  /// Convert TimeOfDay to HH:mm format (machine-friendly, locale-independent)
  String _formatHHmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _completeAndClose() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await svc.setSmartAssistComplete(uid, value: true);
      } catch (_) {}
    }
    widget.onFinished();
  }

  Future<void> _saveMedication() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (medName.isEmpty || medUnit.isEmpty || medTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('smart.required'.tr())));
      return;
    }
    setState(() => saving = true);
    try {
      await svc.addMedicationReminder(
        uid,
        MedicationReminder(
          name: medName.trim(),
          unit: medUnit.trim(),
          time: _formatHHmm(medTime!), // Use HH:mm format
        ),
      );
      setState(() => step = 1);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _saveGlucose() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final complete = glucose
        .where(
          (g) => (g['label'] as String).trim().isNotEmpty && g['time'] != null,
        )
        .toList();
    if (complete.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('smart.required'.tr())));
      return;
    }
    setState(() => saving = true);
    try {
      final list = complete
          .map(
            (g) => GlucoseCheckReminder(
              label: (g['label'] as String).trim(),
              time: _formatHHmm(g['time'] as TimeOfDay), // Use HH:mm format
            ),
          )
          .toList();
      await svc.setGlucoseReminders(uid, list);
      await svc.setSmartAssistComplete(uid, value: true);
      widget.onFinished();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _medStepCard() {
    return _card(
      title: 'smart.med_title'.tr(),
      subtitle: 'smart.med_subtitle'.tr(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'smart.med_name'.tr(),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
            ),
            onChanged: (v) => medName = v,
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: 'smart.med_unit'.tr(),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
            ),
            onChanged: (v) => medUnit = v,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('smart.med_time'.tr(), style: theme.textTheme.bodyMedium),
              const SizedBox(width: 10),
              Text(medTime?.format(context) ?? '--:--'),
              TextButton(
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t != null) setState(() => medTime = t);
                },
                child: Text('smart.pick_time'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _completeAndClose, // mark complete on skip
                child: Text(
                  'smart.skip'.tr(),
                  style: TextStyle(color: cs.onSurface),
                ),
              ),
              ElevatedButton(
                onPressed: saving ? null : _saveMedication,
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('smart.save_continue'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glucoseStepCard() {
    return _card(
      title: 'smart.glucose_title'.tr(),
      subtitle: 'smart.glucose_subtitle'.tr(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...glucose.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'smart.glucose_label'.tr(),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                      ),
                      onChanged: (v) => item['label'] = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['time'] == null
                        ? '--:--'
                        : (item['time'] as TimeOfDay).format(context),
                  ),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (t != null) setState(() => item['time'] = t);
                    },
                    child: Text('smart.pick_time'.tr()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: glucose.length == 1
                        ? null
                        : () => setState(() => glucose.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() {
              glucose.add({'label': '', 'time': null});
            }),
            icon: const Icon(Icons.add),
            label: Text('smart.add_another'.tr()),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _completeAndClose, // mark complete on skip
                child: Text(
                  'smart.skip'.tr(),
                  style: TextStyle(color: cs.onSurface),
                ),
              ),
              ElevatedButton(
                onPressed: saving ? null : _saveGlucose,
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('smart.save_finish'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: cs.onSurface.withOpacity(.7)),
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: .55),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: step == 0 ? _medStepCard() : _glucoseStepCard(),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mysugaryapp/services/reminder_service.dart';
import 'package:mysugaryapp/models/reminder_models.dart';

class SmartAssist extends StatefulWidget {
  final VoidCallback onFinished; // called when overlay is done (or dismissed)
  const SmartAssist({super.key, required this.onFinished});

  @override
  State<SmartAssist> createState() => _SmartAssistState();
}

class _SmartAssistState extends State<SmartAssist> {
  final ReminderService svc = ReminderService();

  bool saving = false;

  // Generic reminders to create during onboarding
  final List<_ReminderDraft> _reminders = [_ReminderDraft()];

  ColorScheme get cs => Theme.of(context).colorScheme;
  ThemeData get theme => Theme.of(context);

  /// Convert TimeOfDay to HH:mm format (machine-friendly, locale-independent)
  String _formatHHmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _completeAndClose() async {
    widget.onFinished();
  }

  Future<void> _saveReminders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final valid = _reminders
        .where(
          (r) => r.type != null && r.title.trim().isNotEmpty && r.time != null,
        )
        .toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('smart.required'.tr())));
      return;
    }
    setState(() => saving = true);
    try {
      for (final r in valid) {
        final dto = ReminderItemDto(
          id: '',
          type: r.type!,
          title: r.title.trim(),
          time: _formatHHmm(r.time!),
          frequency: ReminderFrequency.daily,
          enabled: true,
        );
        await svc.addReminder(uid, dto);
      }
      widget.onFinished();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _addRemindersCard() {
    return _card(
      title: 'reminders.title'.tr(),
      subtitle: 'reminders.subtitle'.tr(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._reminders.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Type
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<ReminderType>(
                      value: item.type,
                      decoration: InputDecoration(
                        labelText: 'reminders.type_label'.tr(),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      items: ReminderType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(_typeLabel(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => item.type = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'reminders.title_label'.tr(),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                      ),
                      onChanged: (v) => item.title = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time
                  Text(
                    item.time == null ? '--:--' : (item.time!).format(context),
                  ),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (t != null) setState(() => item.time = t);
                    },
                    child: Text('smart.pick_time'.tr()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _reminders.length == 1
                        ? null
                        : () => setState(() => _reminders.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _reminders.add(_ReminderDraft())),
            icon: const Icon(Icons.add),
            label: Text('smart.add_another'.tr()),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _completeAndClose, // skip
                child: Text(
                  'smart.skip'.tr(),
                  style: TextStyle(color: cs.onSurface),
                ),
              ),
              ElevatedButton(
                onPressed: saving ? null : _saveReminders,
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

  // Helper to localize ReminderType
  String _typeLabel(ReminderType t) {
    switch (t) {
      case ReminderType.medication:
        return 'reminders.type_medication'.tr();
      case ReminderType.glucose:
        return 'reminders.type_glucose'.tr();
      case ReminderType.appointment:
        return 'reminders.type_appointment'.tr();
    }
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
                style: TextStyle(color: cs.onSurface.withValues(alpha: .7)),
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
      child: Center(child: _addRemindersCard()),
    );
  }
}

class _ReminderDraft {
  ReminderType? type;
  String title = '';
  TimeOfDay? time;
}

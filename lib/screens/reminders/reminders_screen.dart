import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as fr;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mysugaryapp/models/reminder_models.dart';
import 'package:mysugaryapp/services/notification_service.dart';
import 'package:mysugaryapp/services/reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _svc = ReminderService();

  ReminderType? _type;
  TimeOfDay? _time;
  ReminderFrequency _frequency = ReminderFrequency.daily;

  int? _editingIndex; // null means adding
  List<ReminderItemDto> _items = [];
  String? _uid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final items = await _svc.listReminders(uid);
    if (!mounted) return;
    setState(() {
      _uid = uid;
      _items = items;
      _loading = false;
    });
  }

  IconData _iconFor(ReminderType t) {
    switch (t) {
      case ReminderType.medication:
        return Icons.medication_outlined;
      case ReminderType.glucose:
        return Icons.monitor_heart_outlined;
      case ReminderType.appointment:
        return Icons.event_outlined;
    }
  }

  Color _colorFor(ReminderType t) {
    switch (t) {
      case ReminderType.medication:
        return Colors.blue.shade600;
      case ReminderType.glucose:
        return Colors.green.shade600;
      case ReminderType.appointment:
        return Colors.orange.shade700;
    }
  }

  String _typeLabel(ReminderType? t) {
    if (t == null) return 'reminders.type_placeholder'.tr();
    switch (t) {
      case ReminderType.medication:
        return 'reminders.type_medication'.tr();
      case ReminderType.glucose:
        return 'reminders.type_glucose'.tr();
      case ReminderType.appointment:
        return 'reminders.type_appointment'.tr();
    }
  }

  String _freqLabel(ReminderFrequency f) {
    switch (f) {
      case ReminderFrequency.daily:
        return 'reminders.freq_daily'.tr();
      case ReminderFrequency.weekly:
        return 'reminders.freq_weekly'.tr();
      case ReminderFrequency.monthly:
        return 'reminders.freq_custom'.tr();
    }
  }

  TimeOfDay? _parseHHmm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  String _formatHHmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _resetForm() {
    _editingIndex = null;
    _type = null;
    _time = null;
    _frequency = ReminderFrequency.daily;
    _titleCtrl.clear();
    setState(() {});
  }

  void _startEdit(int index) {
    final r = _items[index];
    _editingIndex = index;
    _type = r.type;
    _time = _parseHHmm(r.time);
    _frequency = r.frequency;
    _titleCtrl.text = r.title;
    setState(() {});
  }

  Future<void> _deleteItem(int index) async {
    if (_uid == null) return;
    final r = _items[index];
    await _svc.deleteReminder(_uid!, r.id);
    await NotificationsService().cancelReminder(r);
    if (!mounted) return;
    setState(() {
      _items.removeAt(index);
      if (_editingIndex == index) _resetForm();
    });
  }

  Future<void> _addOrUpdateReminder() async {
    if (_uid == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_type == null || _time == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('reminders.missing_fields'.tr())));
      return;
    }

    final hhmm = _formatHHmm(_time!);
    final dto = ReminderItemDto(
      id: _editingIndex == null ? '' : _items[_editingIndex!].id,
      type: _type!,
      title: _titleCtrl.text.trim(),
      time: hhmm,
      frequency: _frequency,
      enabled: true,
    );

    if (_editingIndex == null) {
      final newId = await _svc.addReminder(_uid!, dto);
      final created = dto.copyWith(id: newId);
      await NotificationsService().scheduleReminder(created);
      if (!mounted) return;
      setState(() => _items.add(created));
    } else {
      await _svc.updateReminder(_uid!, dto);
      await NotificationsService().cancelReminder(_items[_editingIndex!]);
      await NotificationsService().scheduleReminder(dto);
      if (!mounted) return;
      setState(() => _items[_editingIndex!] = dto);
    }

    _resetForm();
  }

  Future<void> _toggleEnabled(int index, bool value) async {
    if (_uid == null) return;
    final curr = _items[index];
    final updated = curr.copyWith(enabled: value);
    await _svc.updateReminder(_uid!, updated);
    if (value) {
      await NotificationsService().scheduleReminder(updated);
    } else {
      await NotificationsService().cancelReminder(curr);
    }
    if (!mounted) return;
    setState(() => _items[index] = updated);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.locale.languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: isRtl ? fr.TextDirection.rtl : fr.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.notifications_none,
                color: Color.fromARGB(255, 48, 26, 188),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'reminders.title'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'reminders.subtitle'.tr(),
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    children: [
                      // Add / Edit reminder card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _editingIndex == null
                                        ? Icons.add
                                        : Icons.edit,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _editingIndex == null
                                          ? 'reminders.add_new'.tr()
                                          : 'reminders.edit_existing'.tr(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_editingIndex != null) ...[
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _resetForm,
                                      child: Text('reminders.cancel_edit'.tr()),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'reminders.type_label'.tr(),
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<ReminderType>(
                                initialValue: _type,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                hint: Text('reminders.type_placeholder'.tr()),
                                items: ReminderType.values
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(_typeLabel(t)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _type = v),
                                validator: (v) => v == null
                                    ? 'reminders.type_required'.tr()
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'reminders.title_label'.tr(),
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _titleCtrl,
                                decoration: InputDecoration(
                                  hintText: 'reminders.title_hint'.tr(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'reminders.title_required'.tr()
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'reminders.time_label'.tr(),
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(10),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _time == null
                                              ? 'reminders.time_placeholder'
                                                    .tr()
                                              : _time!.format(context),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.access_time, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'reminders.freq_label'.tr(),
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<ReminderFrequency>(
                                initialValue: _frequency,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                items: ReminderFrequency.values.map((f) {
                                  final label = _freqLabel(f);
                                  return DropdownMenuItem(
                                    value: f,
                                    child: Text(label),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(
                                  () =>
                                      _frequency = v ?? ReminderFrequency.daily,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _addOrUpdateReminder,
                                  child: Text(
                                    _editingIndex == null
                                        ? 'reminders.add_button'.tr()
                                        : 'reminders.save_button'.tr(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Active reminders
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'reminders.active_title'.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'reminders.active_empty'.tr(),
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: _items.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final r = entry.value;
                                  final typeEnum = r.type;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _colorFor(
                                        typeEnum,
                                      ).withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _colorFor(
                                          typeEnum,
                                        ).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _iconFor(typeEnum),
                                            color: _colorFor(typeEnum),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  r.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: cs.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${r.time} • ${_freqLabel(r.frequency)}',
                                                  style: TextStyle(
                                                    color: cs.onSurface
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: cs.surface,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: cs.onSurface
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _typeLabel(typeEnum),
                                                    style: TextStyle(
                                                      color: cs.onSurface
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                Switch(
                                                  value: r.enabled,
                                                  onChanged: (v) =>
                                                      _toggleEnabled(i, v),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'reminders.edit'
                                                      .tr(),
                                                  onPressed: () =>
                                                      _startEdit(i),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'reminders.delete'
                                                      .tr(),
                                                  onPressed: () =>
                                                      _deleteItem(i),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

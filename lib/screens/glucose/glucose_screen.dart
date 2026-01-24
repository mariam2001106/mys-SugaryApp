import 'package:easy_localization/easy_localization.dart' as tr;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:mysugaryapp/models/glucose_entry_model.dart';
import 'package:mysugaryapp/services/glucose_service.dart';

class GlucoseScreen extends StatefulWidget {
  const GlucoseScreen({super.key});

  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _svc = GlucoseService();

  TimeOfDay _time = TimeOfDay.now();
  DateTime _date = DateTime.now();
  GlucoseContext _ctx = GlucoseContext.fasting;
  bool _saving = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = d);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final val = num.parse(_valueCtrl.text.trim());
      await _svc.addEntry(
        value: val,
        timestamp: _combinedDateTime,
        context: _ctx,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('glucose.saved'.tr())));
        _valueCtrl.clear();
        _noteCtrl.clear();
        setState(() {
          _time = TimeOfDay.now();
          _date = DateTime.now();
          _ctx = GlucoseContext.fasting;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('errors.unexpected'.tr())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEntry(GlucoseEntry e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('glucose.delete_title'.tr()),
        content: Text('glucose.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _svc.deleteEntry(e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('glucose.deleted'.tr())));
  }

  Future<void> _editEntry(GlucoseEntry entry) async {
    final valueCtrl = TextEditingController(text: entry.value.toString());
    final noteCtrl = TextEditingController(text: entry.note);
    var ctx = entry.context;
    var date = entry.timestamp;
    var time = TimeOfDay.fromDateTime(entry.timestamp);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final insets = MediaQuery.of(context).viewInsets;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: insets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note),
                    const SizedBox(width: 8),
                    Text(
                      'glucose.edit_title'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'glucose.value_label'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'glucose.value_required'.tr();
                    }
                    final n = num.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return 'glucose.value_invalid'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );
                          if (picked != null) {
                            time = picked;
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'glucose.time_label'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            DateFormat('hh:mm a').format(_combine(date, time)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (picked != null) {
                            date = picked;
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'glucose.date_label'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            DateFormat(
                              'MM/dd/yyyy',
                            ).format(_combine(date, time)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GlucoseContext>(
                  initialValue: ctx,
                  decoration: InputDecoration(
                    labelText: 'glucose.context_label'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: GlucoseContext.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(_ctxLabel(c)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => ctx = v ?? GlucoseContext.fasting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'glucose.note_label'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final val = num.parse(valueCtrl.text.trim());
                      final ts = _combine(date, time);
                      await _svc.updateEntry(
                        entry.id,
                        value: val,
                        timestamp: ts,
                        context: ctx,
                        note: noteCtrl.text.trim(),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('glucose.updated'.tr())),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('glucose.save'.tr()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _ctxLabel(GlucoseContext c) {
    switch (c) {
      case GlucoseContext.fasting:
        return 'glucose.ctx.fasting'.tr();
      case GlucoseContext.beforeMeal:
        return 'glucose.ctx.before_meal'.tr();
      case GlucoseContext.afterMeal:
        return 'glucose.ctx.after_meal'.tr();
      case GlucoseContext.beforeSleep:
        return 'glucose.ctx.before_sleep'.tr();
      case GlucoseContext.afterExercise:
        return 'glucose.ctx.after_exercise'.tr();
      case GlucoseContext.duringStress:
        return 'glucose.ctx.during_stress'.tr();
      case GlucoseContext.whenSick:
        return 'glucose.ctx.when_sick'.tr();
      case GlucoseContext.other:
        return 'glucose.ctx.other'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = context.locale.languageCode == 'ar';
    final dateFmt = DateFormat('MM/dd/yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Directionality(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text('glucose.title'.tr()), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Form
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
                            const Icon(Icons.bloodtype, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'glucose.add_title'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _valueCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'glucose.value_label'.tr(),
                            hintText: 'glucose.value_hint'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'glucose.value_required'.tr();
                            }
                            final n = num.tryParse(v.trim());
                            if (n == null || n <= 0) {
                              return 'glucose.value_invalid'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(10),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'glucose.time_label'.tr(),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    timeFmt.format(_combinedDateTime),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(10),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'glucose.date_label'.tr(),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    dateFmt.format(_combinedDateTime),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<GlucoseContext>(
                          initialValue: _ctx,
                          decoration: InputDecoration(
                            labelText: 'glucose.context_label'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: GlucoseContext.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(_ctxLabel(c)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () => _ctx = v ?? GlucoseContext.fasting,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'glucose.note_label'.tr(),
                            hintText: 'glucose.note_hint'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('glucose.save'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Recent readings
                StreamBuilder<List<GlucoseEntry>>(
                  stream: _svc.recentStream(limit: 10),
                  builder: (context, snap) {
                    final entries = snap.data ?? [];
                    return Container(
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
                              const Icon(Icons.history, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'glucose.recent'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (snap.connectionState == ConnectionState.waiting)
                            const Center(child: CircularProgressIndicator())
                          else if (entries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.water_drop_outlined,
                                    size: 48,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'glucose.empty'.tr(),
                                    style: TextStyle(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: entries
                                  .map(
                                    (e) => ListTile(
                                      dense: true,
                                      leading: Icon(
                                        Icons.water_drop,
                                        color: cs.primary,
                                      ),
                                      title: Text('${e.value} ${e.unit}'),
                                      subtitle: Text(
                                        '${timeFmt.format(e.timestamp)} • ${_ctxLabel(e.context)}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(dateFmt.format(e.timestamp)),
                                          PopupMenuButton<String>(
                                            onSelected: (choice) {
                                              if (choice == 'edit') {
                                                _editEntry(e);
                                              } else if (choice == 'delete') {
                                                _deleteEntry(e);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('common.edit'.tr()),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text(
                                                  "common.delete".tr(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysugaryapp/models/meals_enrty_model.dart';
import 'package:mysugaryapp/services/meal_service.dart';

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  final _svc = MealService();
  final _formKey = GlobalKey<FormState>();

  final _mealNameCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  MealType? _mealType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    // Initialize date and time to current values
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void dispose() {
    _mealNameCtrl.dispose();
    _carbsCtrl.dispose();
    _caloriesCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    // Build detailed error message for missing fields
    final missingFields = <String>[];
    if (_mealType == null) missingFields.add('meals.meal_type_label'.tr());
    if (_selectedDate == null) missingFields.add('meals.date_label'.tr());
    if (_selectedTime == null) missingFields.add('meals.time_label'.tr());
    // Carbs input is validated by form validator, not needed here

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('${'meals.missing_field_prefix'.tr()}: ${missingFields.join(', ')}'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final tsLocal = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Parse carbs and calories
    final carbs = num.tryParse(_carbsCtrl.text.trim()) ?? 0;
    final calories = _caloriesCtrl.text.trim().isEmpty 
        ? null 
        : num.tryParse(_caloriesCtrl.text.trim());

    final result = await _svc.addMeal(
      name: _mealNameCtrl.text.trim(),
      type: _mealType!,
      timestamp: tsLocal,
      directCarbs: carbs,
      directCalories: calories,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('meals.save_error'.tr()),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show insulin suggestion dialog
    final insulinUnits = result['insulinUnits'] as num?;
    final totalCarbs = result['totalCarbs'] as num;
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('meals.save_success'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_mealNameCtrl.text.trim()}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '${totalCarbs.toStringAsFixed(0)}g ${'meals.carbs_label'.tr()}',
              style: TextStyle(fontSize: 16),
            ),
            if (insulinUnits != null) ...[
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.medication, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'meals.suggested_insulin'.tr()}: ${insulinUnits.toStringAsFixed(2)} units',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    // Reset fields after dialog is closed
    if (!mounted) return;
    setState(() {
      _mealNameCtrl.clear();
      _carbsCtrl.clear();
      _caloriesCtrl.clear();
      _noteCtrl.clear();
      _mealType = null;
      // Reinitialize date and time to current values for next meal
      final now = DateTime.now();
      _selectedDate = now;
      _selectedTime = TimeOfDay.fromDateTime(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('h:mm a');
    final dateFmt = DateFormat('MM/dd/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant_outlined, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'meals.title'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'meals.subtitle'.tr(),
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Add New Meal card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withOpacity(0.1)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'meals.add_new_title'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Meal name
                    Text(
                      'meals.meal_name_label'.tr(),
                      style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _mealNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'meals.meal_name_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'meals.meal_name_required'.tr()
                          : null,
                    ),

                    const SizedBox(height: 12),

                    // Meal type
                    Text(
                      'meals.meal_type_label'.tr(),
                      style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<MealType>(
                      initialValue: _mealType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      hint: Text('meals.meal_type_hint'.tr()),
                      items: MealType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(_mealTypeLabel(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _mealType = v),
                      validator: (v) =>
                          v == null ? 'meals.meal_type_required'.tr() : null,
                    ),

                    const SizedBox(height: 12),

                    // Time and Date pickers
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'meals.time_label'.tr(),
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.75),
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
                                          _selectedTime == null
                                              ? 'meals.time_hint'.tr()
                                              : timeFmt.format(
                                                  DateTime(
                                                    0,
                                                    1,
                                                    1,
                                                    _selectedTime!.hour,
                                                    _selectedTime!.minute,
                                                  ),
                                                ),
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'meals.date_label'.tr(),
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.75),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
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
                                          _selectedDate == null
                                              ? 'meals.date_hint'.tr()
                                              : dateFmt.format(_selectedDate!),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Carbohydrates input
                    Text(
                      'meals.carbs_total_label'.tr(),
                      style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _carbsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'meals.carbs_total_hint'.tr(),
                        suffixText: 'g',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'meals.carbs_required'.tr();
                        }
                        final n = num.tryParse(v.trim());
                        if (n == null || n < 0) {
                          return 'meals.invalid_number'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    // Calories input
                    Text(
                      'meals.calories_total_label'.tr(),
                      style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _caloriesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'meals.calories_total_hint'.tr(),
                        suffixText: 'kcal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (v) {
                        // Calories is optional, but if provided must be valid
                        if (v != null && v.trim().isNotEmpty) {
                          final n = num.tryParse(v.trim());
                          if (n == null || n < 0) {
                            return 'meals.invalid_number'.tr();
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Notes
                    Text(
                      'meals.notes_label'.tr(),
                      style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'meals.notes_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _saveMeal,
                        child: Text('meals.save_button'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recent meals
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'meals.recent_title'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<MealEntry>>(
                    stream: _svc.recentStream(limit: 10),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final recent = snap.data ?? [];
                      if (recent.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.restaurant_outlined,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'meals.recent_empty'.tr(),
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: recent.map((m) {
                          final dt = m.timestamp;
                          final dtStr =
                              '${dateFmt.format(dt)} • ${timeFmt.format(dt)}';
                          final macroStr = [
                            '${m.totalCarbs} g ${'meals.carbs_unit'.tr()}',
                            if (m.totalCalories != null)
                              '${m.totalCalories} ${'meals.calories_unit'.tr()}',
                            if (m.insulinUnitsSuggested != null)
                              'meals.insulin_suggested'.tr(args: [m.insulinUnitsSuggested!.toStringAsFixed(2)]),
                          ].join(' • ');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dtStr,
                                        style: TextStyle(
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        macroStr,
                                        style: TextStyle(
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mealTypeLabel(MealType t) {
    switch (t) {
      case MealType.breakfast:
        return 'meals.type_breakfast'.tr();
      case MealType.lunch:
        return 'meals.type_lunch'.tr();
      case MealType.dinner:
        return 'meals.type_dinner'.tr();
      case MealType.snack:
        return 'meals.type_snack'.tr();
      case MealType.other:
        return 'meals.type_other'.tr();
    }
  }
}

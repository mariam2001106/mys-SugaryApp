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
  final _noteCtrl = TextEditingController();

  MealType? _mealType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Items selected for this meal
  final List<FoodItem> _selectedItems = [];

  @override
  void dispose() {
    _mealNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // Derived totals from selected items
  ({num carbs, num? calories}) get _totals {
    num carbs = 0;
    num? calories;
    for (final i in _selectedItems) {
      carbs += i.carbsGrams;
      if (i.calories != null) {
        calories = (calories ?? 0) + i.calories!;
      }
    }
    return (carbs: carbs, calories: calories);
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

  void _removeItem(int index) {
    setState(() => _selectedItems.removeAt(index));
  }

  Future<void> _addCommonFood(FoodItem base) async {
    final qtyCtrl = TextEditingController(text: '1');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'meals.add_item_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      base.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'meals.quantity_label'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final q = num.tryParse(qtyCtrl.text.trim());
                    if (q == null || q <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('meals.quantity_invalid'.tr())),
                      );
                      return;
                    }
                    // Multiply macros/calories by quantity
                    final item = FoodItem(
                      name: base.name,
                      carbsGrams: base.carbsGrams * q,
                      calories: base.calories == null
                          ? null
                          : base.calories! * q,
                      quantity: q,
                      unit: base.unit,
                    );
                    Navigator.pop(ctx);
                    setState(() => _selectedItems.add(item));
                  },
                  child: Text('meals.add_button'.tr()),
                ),
              ),
            ],
          ),
        );
      },
    );
    qtyCtrl.dispose();
  }

  Future<void> _addCustomFood() async {
    final nameCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final calsCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'meals.custom_item_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'meals.item_name_label'.tr(),
                  hintText: 'meals.item_name_hint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carbsCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'meals.carbs_grams_label'.tr(),
                        hintText: 'meals.carbs_grams_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: calsCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'meals.calories_label'.tr(),
                        hintText: 'meals.calories_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'meals.quantity_label'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: FilledButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final carbs = num.tryParse(carbsCtrl.text.trim());
                        final cals = calsCtrl.text.trim().isEmpty
                            ? null
                            : num.tryParse(calsCtrl.text.trim());
                        final qty = num.tryParse(qtyCtrl.text.trim());
                        if (name.isEmpty ||
                            carbs == null ||
                            carbs <= 0 ||
                            qty == null ||
                            qty <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('meals.custom_item_invalid'.tr()),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedItems.add(
                            FoodItem(
                              name: name,
                              carbsGrams: carbs * qty,
                              calories: cals == null ? null : cals * qty,
                              quantity: qty,
                              unit: null,
                            ),
                          );
                        });
                      },
                      child: Text('meals.add_button'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    nameCtrl.dispose();
    carbsCtrl.dispose();
    calsCtrl.dispose();
    qtyCtrl.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mealType == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('meals.missing_fields'.tr())));
      return;
    }

    final tsLocal = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final id = await _svc.addMeal(
      name: _mealNameCtrl.text.trim(),
      type: _mealType!,
      timestamp: tsLocal,
      items: _selectedItems,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('meals.save_error'.tr())));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('meals.save_success'.tr())));
    // Reset minimal fields after save
    setState(() {
      _selectedItems.clear();
      _mealNameCtrl.clear();
      _noteCtrl.clear();
      _mealType = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totals = _totals;
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
                        TextButton.icon(
                          onPressed: _addCustomFood,
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text('meals.add_custom_food'.tr()),
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
                      value: _mealType,
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

                    // Selected items list
                    if (_selectedItems.isNotEmpty) ...[
                      Text(
                        'meals.selected_items_title'.tr(),
                        style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedItems.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          final chipsText =
                              '${item.name} • ${item.carbsGrams.toString()} g'
                              '${item.calories == null ? '' : ' • ${item.calories!.toString()} kcal'}'
                              '${item.quantity > 0 ? ' • x${item.quantity}' : ''}';
                          return Chip(
                            label: Text(chipsText),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeItem(i),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Read-only totals
                    Text(
                      'meals.carbs_total_label'.tr(),
                      style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      readOnly: false,
                      controller: TextEditingController(
                        text: totals.carbs.toStringAsFixed(0),
                      ),
                      decoration: InputDecoration(
                        hintText: 'meals.carbs_total_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'meals.calories_total_label'.tr(),
                      style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      readOnly: false,
                      controller: TextEditingController(
                        text: totals.calories == null
                            ? ''
                            : totals.calories!.toStringAsFixed(0),
                      ),
                      decoration: InputDecoration(
                        hintText: 'meals.calories_total_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
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

            // Common foods
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
                      const Icon(Icons.list_alt_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'meals.common_foods_title'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<FoodItem>>(
                    stream: _svc.commonFoodsStream(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final foods = snap.data ?? [];
                      if (foods.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'meals.common_foods_empty'.tr(),
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: foods.map((f) {
                          final subtitle = [
                            '${f.carbsGrams} g ${'meals.carbs_unit'.tr()}',
                            if (f.calories != null)
                              '${f.calories} ${'meals.calories_unit'.tr()}',
                            if (f.unit?.isNotEmpty == true) f.unit!,
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _addCommonFood(f),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text('meals.add_button'.tr()),
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
                              const Icon(
                                Icons.restaurant_outlined,
                                color: Colors.grey,
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
                              '${'meals.insulin_suggested'.tr(args: [m.insulinUnitsSuggested!.toStringAsFixed(2)])}',
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

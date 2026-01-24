import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mysugaryapp/models/glucose_entry_model.dart';
import 'package:mysugaryapp/services/glucose_service.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/models/user_profile.dart';

class A1CCalculatorScreen extends StatefulWidget {
  const A1CCalculatorScreen({super.key});

  @override
  State<A1CCalculatorScreen> createState() => _A1CCalculatorScreenState();
}

class _A1CCalculatorScreenState extends State<A1CCalculatorScreen> {
  final _svc = GlucoseService();
  final _profileSvc = ProfileService();

  // Estimated A1C formula: (avgGlucose + 46.7) / 28.7

  Widget _emptyCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _card(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'a1c.no_readings_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'a1c.no_readings_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/a1c_add_glucose_fallback'),
            child: Text('a1c.add_glucose_cta'.tr()),
          ),
        ],
      ),
    );
  }

  BoxDecoration _card(ColorScheme cs) => BoxDecoration(
    color: cs.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text('a1c.title'.tr()), centerTitle: true),
        body: SafeArea(
          child: StreamBuilder<List<GlucoseEntry>>(
            stream: _svc.rangeStream(days: 90),
            builder: (context, snap) {
              final entries = snap.data ?? [];
              final hasData = entries.isNotEmpty;
              final avg = hasData
                  ? entries.map((e) => e.value).fold<num>(0, (a, b) => a + b) /
                        entries.length
                  : null;
              final estA1c = avg != null ? (avg + 46.7) / 28.7 : null;

              final uid = FirebaseAuth.instance.currentUser?.uid;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Hero / empty / summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _card(cs),
                      child: hasData
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'a1c.estimated_title'.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  '${estA1c!.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(height: 12),
                              ],
                            )
                          : _emptyCard(cs),
                    ),

                    const SizedBox(height: 12),

                    // Recommended target
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _card(cs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.track_changes, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'a1c.recommended_title'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                '> 7.0%',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'a1c.recommended_desc'.tr(),
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reference levels
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _card(cs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'a1c.reference_title'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _refRow(
                            cs,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1B4332)  // Darker green for dark mode
                                : const Color(0xFFD1F4E0),  // Slightly darker/more saturated green for light mode
                            dot: const Color(0xFF2BA24C),
                            title: 'a1c.ref_normal_title'.tr(),
                            desc: 'a1c.ref_normal_desc'.tr(),
                          ),
                          const SizedBox(height: 8),
                          _refRow(
                            cs,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF4A3800)  // Darker yellow for dark mode
                                : const Color(0xFFFFEBAA),  // More saturated yellow for light mode
                            dot: const Color(0xFFF7B500),
                            title: 'a1c.ref_prediabetes_title'.tr(),
                            desc: 'a1c.ref_prediabetes_desc'.tr(),
                          ),
                          const SizedBox(height: 8),
                          _refRow(
                            cs,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF4A2A1A)  // Darker orange for dark mode
                                : const Color(0xFFFFD4B3),  // More saturated orange for light mode
                            dot: const Color(0xFFEA580C),
                            title: 'a1c.ref_controlled_title'.tr(),
                            desc: 'a1c.ref_controlled_desc'.tr(),
                          ),
                          const SizedBox(height: 8),
                          _refRow(
                            cs,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF4A1A1A)  // Darker red for dark mode
                                : const Color(0xFFFFCCCC),  // More saturated red for light mode
                            dot: const Color(0xFFD32F2F),
                            title: 'a1c.ref_uncontrolled_title'.tr(),
                            desc: 'a1c.ref_uncontrolled_desc'.tr(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'a1c.ref_note'.tr(),
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _refRow(
    ColorScheme cs, {
    required Color color,
    required Color dot,
    required String title,
    required String desc,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: dot),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

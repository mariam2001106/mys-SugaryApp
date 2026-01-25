import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mysugaryapp/models/glucose_entry_model.dart';
import 'package:mysugaryapp/models/user_profile.dart';
import 'package:mysugaryapp/services/glucose_service.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/widgets/firestore_trend_chart.dart';

class TrendScreen extends StatefulWidget {
  final bool isArabic;
  const TrendScreen({super.key, this.isArabic = false});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  final _glucoseSvc = GlucoseService();
  final _profileSvc = ProfileService();
  final _timeFmt = DateFormat('h:mm a');

  final List<int> _hourOptions = const [6, 12, 24];
  int _selectedHours = 24;

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.isArabic || context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text('trends.title'.tr()),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.timeline),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(16), child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(child: Text('trends.not_signed_in'.tr()));
    }

    return StreamBuilder<UserProfile?>(
      stream: _profileSvc.streamProfile(uid),
      builder: (context, profSnap) {
        if (profSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = profSnap.data;
        if (profile == null) {
          return Center(child: Text('trends.no_profile'.tr()));
        }
        final g = profile.glucoseRanges;

        return StreamBuilder<List<GlucoseEntry>>(
          stream: _glucoseSvc.rangeStream(hours: _selectedHours),
          builder: (context, gsnap) {
            if (gsnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final readings = gsnap.data ?? [];
            return ListView(
              children: [
                _timeSelector(),
                const SizedBox(height: 16),
                _chartCard(g, readings),
                const SizedBox(height: 16),
                _lastReadingCard(readings),
                const SizedBox(height: 12),
                _a1cCard(readings),
              ],
            );
          },
        );
      },
    );
  }

  Widget _timeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _hourOptions
          .map(
            (h) => ChoiceChip(
              label: Text('$h ${'trends.range_label'.tr()}'),
              selected: _selectedHours == h,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: _selectedHours == h 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: _selectedHours == h
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              onSelected: (_) => setState(() => _selectedHours = h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedHours == h
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _chartCard(GlucoseRanges g, List<GlucoseEntry> readings) {
    if (readings.isEmpty) {
      return _emptyChart();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          elevation: 1,
          child: FirestoreTrendChart(
            selectedHours: _selectedHours,
            veryLow: g.veryLow,
            targetMin: g.targetMin,
            targetMax: g.targetMax,
            veryHigh: g.veryHigh,
          ),
        ),
      ),
    );
  }

  Widget _emptyChart() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: SizedBox(
        height: 240,
        child: Center(
          child: Text(
            'trends.no_period_data'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _lastReadingCard(List<GlucoseEntry> readings) {
    final lr = readings.isEmpty ? null : readings.last;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: lr == null
            ? Center(child: Text('cards.no_data'.tr()))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'cards.last_reading_title'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lr.value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'units.mgdl'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }

  Widget _a1cCard(List<GlucoseEntry> readings) {
    if (readings.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Center(child: Text('cards.no_data'.tr())),
        ),
      );
    }

    final avg =
        readings.map((e) => e.value).fold<num>(0, (a, b) => a + b) /
        readings.length;
    final a1c = (avg + 46.7) / 28.7;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.calculate, color: Theme.of(context).colorScheme.secondary, size: 24),
            const SizedBox(height: 6),
            Text(
              'a1c.last_30_days'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '${a1c.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'a1c.status_controlled'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

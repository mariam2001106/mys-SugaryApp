import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysugaryapp/models/glucose_entry_model.dart';
import 'package:mysugaryapp/models/user_profile.dart';
import 'package:mysugaryapp/services/glucose_service.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/theme/app_theme.dart';

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
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: _selectedHours == h ? Colors.white : Colors.black87,
                fontWeight: _selectedHours == h
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              onSelected: (_) => setState(() => _selectedHours = h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedHours == h
                      ? Colors.black
                      : Colors.grey.shade300,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _chartCard(GlucoseRanges g, List<GlucoseEntry> readings) {
    final targetMin = g.targetMin.toDouble();
    final targetMax = g.targetMax.toDouble();

    if (readings.isEmpty) {
      return _emptyChart();
    }

    final sorted = [...readings]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();

    final minReading = sorted.map((e) => e.value.toDouble()).reduce(math.min);
    final maxReading = sorted.map((e) => e.value.toDouble()).reduce(math.max);

    final lowBound = math.min(minReading, targetMin);
    final highBound = math.max(maxReading, targetMax);
    final span = (highBound - lowBound).abs();
    final padding = span == 0
        ? (highBound == 0 ? 1.0 : highBound * 0.1)
        : span * 0.1;
    final minY = (lowBound - padding);
    final maxY = (highBound + padding);

    String xLabel(double v) {
      final idx = v.round();
      if (idx < 0 || idx >= sorted.length) return '';
      return _timeFmt.format(sorted[idx].timestamp);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1.25,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                        y1: targetMin,
                        y2: targetMax,
                        color: AppColors.gray.withOpacity(0.12),
                      ),
                    ],
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map(
                            (s) => LineTooltipItem(
                              s.y.toStringAsFixed(0),
                              const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (targetMax - targetMin).abs(),
                        getTitlesWidget: (v, _) {
                          if (v == targetMin || v == targetMax) {
                            return Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 11),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: sorted.isEmpty
                            ? 1
                            : (sorted.length / 3).clamp(1, 6).toDouble(),
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= sorted.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              xLabel(v),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: targetMin,
                        color: Colors.blueGrey.withOpacity(0.6),
                        dashArray: const [6, 6],
                        strokeWidth: 1,
                      ),
                      HorizontalLine(
                        y: targetMax,
                        color: Colors.blueGrey.withOpacity(0.6),
                        dashArray: const [6, 6],
                        strokeWidth: 1,
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      barWidth: 2.8,
                      color: const Color(0xFF4A90E2),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, idx) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF4A90E2),
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF4A90E2).withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyChart() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
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
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: lr == null
            ? Center(child: Text('cards.no_data'.tr()))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.show_chart,
                    color: Color(0xFF4A90E2),
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
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  Text(
                    'units.mgdl'.tr(),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
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
          side: BorderSide(color: Colors.grey.shade300),
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
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.calculate, color: Colors.green, size: 24),
            const SizedBox(height: 6),
            Text(
              'a1c.last_30_days'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '${a1c.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD61C4E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'a1c.status_controlled'.tr(),
                style: const TextStyle(
                  color: Colors.white,
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

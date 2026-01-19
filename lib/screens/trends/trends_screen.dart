import 'dart:math' as math;

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
  const TrendScreen({super.key});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  final _glucoseSvc = GlucoseService();
  final _profileSvc = ProfileService();
  final _timeFmt = DateFormat('h:mm a');

  // User-selectable time ranges
  final List<int> _ranges = const [1, 3, 6, 12, 24];
  int _selectedRange = 24;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text('trends.title'.tr()), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: uid == null
              ? Center(
                  child: Text(
                    'Not signed in',
                    style: TextStyle(color: cs.onSurface),
                  ),
                )
              : StreamBuilder<UserProfile?>(
                  stream: _profileSvc.streamProfile(uid),
                  builder: (context, profSnap) {
                    if (profSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final profile = profSnap.data;
                    if (profile == null) {
                      return Center(
                        child: Text(
                          'No profile data yet',
                          style: TextStyle(color: cs.onSurface),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        _buildRangeSelector(cs),
                        const SizedBox(height: 12),
                        Expanded(
                          child: StreamBuilder<List<GlucoseEntry>>(
                            stream: _glucoseSvc.rangeStream(
                              hours: _selectedRange,
                            ),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final entries = snap.data ?? [];

                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildChartCard(
                                      cs,
                                      profile.glucoseRanges,
                                      entries,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLastReadingCard(cs, entries),
                                    const SizedBox(height: 12),
                                    _buildAverageA1CCard(cs, entries),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildRangeSelector(ColorScheme cs) {
    return Align(
      alignment: Alignment.centerRight,
      child: DropdownButtonHideUnderline(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withOpacity(0.12)),
          ),
          child: DropdownButton<int>(
            value: _selectedRange,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            borderRadius: BorderRadius.circular(12),
            items: _ranges
                .map(
                  (h) => DropdownMenuItem(value: h, child: Text('Last $h hr')),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedRange = v);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(
    ColorScheme cs,
    GlucoseRanges ranges,
    List<GlucoseEntry> entries,
  ) {
    final targetMin = ranges.targetMin.toDouble();
    final targetMax = ranges.targetMax.toDouble();

    // Generate spots from actual data only
    final spots = entries.isEmpty
        ? <FlSpot>[]
        : entries.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.value.toDouble());
          }).toList();

    // Calculate Y-axis bounds dynamically
    final minReading = entries.isEmpty
        ? targetMin
        : entries.map((e) => e.value.toDouble()).reduce(math.min);
    final maxReading = entries.isEmpty
        ? targetMax
        : entries.map((e) => e.value.toDouble()).reduce(math.max);

    final lowBound = math.min(minReading, targetMin);
    final highBound = math.max(maxReading, targetMax);
    final span = (highBound - lowBound).abs();
    final padding = span == 0 ? highBound * 0.1 : span * 0.1;
    final minY = lowBound - padding;
    final maxY = highBound + padding;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.35,
        child: entries.isEmpty
            ? Center(
                child: Text(
                  'No readings in selected range',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              )
            : LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                        y1: targetMin,
                        y2: targetMax,
                        color: AppColors.gray.withOpacity(0.16),
                      ),
                    ],
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final idx = s.x.toInt();
                        if (idx < 0 || idx >= entries.length) return null;
                        return LineTooltipItem(
                          '${s.y.toStringAsFixed(0)} ${entries[idx].unit}',
                          TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '\n${_timeFmt.format(entries[idx].timestamp)}',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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
                    // Y-axis: show only user's targetMin and targetMax
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: (targetMax - targetMin).abs(),
                        getTitlesWidget: (value, meta) {
                          // Round to handle floating point comparison
                          final roundedValue = value.round().toDouble();
                          final roundedMin = targetMin.round().toDouble();
                          final roundedMax = targetMax.round().toDouble();

                          if (roundedValue == roundedMin ||
                              roundedValue == roundedMax) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                value.round().toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    // X-axis: dynamic time labels from entries
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: entries.length <= 1
                            ? 1
                            : (entries.length / 4).clamp(1.0, double.infinity),
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          if (idx < 0 || idx >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _timeFmt.format(entries[idx].timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
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
                        color: AppColors.darkRed.withOpacity(0.45),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                      HorizontalLine(
                        y: targetMax,
                        color: AppColors.darkRed.withOpacity(0.45),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      barWidth: 3,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.darkRed.withOpacity(0.85),
                          AppColors.darkBlue.withOpacity(0.85),
                          AppColors.gray.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, idx) =>
                            FlDotCirclePainter(
                              radius: 3.4,
                              color: cs.surface,
                              strokeColor: AppColors.darkBlue,
                              strokeWidth: 1.4,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.darkRed.withOpacity(0.15),
                            AppColors.darkBlue.withOpacity(0.15),
                            AppColors.gray.withOpacity(0.15),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLastReadingCard(ColorScheme cs, List<GlucoseEntry> entries) {
    if (entries.isEmpty) {
      return _buildInfoCard(
        cs,
        title: 'Last Reading',
        value: '—',
        subtitle: 'No readings yet',
      );
    }

    final lastEntry = entries.last;
    final now = DateTime.now();
    final diff = now.difference(lastEntry.timestamp.toLocal());
    final timeAgo = _humanizeDuration(diff);

    return _buildInfoCard(
      cs,
      title: 'Last Reading',
      value: '${lastEntry.value.toStringAsFixed(0)} ${lastEntry.unit}',
      subtitle: timeAgo,
    );
  }

  Widget _buildAverageA1CCard(ColorScheme cs, List<GlucoseEntry> entries) {
    if (entries.isEmpty) {
      return _buildInfoCard(
        cs,
        title: 'Average A1C',
        value: '—',
        subtitle: 'No data yet',
      );
    }

    final avgGlucose =
        entries.map((e) => e.value).reduce((a, b) => a + b) / entries.length;
    final a1c = (avgGlucose + 46.7) / 28.7;

    return _buildInfoCard(
      cs,
      title: 'Average A1C',
      value: '${a1c.toStringAsFixed(2)}%',
      subtitle: '${entries.length} reading${entries.length == 1 ? '' : 's'}',
    );
  }

  Widget _buildInfoCard(
    ColorScheme cs, {
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _humanizeDuration(Duration d) {
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} hr ago';
    return '${d.inDays} d ago';
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mysugaryapp/models/glucose_entry_model.dart';
import 'package:mysugaryapp/services/glucose_service.dart';

class A1CCard extends StatelessWidget {
  A1CCard({super.key});

  final _svc = GlucoseService();

  double _a1cFromAvg(num avgMgdl) => ((avgMgdl + 46.7) / 28.7);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<GlucoseEntry>>(
      stream: _svc.rangeStream(days: 90), // use last ~3 months
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _card(
            cs,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return _card(
            cs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.estimated_a1c_title'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'home.estimated_a1c_none'.tr(),
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          );
        }
        final avg =
            entries.map((e) => e.value).fold<num>(0, (a, b) => a + b) /
            entries.length;
        final a1c = _a1cFromAvg(avg);

        return _card(
          cs,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.estimated_a1c_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${a1c.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'trends.avg'.tr(args: [avg.toStringAsFixed(1)]),
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(ColorScheme cs, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

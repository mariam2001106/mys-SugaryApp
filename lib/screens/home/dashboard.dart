import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as fr;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:mysugaryapp/models/user_profile.dart';
import 'package:mysugaryapp/models/glucose_entry_model.dart';
import 'package:mysugaryapp/screens/meals/meals.screen.dart';
import 'package:mysugaryapp/screens/reminders/reminders_screen.dart';
import 'package:mysugaryapp/screens/setup/personal_setup_wizerd.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/services/glucose_service.dart';

// A1C calculator + optional A1C summary card
import 'package:mysugaryapp/screens/trends/a1c_calculator_screen.dart';
import 'package:mysugaryapp/widgets/a1c_card.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Future<void> _toggleLocale() async {
    final current = context.locale.languageCode;
    final next = current == 'ar' ? const Locale('en') : const Locale('ar');
    try {
      await context.setLocale(next);
    } catch (_) {}
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await ProfileService().updatePartial(user.uid, {
          'locale': next.languageCode,
        });
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Widget _metricCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool filled = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.05),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: Directionality.of(context) == fr.TextDirection.rtl
                ? TextAlign.right
                : TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _onboardingPrompt(BuildContext context, String uid) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 72),
              const SizedBox(height: 14),
              const Text(
                'أكمل إعداد حسابك',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'يجب عليك إكمال بعض الأسئلة لتقديم تجربة مخصصة. اضغط للبدء.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => PersonalSetupWizard(uid: uid),
                  ),
                ),
                child: const Text('ابدأ الإعداد'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyStateCard() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.05),
            cs.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 48,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'home.empty_glucose_title'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'home.empty_glucose_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/a1c_add_glucose_fallback'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.bloodtype, size: 20),
              label: Text(
                'home.empty_glucose_cta'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final authUser = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    if (uid == null) {
      return Directionality(
        textDirection: context.locale.languageCode == 'ar'
            ? fr.TextDirection.rtl
            : fr.TextDirection.ltr,
        child: const Scaffold(body: Center(child: Text('غير مسجل الدخول'))),
      );
    }

    final svc = ProfileService();

    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? fr.TextDirection.rtl
          : fr.TextDirection.ltr,
      child: StreamBuilder<UserProfile?>(
        stream: svc.streamProfile(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return Scaffold(
              body: Center(child: Text('حدث خطأ: ${snap.error}')),
            );
          }

          final profile = snap.data;
          if (profile == null || !profile.onboardingComplete) {
            return _onboardingPrompt(context, uid);
          }

          final displayNameFallback =
              (authUser?.displayName?.trim().isNotEmpty == true)
              ? authUser!.displayName!.trim()
              : (authUser?.email != null
                    ? authUser!.email!.split('@')[0]
                    : 'المستخدم');

          return Scaffold(
            backgroundColor: cs.surfaceContainerLowest,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with logo + controls
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary.withValues(alpha: 0.08),
                              cs.secondary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayNameFallback,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _iconSquare(
                                  icon:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Icons.dark_mode
                                      : Icons.wb_sunny_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Toggle theme (hook needed)',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _iconSquare(
                                  icon: Icons.language,
                                  onTap: _toggleLocale,
                                ),
                                const SizedBox(width: 8),
                                _iconSquare(
                                  icon: Icons.notifications_outlined,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RemindersScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Metrics cards: Latest, Weekly, Meals, A1C
                      StreamBuilder<List<GlucoseEntry>>(
                        stream: GlucoseService().recentStream(limit: 1),
                        builder: (context, latestSnap) {
                          final latestReading =
                              latestSnap.data?.isNotEmpty == true
                              ? '${latestSnap.data!.first.value.toStringAsFixed(0)} ${latestSnap.data!.first.unit == 'mg/dL' ? 'home.mg_dl_unit'.tr() : latestSnap.data!.first.unit}'
                              : '${'home.latest_reading_none'.tr()} ${'home.mg_dl_unit'.tr()}';

                          return _metricCard(
                            icon: Icons.bloodtype_outlined,
                            color: cs.error,
                            title: 'home.latest_reading_title'.tr(),
                            subtitle: latestReading,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      StreamBuilder<List<GlucoseEntry>>(
                        stream: GlucoseService().rangeStream(days: 7),
                        builder: (context, weeklySnap) {
                          final entries = weeklySnap.data ?? [];
                          final weeklyAvg = entries.isNotEmpty
                              ? entries
                                        .map((e) => e.value)
                                        .reduce((a, b) => a + b) /
                                    entries.length
                              : null;
                          final weeklyAvgStr = weeklyAvg != null
                              ? '${weeklyAvg.toStringAsFixed(0)} ${'home.mg_dl_unit'.tr()}'
                              : 'home.weekly_average_none'.tr();

                          return _metricCard(
                            icon: Icons.trending_up,
                            color: cs.primary,
                            title: 'home.weekly_average_title'.tr(),
                            subtitle: weeklyAvgStr,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _metricCard(
                        icon: Icons.lunch_dining,
                        color: cs.secondary,
                        title: 'home.todays_meals_title'.tr(),
                        subtitle: 'home.todays_meals_value'.tr(),
                      ),
                      const SizedBox(height: 14),

                      // Optional: live A1C summary card (remove if you don't want A1C on Home)
                      A1CCard(),

                      const SizedBox(height: 20),

                      // Quick actions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.surfaceContainerHighest, cs.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cs.primary.withValues(alpha: 0.1),
                                    cs.secondary.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    size: 20,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'home.quick_title'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _quickActionButton(
                                  icon: Icons.bloodtype,
                                  color: cs.error,
                                  label: 'home.quick_add_glucose'.tr(),
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed('/a1c_add_glucose_fallback'),
                                ),
                                _quickActionButton(
                                  icon: Icons.lunch_dining,
                                  color: cs.secondary,
                                  label: 'home.quick_add_meal'.tr(),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const MealLogScreen(),
                                    ),
                                  ),
                                ),
                                _quickActionButton(
                                  icon: Icons.calculate_outlined,
                                  color: cs.primary,
                                  label: 'a1c.title'.tr(),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const A1CCalculatorScreen(),
                                    ),
                                  ),
                                ),
                                _quickActionButton(
                                  icon: Icons.insights,
                                  color: cs.tertiary,
                                  label: 'home.quick_view_trends'.tr(),
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed('/trends'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // NotificationsService.showNotification(body: "body", title: "title", payload: "payload");
                                  },
                                  child: const Text('show'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // NotificationsService.showNotification(body: "body", title: "title", payload: "payload");
                                    // NotificationsService.showPreiodicNotification(body: "body", title: "timely", payload: "payload");
                                    // NotificationsService.cancelNotification(1);
                                  },
                                  child: const Text('timing a noti'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Readings display or empty state
                      StreamBuilder<List<GlucoseEntry>>(
                        stream: GlucoseService().recentStream(limit: 10),
                        builder: (context, glucoseSnap) {
                          final entries = glucoseSnap.data ?? [];

                          if (entries.isEmpty) {
                            return _emptyStateCard();
                          }

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary.withValues(alpha: 0.05),
                                  cs.secondary.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bloodtype_outlined,
                                      color: cs.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'home.recent_readings_title'.tr(),
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: entries.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, index) {
                                    final entry = entries[index];
                                    final timestamp = entry.timestamp;
                                    final formattedDate =
                                        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} - ${timestamp.day}/${timestamp.month}/${timestamp.year}';

                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: cs.onSurface.withValues(
                                            alpha: 0.1,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: cs.error.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              entry.value.toStringAsFixed(0),
                                              style: TextStyle(
                                                color: cs.error,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entry.unit == 'mg/dL'
                                                      ? 'home.mg_dl_unit'.tr()
                                                      : entry.unit,
                                                  style: TextStyle(
                                                    color: cs.onSurface
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    color: cs.onSurface
                                                        .withValues(alpha: 0.5),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (entry.note.isNotEmpty)
                                            Tooltip(
                                              message: entry.note,
                                              child: Icon(
                                                Icons.note_outlined,
                                                size: 18,
                                                color: cs.onSurface.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
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
        },
      ),
    );
  }

  Widget _iconSquare({required IconData icon, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surface, cs.surfaceContainerHighest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );
  }
}

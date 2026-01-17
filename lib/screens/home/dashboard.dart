import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as fr;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:mysugaryapp/models/user_profile.dart';
import 'package:mysugaryapp/screens/reminders/reminders_screen.dart';
import 'package:mysugaryapp/screens/setup/personal_setup_wizerd.dart';
import 'package:mysugaryapp/services/profile_service.dart';

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: filled ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
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
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.12), width: 1),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _rowItem(String label, String value) {
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Icon(
            Icons.monitor_heart_outlined,
            size: 44,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'home.empty_glucose_title'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home.empty_glucose_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.65),
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('home.quick_add_glucose'.tr())),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.bloodtype, size: 18),
            label: Text('home.empty_glucose_cta'.tr()),
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
            backgroundColor: cs.surface,
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
                      // Header with name + controls
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${'home.welcome'.tr()}, $displayNameFallback ',
                                      ),
                                      const WidgetSpan(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 2),
                                          child: Text(
                                            '👋',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'home.health_overview'.tr(),
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.65),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              // Theme toggle placeholder button (visual only)
                              _iconSquare(
                                icon:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Icons.dark_mode
                                    : Icons.wb_sunny_outlined,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Toggle theme (hook needed)',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              // Language toggle
                              _iconSquare(
                                icon: Icons.language,
                                onTap: _toggleLocale,
                              ),
                              const SizedBox(width: 8),
                              // Notifications icon -> Reminders screen
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

                      const SizedBox(height: 16),

                      // Metrics cards in order: Latest, Weekly, Meals, A1C
                      _metricCard(
                        icon: Icons.bloodtype_outlined,
                        color: Colors.red.shade600,
                        title: 'home.latest_reading_title'.tr(),
                        subtitle: 'home.latest_reading_none'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _metricCard(
                        icon: Icons.trending_up,
                        color: cs.primary,
                        title: 'home.weekly_average_title'.tr(),
                        subtitle: 'home.weekly_average_none'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _metricCard(
                        icon: Icons.lunch_dining,
                        color: Colors.green.shade600,
                        title: 'home.todays_meals_title'.tr(),
                        subtitle: 'home.todays_meals_value'
                            .tr(), // e.g., "0 meals"
                      ),
                      const SizedBox(height: 12),
                      _metricCard(
                        icon: Icons.calculate_outlined,
                        color: cs.primary,
                        title: 'home.estimated_a1c_title'.tr(),
                        subtitle: 'home.estimated_a1c_none'.tr(),
                        filled: true,
                      ),

                      const SizedBox(height: 16),

                      // Quick actions block centered
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.show_chart, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'home.quick_title'.tr(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _quickActionButton(
                                  icon: Icons.bloodtype,
                                  color: Colors.red.shade600,
                                  label: 'home.quick_add_glucose'.tr(),
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'home.quick_add_glucose'.tr(),
                                          ),
                                        ),
                                      ),
                                ),
                                _quickActionButton(
                                  icon: Icons.lunch_dining,
                                  color: Colors.green.shade600,
                                  label: 'home.quick_add_meal'.tr(),
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'home.quick_add_meal'.tr(),
                                          ),
                                        ),
                                      ),
                                ),
                                _quickActionButton(
                                  icon: Icons.insights,
                                  color: Colors.blue.shade600,
                                  label: 'home.quick_view_trends'.tr(),
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'home.quick_view_trends'.tr(),
                                          ),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Empty state CTA
                      _emptyStateCard(),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, size: 18, color: cs.onSurface),
      ),
    );
  }
}

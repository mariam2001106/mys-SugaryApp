import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/screens/profile/profile_screen.dart';
import 'dashboard.dart';
import 'package:flutter/rendering.dart' as fr;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Provide ALL tabs here, including ProfileScreen.
  late final List<Widget> _pages = const [
    Dashboard(),
    _PlaceholderPage(titleKey: 'home.glucose'), // use translation keys
    _PlaceholderPage(titleKey: 'home.meals'),
    _PlaceholderPage(titleKey: 'home.trends'),
    ProfileScreen(),
  ];

  void _onTab(int i) => setState(() => _currentIndex = i);

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Toggle locale between Arabic and English and persist to Firestore (users/<uid>.locale)
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
    // Rebuild to reflect new direction and labels
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? fr.TextDirection.rtl : fr.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'home.title'.tr() : 'home.title'.tr()),
          centerTitle: true,
          actions: [
            // Language switch: Arabic <-> English
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    isArabic ? 'العربية' : 'Arabic',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Switch(
                  value: !isArabic, // ON means English
                  onChanged: (_) => _toggleLocale(),
                  activeColor: cs.primary,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    isArabic ? 'إنجليزي' : 'English',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(child: _pages[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: cs.primary,
          unselectedItemColor: cs.onSurface.withValues(alpha: 0.6),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              label: 'home.nav_home'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bloodtype_outlined),
              label: 'home.nav_glucose'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.restaurant_outlined),
              label: 'home.nav_meals'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.show_chart_outlined),
              label: 'home.nav_trends'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: 'home.nav_profile'.tr(),
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: Text('home.logout'.tr()),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String titleKey;
  const _PlaceholderPage({required this.titleKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? fr.TextDirection.rtl : fr.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(titleKey.tr()), centerTitle: true),
        body: Center(
          child: Text(
            '${'home.under_construction'.tr()}: ${titleKey.tr()}',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }
}

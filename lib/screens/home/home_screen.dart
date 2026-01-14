import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as fr;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';
import 'package:mysugaryapp/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    Dashboard(),
    _PlaceholderPage(titleKey: 'home.glucose'),
    _PlaceholderPage(titleKey: 'home.meals'),
    _PlaceholderPage(titleKey: 'home.trends'),
    ProfileScreen(),
  ];

  void _onTab(int i) => setState(() => _currentIndex = i);

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? fr.TextDirection.rtl : fr.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text('home.title'.tr()), centerTitle: true),
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

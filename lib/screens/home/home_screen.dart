import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as fr;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';
import 'package:mysugaryapp/screens/profile/profile_screen.dart';
import 'package:mysugaryapp/screens/glucose/glucose_screen.dart';
import 'package:mysugaryapp/screens/meals/meals.screen.dart';
import 'package:mysugaryapp/screens/trends/trends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    Dashboard(),
    GlucoseScreen(),
    MealLogScreen(),
    TrendScreen(),
    ProfileScreen(),
  ];

  void _onTab(int i) => setState(() => _currentIndex = i);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? fr.TextDirection.rtl : fr.TextDirection.ltr,
      child: Scaffold(
        appBar: _currentIndex == 0
            ? AppBar(title: Text('home.title'.tr()), centerTitle: true)
            : null,
        body: SafeArea(child: _pages[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTab,
          type: BottomNavigationBarType.shifting,
          selectedItemColor: cs.primary,
          unselectedItemColor: cs.onSurface.withValues(alpha: 0.6),
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              label: 'home.nav_home'.tr(),
              backgroundColor: cs.surface,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bloodtype_outlined),
              label: 'home.nav_glucose'.tr(),
              backgroundColor: cs.surface,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.restaurant_outlined),
              label: 'home.nav_meals'.tr(),
              backgroundColor: cs.surface,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.timeline_outlined),
              label: 'home.nav_trends'.tr(),
              backgroundColor: cs.surface,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: 'home.nav_profile'.tr(),
              backgroundColor: cs.surface,
            ),
          ],
        ),
      ),
    );
  }
}

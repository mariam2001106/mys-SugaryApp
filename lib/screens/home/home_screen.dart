import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _pages = <Widget>[
    const Dashboard(),
    const _PlaceholderPage(title: 'الجلوكوز'),
    const _PlaceholderPage(title: 'الوجبات'),
    const _PlaceholderPage(title: 'الرسوم البيانية'),
    const _PlaceholderPage(title: 'الملف الشخصي'),
  ];

  void _onTab(int i) => setState(() => _currentIndex = i);

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate/listeners will show SignInScreen
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(child: _pages[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: cs.primary,
          unselectedItemColor: cs.onSurface.withValues(alpha: 0.6),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bloodtype_outlined),
              label: 'الجلوكوز',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_outlined),
              label: 'الوجبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              label: 'الاتجاهات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'الملف',
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: const Text('تسجيل الخروج'),
                  onTap: _signOut,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: Center(
          child: Text('قيد التطوير: $title', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
        ),
      ),
    );
  }
}
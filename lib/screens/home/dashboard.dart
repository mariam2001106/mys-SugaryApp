import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mysugaryapp/screens/setup/personal_setup_wizerd.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/models/user_profile.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  Widget _card({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool filled = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: filled ? cs.surfaceVariant : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withOpacity(.04)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(.12),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: cs.onSurface.withOpacity(.8), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton(BuildContext context, {required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.onSurface.withOpacity(.06)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cs = Theme.of(context).colorScheme;

    if (uid == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: Text('غير مسجل الدخول'))),
      );
    }

    final svc = ProfileService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserProfile?>(
        stream: svc.streamProfile(uid),
        builder: (context, snap) {
          // handle loading / error
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return Scaffold(body: Center(child: Text('حدث خطأ: ${snap.error}')));
          }

          final profile = snap.data;

          // If profile missing or onboarding incomplete, show full prompt to run wizard
          if (profile == null || !profile.onboardingComplete) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('الرئيسية'),
                centerTitle: true,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.quiz_outlined, size: 72),
                      const SizedBox(height: 14),
                      const Text('أكمل إعداد حسابك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text(
                        'يجب عليك إكمال بعض الأسئلة لتقديم تجربة مخصصة. اضغط للبدء.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PersonalSetupWizard(uid: uid))),
                        child: const Text('ابدأ الإعداد'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final ranges = profile.glucoseRanges;
          final med = profile.medicationName ?? '—';
          final displayName = 'مرحبًا ';

          return Scaffold(
            appBar: AppBar(
              title: const Text('الصفحة الرئيسية'),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: cs.onSurface,
              actions: [
                IconButton(onPressed: () {}, icon: Icon(Icons.search, color: cs.onSurface)),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                              ),
                              const SizedBox(height: 6),
                              Text('نظرة عامة على الصحة', style: TextStyle(color: cs.onSurface.withOpacity(.6))),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(onPressed: () {}, icon: Icon(Icons.brightness_2_outlined, color: cs.onSurface)),
                            IconButton(onPressed: () {}, icon: Icon(Icons.language_outlined, color: cs.onSurface)),
                            IconButton(onPressed: () {}, icon: Icon(Icons.notifications_outlined, color: cs.onSurface)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Cards list (stacked look)
                    Column(
                      children: [
                        _card(
                          context: context,
                          icon: Icons.bloodtype,
                          iconColor: Colors.red.shade600,
                          title: 'أحدث قراءة',
                          subtitle: 'لا توجد قراءات',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _card(
                          context: context,
                          icon: Icons.trending_up,
                          iconColor: cs.primary,
                          title: 'المتوسط الأسبوعي',
                          subtitle: 'لا توجد بيانات',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _card(
                          context: context,
                          icon: Icons.restaurant,
                          iconColor: Colors.green.shade600,
                          title: 'وجبات اليوم',
                          subtitle: '0 وجبات',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _card(
                          context: context,
                          icon: Icons.calculate_outlined,
                          iconColor: cs.primary.withOpacity(.9),
                          title: 'تقدير A1C',
                          subtitle: 'لا توجد بيانات',
                          filled: true,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Quick actions card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('إجراءات سريعة', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
                            const SizedBox(height: 12),
                            _quickActionButton(
                              context,
                              icon: Icons.bloodtype,
                              label: 'إضافة قراءة جلوكوز',
                              color: Colors.red.shade600,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إضافة قراءة')));
                              },
                            ),
                            const SizedBox(height: 12),
                            _quickActionButton(
                              context,
                              icon: Icons.restaurant,
                              label: 'إضافة وجبة',
                              color: Colors.green.shade600,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إضافة وجبة')));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Account summary card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('الحساب', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
                            const SizedBox(height: 6),
                            _rowItem('المعرف', profile.uid),
                            _rowItem('نوع السكري', profile.diabetesType.name),
                            _rowItem('حالة الإعداد', profile.onboardingComplete ? 'مكتمل' : 'غير مكتمل'),
                            const SizedBox(height: 6),
                            Text('نصائح', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
                            const SizedBox(height: 6),
                            Text('- اضغط على "إضافة قراءة جلوكوز" لتسجيل مستوى الجلوكوز', style: TextStyle(color: cs.onSurface.withOpacity(.7))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Text(value, textAlign: TextAlign.right),
        ],
      ),
    );
  }
}
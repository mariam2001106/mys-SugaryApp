import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:flutter/rendering.dart' as fr;


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _showSignOutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: context.locale.languageCode == 'ar'
            ? fr.TextDirection.rtl
            : fr.TextDirection.ltr,
        child: AlertDialog(
          title: Text('profile.logout'.tr()),
          content: Text('profile.confirm_logout'.tr()),
          actions: [
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('profile.cancel'.tr()),
                ),
                // ElevatedButton inherits new theme: minWidth=0, minHeight=52; ButtonBar gives finite width.
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('profile.logout'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile.logout'.tr())));
      }
    }
  }

  Future<void> _setLocaleAndSave(BuildContext context, String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await context.setLocale(Locale(code));
    } catch (_) {}
    try {
      await ProfileService().updatePartial(user.uid, {'locale': code});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    final displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (user?.email != null ? user!.email!.split('@')[0] : 'المستخدم');

    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? fr.TextDirection.rtl
          : fr.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text('profile.title'.tr()), centerTitle: true),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primary.withOpacity(.12),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'م',
                      style: TextStyle(fontSize: 24, color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user?.email ?? '-',
                          style: TextStyle(color: cs.onSurface.withOpacity(.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person, color: cs.onSurface),
                        title: Text('profile.name'.tr()),
                        subtitle: Text(displayName),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.email_outlined,
                          color: cs.onSurface,
                        ),
                        title: Text('profile.email'.tr()),
                        subtitle: Text(user?.email ?? '-'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'profile.language'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton(
                            onPressed: () => _setLocaleAndSave(context, 'ar'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  context.locale.languageCode == 'ar'
                                  ? cs.primary
                                  : cs.surface,
                              foregroundColor:
                                  context.locale.languageCode == 'ar'
                                  ? cs.onPrimary
                                  : cs.onSurface,
                            ),
                            child: const Text('العربية'),
                          ),
                          FilledButton(
                            onPressed: () => _setLocaleAndSave(context, 'en'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  context.locale.languageCode == 'en'
                                  ? cs.primary
                                  : cs.surface,
                              foregroundColor:
                                  context.locale.languageCode == 'en'
                                  ? cs.onPrimary
                                  : cs.onSurface,
                            ),
                            child: const Text('English'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _showSignOutDialog(context),
                  child: Text(
                    'profile.logout'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

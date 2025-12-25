import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as fr;
import 'package:easy_localization/easy_localization.dart';
import 'package:mysugaryapp/screens/setup/personal_setup_wizerd.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/services/auth_service.dart';
import 'package:mysugaryapp/widgets/brabd_logo.dart';
import '../home/home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('errors.unexpected'.tr())));
        }
        return;
      }

      final uid = user.uid;
      final svc = ProfileService();

      // Server read (persistence is disabled globally, but this enforces server read)
      final docSnap = await svc.getUserDocFromServer(uid);

      if (docSnap.exists) {
        final data = docSnap.data()!;
        final localeCode = (data['locale'] as String?) ?? '';
        if (localeCode.isNotEmpty &&
            context.locale.languageCode != localeCode) {
          try {
            await context.setLocale(Locale(localeCode));
          } catch (_) {}
        }

        final onboardingComplete =
            (data['onboardingComplete'] ?? false) as bool;
        if (onboardingComplete) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
          return;
        } else {

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => PersonalSetupWizard(uid: uid)),
            );
          }
          return;
        }
      } else {
        await svc.createIfMissing(uid);
        try {
          await svc.updatePartial(uid, {'locale': context.locale.languageCode});
        } catch (_) {}
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => PersonalSetupWizard(uid: uid)),
          );
        }
        return;
      }
    } catch (e) {
      final msg = _auth.mapFirebaseAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: fr.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('sign_in.title'.tr())),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth < 600
                  ? constraints.maxWidth
                  : 480.0;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),
                        const BrandLogo(size: 96),
                        const SizedBox(height: 14),
                        Text(
                          'app.title'.tr(),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'sign_in.subtitle'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurface.withOpacity(.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'sign_in.email'.tr(),
                                      prefixIcon: const Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'sign_in.email_required'.tr()
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    obscureText: _obscure,
                                    decoration: InputDecoration(
                                      labelText: 'sign_in.password'.tr(),
                                      prefixIcon: const Icon(
                                        Icons.lock_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                        ),
                                        tooltip: 'sign_in.toggle_password'.tr(),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                        ? 'sign_in.password_required'.tr()
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () => Navigator.of(
                                        context,
                                      ).pushNamed('/reset'),
                                      child: Text('sign_in.forgot'.tr()),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FilledButton(
                                    onPressed: _loading ? null : _signIn,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                            ),
                                          )
                                        : Text('sign_in.cta'.tr()),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'sign_in.or'.tr(),
                                style: TextStyle(
                                  color: scheme.onSurface.withOpacity(.7),
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/signup'),
                          child: Text('sign_in.no_account'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

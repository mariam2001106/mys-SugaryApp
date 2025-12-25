import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mysugaryapp/screens/setup/personal_setup_wizerd.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/models/user_profile.dart';
import 'package:mysugaryapp/screens/home/home_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void>? _createProfileFuture;
  String? _appliedLocaleForUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        if (authSnap.hasError) {
          return _ErrorScreen('Auth error: ${authSnap.error}');
        }
        final user = authSnap.data;
        if (user == null) return const SignInScreen();

        final svc = ProfileService();
        _createProfileFuture ??= svc.createIfMissing(user.uid);

        return FutureBuilder<void>(
          future: _createProfileFuture,
          builder: (context, createSnap) {
            if (createSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            if (createSnap.hasError) {
              return _ErrorScreen('Create profile error: ${createSnap.error}');
            }

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: svc.getUserDocFromServer(user.uid),
              builder: (context, docSnap) {
                if (docSnap.connectionState == ConnectionState.waiting) {
                  return const _Splash();
                }
                if (docSnap.hasError) {
                  // ignore and continue to stream
                } else if (docSnap.hasData) {
                  final data = docSnap.data?.data();
                  final localeCode = data?['locale'] as String?;
                  if (localeCode != null && _appliedLocaleForUid != user.uid) {
                    try {
                      if (context.locale.languageCode != localeCode) {
                        context.setLocale(Locale(localeCode));
                      }
                    } catch (_) {}
                    _appliedLocaleForUid = user.uid;
                  }
                }

                return StreamBuilder<UserProfile?>(
                  stream: svc.streamProfile(user.uid),
                  builder: (context, profSnap) {
                    if (profSnap.connectionState == ConnectionState.waiting) {
                      return const _Splash();
                    }
                    if (profSnap.hasError) {
                      return _ErrorScreen(
                        'Profile stream error: ${profSnap.error}',
                      );
                    }
                    final profile = profSnap.data;

                    if (profile == null || !profile.onboardingComplete) {
                      return PersonalSetupWizard(uid: user.uid);
                    }
                    return const HomeScreen();
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen(this.message);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }
}

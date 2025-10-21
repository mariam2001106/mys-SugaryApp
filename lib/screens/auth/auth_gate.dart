import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mysugaryapp/screens/setup/personal_setup_wizerd.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/models/user_profile.dart';
import 'package:mysugaryapp/screens/home/home_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final user = authSnap.data;
        if (user == null) return const SignInScreen();

        final svc = ProfileService();
        return FutureBuilder<void>(
          future: svc.createIfMissing(user.uid),
          builder: (context, createSnap) {
            if (createSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            return StreamBuilder<UserProfile?>(
              stream: svc.streamProfile(user.uid),
              builder: (context, profSnap) {
                if (profSnap.connectionState == ConnectionState.waiting) {
                  return const _Splash();
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
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

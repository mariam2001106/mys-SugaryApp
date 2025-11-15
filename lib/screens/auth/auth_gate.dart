import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile.dart';
import '../setup/personal_setup_wizard.dart';
import '../home/home_screen.dart';
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
        if (authSnap.hasError) {
          return _ErrorScreen('Auth error: ${authSnap.error}');
        }
        final user = authSnap.data;
        if (user == null) return const SignInScreen();

        // ignore: avoid_print
        print('[AuthGate] Signed in as ${user.uid} (${user.email})');

        final svc = ProfileService();
        return FutureBuilder<void>(
          future: svc.createIfMissing(user.uid),
          builder: (context, createSnap) {
            if (createSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            if (createSnap.hasError) {
              return _ErrorScreen('Create profile error: ${createSnap.error}');
            }
            return StreamBuilder<UserProfile?>(
              stream: svc.streamProfile(user.uid),
              builder: (context, profSnap) {
                if (profSnap.connectionState == ConnectionState.waiting) {
                  return const _Splash();
                }
                if (profSnap.hasError) {
                  return _ErrorScreen('Profile stream error: ${profSnap.error}');
                }
                final profile = profSnap.data;

                // If profile is missing or incomplete → wizard
                if (profile == null || !profile.onboardingComplete) {
                  // ignore: avoid_print
                  print('[AuthGate] Routing to Setup Wizard (profile null or incomplete)');
                  return PersonalSetupWizard(uid: user.uid);
                }

                // else → Home
                // ignore: avoid_print
                print('[AuthGate] Routing to Home (onboarding complete)');
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile.dart';
import '../setup/personal_setup_wizerd.dart';
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

        // debug print
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
              final err = createSnap.error;
              // ignore: avoid_print
              print('[AuthGate] createIfMissing failed: $err');
              return _ErrorScreen('خطأ أثناء إعداد الملف الشخصي:\n$err\n\nتحقق من قواعد Firestore و App Check.');
            }
            return StreamBuilder<UserProfile?>(
              stream: svc.streamProfile(user.uid),
              builder: (context, profSnap) {
                if (profSnap.connectionState == ConnectionState.waiting) {
                  return const _Splash();
                }
                if (profSnap.hasError) {
                  // ignore: avoid_print
                  print('[AuthGate] Profile stream error: ${profSnap.error}');
                  return _ErrorScreen('Profile stream error: ${profSnap.error}');
                }

                final profile = profSnap.data;

                // Debug: print profile fields
                // ignore: avoid_print
                print('[AuthGate] profile object: $profile');
                if (profile != null) {
                  // ignore: avoid_print
                  print('[AuthGate] onboardingComplete=${profile.onboardingComplete}, onboardingStep=${profile.onboardingStep}');
                } else {
                  // ignore: avoid_print
                  print('[AuthGate] profile is null');
                }

                // Debug UI: show profile JSON and let you force the wizard or Home.
                // This helps confirm what Firestore is returning and why routing goes to Home.
                return _DebugProfileChooser(
                  profile: profile,
                  uid: user.uid,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DebugProfileChooser extends StatelessWidget {
  final UserProfile? profile;
  final String uid;
  const _DebugProfileChooser({required this.profile, required this.uid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onboarding = profile?.onboardingComplete;
    final step = profile?.onboardingStep;
    return Scaffold(
      appBar: AppBar(title: const Text('Debug: Auth routing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: SelectableText(
                    'UID: $uid\n\nprofile == null: ${profile == null}\nonboardingComplete: $onboarding\nonboardingStep: $step\n\n(See logs for full profile object)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
              onPressed: () {
                // If profile is null or incomplete, open Wizard
                if (profile == null || profile!.onboardingComplete == false) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => PersonalSetupWizard(uid: uid)));
                } else {
                  // If profile exists and onboardingComplete == true, show a toast and go Home
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
                }
              },
              child: const Text('Auto route (current logic)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Force open wizard regardless of profile state
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => PersonalSetupWizard(uid: uid)));
              },
              child: const Text('Force Setup Wizard (debug)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
              },
              child: const Text('Go Home (debug)'),
            ),
            const SizedBox(height: 16),
            const Text(
              'If onboardingComplete is true but you still want the wizard, press "Force Setup Wizard" and then inspect/overwrite the Firestore document.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
      appBar: AppBar(title: const Text('خطأ (تصحيح)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SelectableText(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

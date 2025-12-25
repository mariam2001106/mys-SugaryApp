import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/auth/auth_gate.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- Disable Firestore local persistence (server-only mode) ---
  // Attempt to clear any existing persistence first (safe if no listeners yet)
  try {
    await FirebaseFirestore.instance.clearPersistence();
  } catch (_) {
    // ignore - clearPersistence may throw if persistence wasn't enabled or listeners exist
  }
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  // ----------------------------------------------------------------

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      child: const SugarApp(),
    ),
  );
}

class SugarApp extends StatelessWidget {
  const SugarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سكر',
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      routes: {
        '/signin': (_) => const SignInScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/reset': (_) => const ResetPasswordScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

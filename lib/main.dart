import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart'
    show BuildContextEasyLocalizationExtension, EasyLocalization;
import 'package:mysugaryapp/screens/glucose/glucose_screen.dart';
import 'package:mysugaryapp/screens/reminders/reminders_screen.dart';
import 'package:mysugaryapp/screens/trends/a1c_calculator_screen.dart';
import 'package:mysugaryapp/screens/trends/trends_screen.dart';
import 'package:mysugaryapp/services/notification_service.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/auth/auth_gate.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

final navigatorkey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase before any Firebase usage
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initializes local notification engine for time-based reminders.
  await NotificationService.instance.init();

  // Disable GoogleFonts runtime fetching to avoid network dependencies
  GoogleFonts.config.allowRuntimeFetching = false;

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
      navigatorKey: navigatorkey,
      routes: {
        '/signin': (_) => const SignInScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/reset': (_) => const ResetPasswordScreen(),
        '/home': (_) => const HomeScreen(),
        '/remainders': (_) => const RemindersScreen(),
        '/trends': (_) => const TrendScreen(),
        '/a1c': (_) => const A1CCalculatorScreen(),
        '/a1c_add_glucose_fallback': (_) =>
            const GlucoseScreen(), // used by CTA
      },
    );
  }
}

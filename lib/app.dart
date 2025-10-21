import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/home_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: 1.1, // slightly larger for accessibility
            ),
      ),
      // Arabic locale automatically applies RTL
      initialRoute: '/signin',
      routes: {
        '/signin': (_) => const SignInScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
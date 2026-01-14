import 'package:flutter/material.dart';
// Using default text themes to avoid runtime font fetching.
// You can re-enable GoogleFonts after bundling fonts locally.

class AppColors {
  // Brand palette
  static const Color darkBlue = Color(0xFF0D3B66);
  static const Color darkRed = Color(0xFFB3261E);
  static const Color gray = Color(0xFF667085);
  static const Color lightGray = Color(0xFFF2F4F7);
  static const Color white = Color(0xFFFFFFFF);
}

class AppTheme {
  static FilledButtonThemeData _filledButtonTheme(ColorScheme cs) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        // Remove Size.fromHeight(52) which forces infinite width
        // Use minWidth=0, minHeight=52; parent decides width.
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: BorderSide(color: cs.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData light() {
    final cs =
        ColorScheme.fromSeed(
          seedColor: AppColors.darkBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.darkBlue,
          onPrimary: Colors.white,
          secondary: AppColors.darkRed,
          onSecondary: Colors.white,
          surface: AppColors.white,
          onSurface: const Color(0xFF1F2937),
          outline: const Color(0xFFD0D5DD),
          surfaceContainerHighest: AppColors.white,
        );

    final textTheme = ThemeData(
      brightness: Brightness.light,
    ).textTheme.apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 14),
        titleLarge: textTheme.titleLarge?.copyWith(fontSize: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: AppColors.gray),
        hintStyle: TextStyle(color: AppColors.gray.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: _filledButtonTheme(cs),
      outlinedButtonTheme: _outlinedButtonTheme(cs),
      cardTheme: CardThemeData(
        elevation: 8,
        surfaceTintColor: cs.surface,
        color: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: cs.outline, thickness: 1),
    );
  }

  static ThemeData dark() {
    final cs =
        ColorScheme.fromSeed(
          seedColor: AppColors.darkBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.darkBlue,
          onPrimary: Colors.white,
          secondary: AppColors.darkRed,
          onSecondary: Colors.white,
          surface: const Color(0xFF111827),
          onSurface: Colors.white,
          outline: const Color(0xFF2A3444),
          surfaceContainerHighest: const Color(0xFF111827),
        );

    final textTheme = ThemeData(brightness: Brightness.dark).textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: _filledButtonTheme(cs),
      outlinedButtonTheme: _outlinedButtonTheme(cs),
      cardTheme: CardThemeData(
        elevation: 6,
        surfaceTintColor: cs.surface,
        color: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

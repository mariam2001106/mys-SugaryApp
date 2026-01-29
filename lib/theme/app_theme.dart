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
    // Material 3 compliant dark ColorScheme with accessibility focus
    // Background hierarchy: background < surface < surfaceContainer < surfaceContainerHighest
    final cs = ColorScheme.dark(
      // Near-black background for deep contrast
      background: const Color(0xFF0D0F12),
      // Slightly lighter surface for cards and containers
      surface: const Color(0xFF101317),
      surfaceContainerLowest: const Color(0xFF0D0F12),
      surfaceContainerLow: const Color(0xFF101317),
      surfaceContainer: const Color(0xFF141820),
      surfaceContainerHigh: const Color(0xFF1A1F28),
      surfaceContainerHighest: const Color(0xFF1F2530),
      
      // Primary: adjusted darkBlue for better legibility on dark backgrounds
      primary: const Color(0xFF4A90E2), // Lighter blue for accessibility
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFF0D3B66), // Original darkBlue for containers
      onPrimaryContainer: const Color(0xFFB8D4F1),
      
      // Secondary colors
      secondary: const Color(0xFF6B7280), // Adjusted gray
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFF2A313B),
      onSecondaryContainer: const Color(0xFFD1D5DB),
      
      // Tertiary for additional accent
      tertiary: const Color(0xFF7C3AED),
      onTertiary: const Color(0xFFFFFFFF),
      
      // Error: adjusted darkRed for visibility
      error: const Color(0xFFEF4444), // Brighter red for dark mode
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFF5F1F1F),
      onErrorContainer: const Color(0xFFFFDAD6),
      
      // Surface text colors - near-white for readability
      onSurface: const Color(0xFFE7E9EE),
      onSurfaceVariant: const Color(0xFFB8BCC5),
      
      // Outline for borders
      outline: const Color(0xFF2A313B),
      outlineVariant: const Color(0xFF1F252E),
      
      // Shadow and scrim
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      
      // Inverse colors for special cases
      inverseSurface: const Color(0xFFE7E9EE),
      onInverseSurface: const Color(0xFF1A1F28),
      inversePrimary: const Color(0xFF0D3B66),
    );

    final textTheme = ThemeData(brightness: Brightness.dark).textTheme.apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      textTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16, color: cs.onSurface),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 14, color: cs.onSurface),
        bodySmall: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        titleLarge: textTheme.titleLarge?.copyWith(fontSize: 22, color: cs.onSurface),
        titleMedium: textTheme.titleMedium?.copyWith(color: cs.onSurface),
        titleSmall: textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 1.6),
        ),
      ),
      filledButtonTheme: _filledButtonTheme(cs),
      outlinedButtonTheme: _outlinedButtonTheme(cs),
      cardTheme: CardThemeData(
        elevation: 0, // Minimal shadow for flat appearance
        surfaceTintColor: Colors.transparent,
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: cs.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainer,
        selectedColor: cs.primaryContainer,
        disabledColor: cs.surfaceContainerLow,
        labelStyle: TextStyle(color: cs.onSurface),
        secondaryLabelStyle: TextStyle(color: cs.onSurfaceVariant),
        side: BorderSide(color: cs.outline, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: cs.onSurface),
      dividerTheme: DividerThemeData(
        color: cs.outline.withValues(alpha: 0.3),
        thickness: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: cs.onInverseSurface, fontSize: 12),
      ),
    );
  }
}

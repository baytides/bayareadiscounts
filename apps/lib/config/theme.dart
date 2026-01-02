import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary - Teal (matches web design tokens)
  static const Color primary = Color(0xFF00ACC1);        // Teal - main brand
  static const Color primaryDark = Color(0xFF00838F);    // Teal darker - headings, links
  static const Color primaryDarker = Color(0xFF006064);  // Teal darkest - hover states
  static const Color accent = Color(0xFFFF6F00);         // Orange - accents, CTAs
  static const Color accentLight = Color(0xFFFF8F00);    // Orange lighter

  // Cyan Palette (brand tints)
  static const Color cyan50 = Color(0xFFE0F7FA);
  static const Color cyan100 = Color(0xFFB2EBF2);
  static const Color cyan200 = Color(0xFF80DEEA);
  static const Color cyan700 = Color(0xFF0097A7);
  static const Color cyan800 = Color(0xFF00838F);
  static const Color cyan900 = Color(0xFF006064);

  // Semantic colors
  static const Color success = Color(0xFF22C55E);  // Green - verified, success
  static const Color warning = Color(0xFFEAB308);  // Yellow - caution
  static const Color danger = Color(0xFFEF4444);   // Red - error, stale
  static const Color info = Color(0xFF3B82F6);     // Blue - information

  // Light theme colors
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF9FAFB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF24292E);
  static const Color lightTextSecondary = Color(0xFF586069);
  static const Color lightTextMuted = Color(0xFF6B7280);
  static const Color lightTextHeading = Color(0xFF00838F);
  static const Color lightBorder = Color(0xFFE1E4E8);
  static const Color lightBorderLight = Color(0xFFB2EBF2);
  static const Color lightHover = Color(0xFFE0F7FA);

  // Light Neutral Palette
  static const Color lightNeutral50 = Color(0xFFF9FAFB);
  static const Color lightNeutral100 = Color(0xFFF3F4F6);
  static const Color lightNeutral200 = Color(0xFFE5E7EB);
  static const Color lightNeutral300 = Color(0xFFD1D5DB);
  static const Color lightNeutral400 = Color(0xFF9CA3AF);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceAlt = Color(0xFF1C2128);
  static const Color darkCard = Color(0xFF1C2128);
  static const Color darkText = Color(0xFFE8EEF5);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextMuted = Color(0xFF6E7681);
  static const Color darkTextHeading = Color(0xFF79D8EB);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkBorderLight = Color(0xFF1B3A3A);
  static const Color darkHover = Color(0xFF1B3A3A);

  // Dark Neutral Palette
  static const Color darkNeutral50 = Color(0xFF21262D);
  static const Color darkNeutral100 = Color(0xFF30363D);
  static const Color darkNeutral200 = Color(0xFF484F58);
  static const Color darkNeutral300 = Color(0xFF6E7681);
  static const Color darkNeutral400 = Color(0xFF8B949E);

  // Focus Ring
  static const Color focusRing = Color(0xFF2563EB);

  // Legacy aliases for backwards compatibility
  static const Color primaryLight = cyan200;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    dividerColor: AppColors.lightBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightTextSecondary,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.lightText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.lightText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.lightTextSecondary,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkTextSecondary,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.darkText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.darkText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.darkTextSecondary,
      ),
    ),
  );
}

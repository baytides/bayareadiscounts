import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary - Teal (matches web Tailwind config)
  // WCAG 2.2 AAA compliant - 7:1 contrast ratio
  static const Color primary = Color(0xFF005A5F);        // primary-700 - main brand
  static const Color primaryLight = Color(0xFF00838F);   // primary-500
  static const Color primaryLighter = Color(0xFF5EEAD4); // primary-200
  static const Color primaryDark = Color(0xFF004A4F);    // primary-800
  static const Color primaryDarker = Color(0xFF003A3D);  // primary-900

  // Primary Palette (matching Tailwind config)
  static const Color primary50 = Color(0xFFE0F7FA);
  static const Color primary100 = Color(0xFFB2EBF2);
  static const Color primary200 = Color(0xFF5EEAD4);   // AAA for dark mode text
  static const Color primary300 = Color(0xFF2DD4BF);   // AAA for dark mode text
  static const Color primary400 = Color(0xFF14B8A6);
  static const Color primary500 = Color(0xFF00838F);
  static const Color primary600 = Color(0xFF006D75);
  static const Color primary700 = Color(0xFF005A5F);   // Main brand - 7.5:1 on white
  static const Color primary800 = Color(0xFF004A4F);
  static const Color primary900 = Color(0xFF003A3D);

  // Secondary - Warm gold (matches web)
  static const Color secondary = Color(0xFF8A6500);      // secondary-700 - AAA compliant
  static const Color secondaryLight = Color(0xFFFFC107); // secondary-500
  static const Color secondaryDark = Color(0xFF5C4300);  // secondary-800

  // Semantic colors (matching web)
  static const Color success = Color(0xFF2E7D32);  // Green - verified, success
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57C00);  // Orange - caution
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color danger = Color(0xFFC62828);   // Red - error
  static const Color dangerLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);     // Blue - information
  static const Color infoLight = Color(0xFFE3F2FD);

  // Light theme colors (matching web neutral palette)
  static const Color lightBackground = Color(0xFFFAFAFA);   // neutral-50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF5F5F5);   // neutral-100
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF171717);         // neutral-900
  static const Color lightTextSecondary = Color(0xFF5C5C5C); // neutral-500 - 7:1 on white
  static const Color lightTextMuted = Color(0xFF4A4A4A);    // neutral-600
  static const Color lightTextHeading = Color(0xFF005A5F);  // primary-700
  static const Color lightBorder = Color(0xFFEEEEEE);       // neutral-200
  static const Color lightBorderLight = Color(0xFFD4D4D4);  // neutral-300
  static const Color lightHover = Color(0xFFE0F7FA);        // primary-50

  // Light Neutral Palette
  static const Color lightNeutral50 = Color(0xFFFAFAFA);
  static const Color lightNeutral100 = Color(0xFFF5F5F5);
  static const Color lightNeutral200 = Color(0xFFEEEEEE);
  static const Color lightNeutral300 = Color(0xFFD4D4D4);
  static const Color lightNeutral400 = Color(0xFFA3A3A3);
  static const Color lightNeutral500 = Color(0xFF5C5C5C);

  // Dark theme colors (matching web)
  static const Color darkBackground = Color(0xFF171717);    // neutral-900
  static const Color darkSurface = Color(0xFF262626);       // neutral-800
  static const Color darkSurfaceAlt = Color(0xFF3D3D3D);    // neutral-700
  static const Color darkCard = Color(0xFF262626);          // neutral-800
  static const Color darkText = Color(0xFFF5F5F5);          // neutral-100
  static const Color darkTextSecondary = Color(0xFFD4D4D4); // neutral-300 - 7:1 on dark
  static const Color darkTextMuted = Color(0xFFA3A3A3);     // neutral-400 - 7:1 on dark
  static const Color darkTextHeading = Color(0xFF5EEAD4);   // primary-200
  static const Color darkBorder = Color(0xFF3D3D3D);        // neutral-700
  static const Color darkBorderLight = Color(0xFF4A4A4A);   // neutral-600
  static const Color darkHover = Color(0xFF004A4F);         // primary-800

  // Dark Neutral Palette
  static const Color darkNeutral50 = Color(0xFF262626);
  static const Color darkNeutral100 = Color(0xFF3D3D3D);
  static const Color darkNeutral200 = Color(0xFF4A4A4A);
  static const Color darkNeutral300 = Color(0xFFD4D4D4);
  static const Color darkNeutral400 = Color(0xFFA3A3A3);

  // Focus Ring
  static const Color focusRing = Color(0xFF005A5F);

  // Legacy aliases for backwards compatibility
  static const Color primaryDarker700 = primary700;
  static const Color cyan50 = primary50;
  static const Color cyan100 = primary100;
  static const Color cyan200 = primary200;
  static const Color cyan700 = primary500;
  static const Color cyan800 = primary700;
  static const Color cyan900 = primary900;
  static const Color accent = secondaryLight;
  static const Color accentLight = Color(0xFFFF8F00);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary50,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
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
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightTextSecondary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      indicatorColor: AppColors.primary50,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          color: AppColors.lightTextSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: AppColors.primary,
            size: 24,
          );
        }
        return const IconThemeData(
          color: AppColors.lightTextSecondary,
          size: 24,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightNeutral100,
      selectedColor: AppColors.primary50,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.lightText,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightNeutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightNeutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
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
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.lightText,
        height: 1.625,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.lightText,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.lightTextSecondary,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextMuted,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary200,
      onPrimary: AppColors.primary900,
      primaryContainer: AppColors.primary800,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.primary900,
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
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary200,
      unselectedItemColor: AppColors.darkTextSecondary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.primary800,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary200,
          );
        }
        return const TextStyle(
          fontSize: 12,
          color: AppColors.darkTextSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: AppColors.primary200,
            size: 24,
          );
        }
        return const IconThemeData(
          color: AppColors.darkTextSecondary,
          size: 24,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkNeutral100,
      selectedColor: AppColors.primary800,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.darkText,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary200, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary200,
        foregroundColor: AppColors.primary900,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary200,
        side: const BorderSide(color: AppColors.primary300, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
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
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.darkText,
        height: 1.625,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.darkText,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.darkTextSecondary,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextMuted,
      ),
    ),
  );
}

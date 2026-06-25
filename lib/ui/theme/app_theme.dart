import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  // Desired font stack: Helvetica Neue (preferred) → Inter → Arial (fallback)
  static const List<String> fontFamilyFallback = [
    'Helvetica Neue',
    'Inter',
    'Arial',
    'sans-serif',
  ];

  /// Helper to force the font stack on any raw TextStyle
  static TextStyle withFontStack(TextStyle base) {
    return base.copyWith(
      fontFamily: 'Helvetica Neue',
      fontFamilyFallback: fontFamilyFallback,
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.tertiary,
      surfaceContainerHighest: Colors.white,
      error: AppColors.errorBg,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.tertiary,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: AppColors.tertiary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      fontFamily: 'Helvetica Neue',
      fontFamilyFallback: fontFamilyFallback,
      textTheme: GoogleFonts.interTextTheme().apply(
        fontFamily: 'Helvetica Neue',
        fontFamilyFallback: fontFamilyFallback,
      ),
      primaryTextTheme: GoogleFonts.interTextTheme().apply(
        fontFamily: 'Helvetica Neue',
        fontFamilyFallback: fontFamilyFallback,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.primaryDark,
      tertiary: AppColors.secondaryLight,
      onTertiary: AppColors.primaryDark,
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: const Color(0xFFF1E8FF),
      surfaceContainerHighest: AppColors.darkCard,
      onSurfaceVariant: const Color(0xFFC8B8E8),
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: Colors.white,
      secondaryContainer: const Color(0xFF2A2147),
      onSecondaryContainer: AppColors.secondary,
      errorContainer: const Color(0xFF5B1E1E),
      onErrorContainer: const Color(0xFFFFDADA),
      outline: const Color(0xFF4B3F6E),
      outlineVariant: const Color(0xFF352C52),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFF1E8FF),
      onInverseSurface: AppColors.darkSurface,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkSurface,
      canvasColor: AppColors.darkSurfaceAlt,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: AppColors.darkSurface,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      fontFamily: 'Helvetica Neue',
      fontFamilyFallback: fontFamilyFallback,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFF1E8FF)),
          bodySmall: TextStyle(color: Color(0xFFA89BC7)),
        ),
      ).apply(
        fontFamily: 'Helvetica Neue',
        fontFamilyFallback: fontFamilyFallback,
      ),
      primaryTextTheme: GoogleFonts.interTextTheme().apply(
        fontFamily: 'Helvetica Neue',
        fontFamilyFallback: fontFamilyFallback,
      ),
    );
  }
}

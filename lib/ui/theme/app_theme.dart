import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  /// Legacy helper kept so existing call sites don't break.
  /// Applies the secondary (body) font; prefer [AppTypography] in new code.
  static TextStyle withFontStack(TextStyle base) {
    return AppTypography.secondary(base);
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
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: AppColors.tertiary,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: AppTypography.textTheme(ThemeData.light().textTheme),
      primaryTextTheme: AppTypography.textTheme(ThemeData.light().primaryTextTheme),
    );
  }

  static ThemeData dark() {
    final baseText = ThemeData.dark().textTheme;
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.primaryDark,
      tertiary: AppColors.secondaryLight,
      onTertiary: AppColors.primaryDark,
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFF1E8FF),
      surfaceContainerHighest: AppColors.darkCard,
      onSurfaceVariant: Color(0xFFC8B8E8),
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: Colors.white,
      secondaryContainer: Color(0xFF2A2147),
      onSecondaryContainer: AppColors.secondary,
      errorContainer: Color(0xFF5B1E1E),
      onErrorContainer: Color(0xFFFFDADA),
      outline: Color(0xFF4B3F6E),
      outlineVariant: Color(0xFF352C52),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFF1E8FF),
      onInverseSurface: AppColors.darkSurface,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkSurface,
      canvasColor: AppColors.darkSurfaceAlt,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: AppColors.darkSurface,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: AppTypography.textTheme(
        baseText.copyWith(
          bodyMedium:
              baseText.bodyMedium?.copyWith(color: const Color(0xFFF1E8FF)),
          bodySmall:
              baseText.bodySmall?.copyWith(color: const Color(0xFFA89BC7)),
        ),
      ),
      primaryTextTheme: AppTypography.textTheme(ThemeData.dark().primaryTextTheme),
    );
  }
}

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'wallet_tokens.dart';

/// Swiss modernism with a glass layer on top.
///
/// The theme itself is flat and rectilinear: hairline rules instead of
/// elevation, near-square corners, one accent, one typeface. Translucency is
/// not set here — it belongs to the surfaces that actually float, and those
/// opt in through `GlassPanel` in `glass.dart`.
class AppTheme {
  const AppTheme._();

  /// Legacy helper kept so existing call sites do not break.
  /// Applies the body font; prefer [AppTypography] in new code.
  static TextStyle withFontStack(TextStyle base) {
    return AppTypography.secondary(base);
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      tertiary: AppColors.secondaryLight,
      surface: Colors.white,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceSoft,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      error: AppColors.errorBg,
      onError: Colors.white,
    );

    return _base(
      scheme: scheme,
      ground: AppColors.background,
      ink: AppColors.textPrimary,
      line: AppColors.line,
      textTheme: AppTypography.textTheme(ThemeData.light().textTheme),
      primaryTextTheme:
          AppTypography.textTheme(ThemeData.light().primaryTextTheme),
    );
  }

  static ThemeData dark() {
    final baseText = ThemeData.dark().textTheme;
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Color(0xFF14101F),
      secondary: AppColors.primaryLight,
      onSecondary: Color(0xFF14101F),
      tertiary: AppColors.secondaryLight,
      onTertiary: AppColors.primaryDark,
      error: Color(0xFFF87171),
      onError: Color(0xFF1A0A0A),
      surface: AppColors.darkSurfaceAlt,
      onSurface: Wallet.darkInk,
      surfaceContainerHighest: AppColors.darkCard,
      onSurfaceVariant: Wallet.darkMuted,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: Colors.white,
      secondaryContainer: Color(0xFF1E1A2B),
      onSecondaryContainer: AppColors.primaryLight,
      errorContainer: Color(0xFF3B1414),
      onErrorContainer: Color(0xFFFECACA),
      outline: Wallet.darkLine,
      outlineVariant: Wallet.darkLine,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Wallet.darkInk,
      onInverseSurface: Wallet.darkGround,
      inversePrimary: AppColors.primary,
    );

    return _base(
      scheme: scheme,
      ground: Wallet.darkGround,
      ink: Wallet.darkInk,
      line: Wallet.darkLine,
      textTheme: AppTypography.textTheme(
        baseText.copyWith(
          bodyLarge: baseText.bodyLarge?.copyWith(color: Wallet.darkInk),
          bodyMedium: baseText.bodyMedium?.copyWith(color: Wallet.darkInk),
          bodySmall: baseText.bodySmall?.copyWith(color: Wallet.darkMuted),
        ),
      ),
      primaryTextTheme:
          AppTypography.textTheme(ThemeData.dark().primaryTextTheme),
    );
  }

  /// Everything the two modes agree on: geometry, rules, control shapes.
  static ThemeData _base({
    required ColorScheme scheme,
    required Color ground,
    required Color ink,
    required Color line,
    required TextTheme textTheme,
    required TextTheme primaryTextTheme,
  }) {
    final isDark = scheme.brightness == Brightness.dark;

    OutlineInputBorder field(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusControl),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      canvasColor: ground,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,

      // Flat chrome. An app bar that tints and lifts on scroll is Material
      // signalling elevation; in this system the hairline below it does that
      // job, and two signals for one boundary is one too many.
      appBarTheme: AppBarTheme(
        backgroundColor: ground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: ink),
      ),

      dividerTheme: DividerThemeData(
        color: line,
        thickness: Wallet.hairline,
        space: Wallet.hairline,
      ),

      cardTheme: CardTheme(
        color: Wallet.surfaceOf(isDark),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusCard),
          side: BorderSide(color: line, width: Wallet.hairline),
        ),
      ),

      // Square-ish blocks, no glow, no gradient. Weight and colour carry the
      // primary action, which is what lets a single accent read as "this is
      // the thing to press".
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withOpacity(.35),
          disabledForegroundColor: scheme.onPrimary.withOpacity(.7),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Wallet.radiusControl),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: .2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: line, width: Wallet.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Wallet.radiusControl),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Wallet.surfaceOf(isDark),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        enabledBorder: field(line, Wallet.hairline),
        focusedBorder: field(scheme.primary, 1.5),
        errorBorder: field(scheme.error, Wallet.hairline),
        focusedErrorBorder: field(scheme.error, 1.5),
        disabledBorder: field(line, Wallet.hairline),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: Wallet.faintOf(isDark),
        ),
        labelStyle: AppTypography.eyebrow(color: Wallet.mutedOf(isDark)),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: scheme.error,
          fontSize: 11.5,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Wallet.surfaceOf(isDark),
        side: BorderSide(color: line, width: Wallet.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusControl),
        ),
        labelStyle: AppTypography.eyebrow(color: ink, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // Sheets and dialogs are the surfaces that genuinely float, so they get
      // the tightest geometry and let `GlassPanel` supply the frost.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Wallet.surfaceOf(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Wallet.radiusPanel),
          ),
        ),
      ),

      dialogTheme: DialogTheme(
        backgroundColor: Wallet.surfaceOf(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusPanel),
          side: BorderSide(color: line, width: Wallet.hairline),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: ink),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Wallet.mutedOf(isDark),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: Wallet.mutedOf(isDark),
        textColor: ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusControl),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: line,
        circularTrackColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? Wallet.darkGround : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusControl),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      tabBarTheme: TabBarTheme(
        labelColor: ink,
        unselectedLabelColor: Wallet.mutedOf(isDark),
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: line,
        labelStyle: AppTypography.eyebrow(fontSize: 12.5),
        unselectedLabelStyle:
            AppTypography.eyebrow(fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
    );
  }
}

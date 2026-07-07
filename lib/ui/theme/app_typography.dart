import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide 3-tier font system.
///
/// - Primary   → Poppins       : headlines, titles, buttons (brand voice)
/// - Secondary → Inter         : body copy and input text (readability)
/// - Tertiary  → Space Grotesk : labels, captions, small accents
///
/// Widgets should normally rely on `Theme.of(context).textTheme` (already
/// mapped below). Use these helpers only when a style must be built inline.
class AppTypography {
  const AppTypography._();

  /// Primary font — Poppins.
  static TextStyle primary([TextStyle? base]) =>
      GoogleFonts.poppins(textStyle: base);

  /// Secondary font — Inter.
  static TextStyle secondary([TextStyle? base]) =>
      GoogleFonts.inter(textStyle: base);

  /// Tertiary font — Space Grotesk.
  static TextStyle tertiary([TextStyle? base]) =>
      GoogleFonts.spaceGrotesk(textStyle: base);

  /// Maps the Material text roles onto the 3 font tiers.
  static TextTheme textTheme(TextTheme base) {
    final poppins = GoogleFonts.poppinsTextTheme(base);
    final inter = GoogleFonts.interTextTheme(base);
    final grotesk = GoogleFonts.spaceGroteskTextTheme(base);

    return base.copyWith(
      // Primary — large, expressive text.
      displayLarge: poppins.displayLarge,
      displayMedium: poppins.displayMedium,
      displaySmall: poppins.displaySmall,
      headlineLarge: poppins.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: poppins.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: poppins.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: poppins.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: poppins.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      titleSmall: poppins.titleSmall?.copyWith(fontWeight: FontWeight.w500),

      // Secondary — reading text and inputs (TextField uses bodyLarge).
      bodyLarge: inter.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: inter.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: inter.bodySmall?.copyWith(fontWeight: FontWeight.w400),

      // Tertiary — labels, chips, captions, buttons' small text.
      labelLarge: grotesk.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      labelMedium: grotesk.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: grotesk.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}

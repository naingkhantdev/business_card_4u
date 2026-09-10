import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One neo-grotesque, sized and weighted — the Swiss position on type.
///
/// The three-family stack (Poppins / Inter / Space Grotesk) is gone. Mixing a
/// geometric display face with a grotesque body face is exactly the kind of
/// decorative variety the International Typographic Style argues against:
/// hierarchy should come from size, weight and space, not from a change of
/// voice. Inter is the closest widely available relative of Helvetica, so it
/// now carries every role.
///
/// The tier helpers are kept — call sites still say `primary` / `secondary` /
/// `tertiary` — but they all resolve to the same family. What differs is the
/// tracking each tier wants.
class AppTypography {
  const AppTypography._();

  /// Display and headline text. Set tight: large grotesque type opens up
  /// optically, so negative tracking is what keeps a headline reading as one
  /// object instead of a row of letters.
  static TextStyle primary([TextStyle? base]) => GoogleFonts.inter(
        textStyle: base,
        letterSpacing: _trackingFor(base?.fontSize ?? 22),
      );

  /// Body copy and inputs. Untracked — the metrics are already right at
  /// reading sizes.
  static TextStyle secondary([TextStyle? base]) =>
      GoogleFonts.inter(textStyle: base);

  /// Small labels and captions. A touch of positive tracking buys legibility
  /// back at sizes where the counters start to close up.
  static TextStyle tertiary([TextStyle? base]) =>
      GoogleFonts.inter(textStyle: base, letterSpacing: .1);

  /// The Swiss eyebrow: a small, uppercase, widely tracked label that names a
  /// block without competing with it. Pair with `.toUpperCase()` on the string.
  static TextStyle eyebrow({
    Color? color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      GoogleFonts.inter(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: fontSize * .09,
        height: 1.2,
      );

  /// Optical tracking: tighter as type grows, neutral at reading sizes.
  static double _trackingFor(double size) {
    if (size >= 48) return -1.6;
    if (size >= 32) return -1.0;
    if (size >= 24) return -0.6;
    if (size >= 18) return -0.35;
    return -0.15;
  }

  /// Maps every Material text role onto the single family.
  static TextTheme textTheme(TextTheme base) {
    final inter = GoogleFonts.interTextTheme(base);

    TextStyle? display(TextStyle? s, FontWeight w) => s?.copyWith(
          fontWeight: w,
          letterSpacing: _trackingFor(s.fontSize ?? 22),
          height: 1.05,
        );

    TextStyle? title(TextStyle? s, FontWeight w) => s?.copyWith(
          fontWeight: w,
          letterSpacing: _trackingFor(s.fontSize ?? 18),
          height: 1.2,
        );

    TextStyle? label(TextStyle? s) => s?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: .2,
        );

    return base.copyWith(
      // Display — set tight and heavy, the Swiss poster voice.
      displayLarge: display(inter.displayLarge, FontWeight.w700),
      displayMedium: display(inter.displayMedium, FontWeight.w700),
      displaySmall: display(inter.displaySmall, FontWeight.w700),

      headlineLarge: display(inter.headlineLarge, FontWeight.w700),
      headlineMedium: display(inter.headlineMedium, FontWeight.w700),
      headlineSmall: display(inter.headlineSmall, FontWeight.w600),

      titleLarge: title(inter.titleLarge, FontWeight.w600),
      titleMedium: title(inter.titleMedium, FontWeight.w600),
      titleSmall: title(inter.titleSmall, FontWeight.w500),

      // Body — untracked, generous leading. Swiss sets body copy for reading,
      // not for effect.
      bodyLarge: inter.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: inter.bodyMedium?.copyWith(height: 1.5),
      bodySmall: inter.bodySmall?.copyWith(height: 1.45),

      labelLarge: label(inter.labelLarge),
      labelMedium: label(inter.labelMedium),
      labelSmall: label(inter.labelSmall),
    );
  }
}

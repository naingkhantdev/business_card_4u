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
///
/// **Myanmar.** Inter has no Myanmar glyphs, so every style carries
/// [fontFamilyFallback] and Myanmar text renders in Noto Sans Myanmar instead
/// of whatever the device happens to have. When the app's locale is Myanmar
/// ([setLocale]), the Latin-tuned settings are relaxed: tracking goes to zero
/// (spacing pulls Myanmar clusters apart), line height rises to at least
/// [myanmarMinHeight] (stacked vowel marks clip below that), and the eyebrow
/// stops shrinking below [myanmarMinEyebrowSize].
class AppTypography {
  const AppTypography._();

  /// Declared in pubspec.yaml under `fonts:`. Until the font files are added
  /// Flutter skips the unknown family and falls back to the system font, so
  /// referencing it here is safe either way.
  static const myanmarFamily = 'NotoSansMyanmar';
  static const List<String> fontFamilyFallback = [myanmarFamily];

  static const double myanmarMinHeight = 1.6;
  static const double myanmarMinEyebrowSize = 12;

  static bool _myanmar = false;

  /// True while the app is showing Myanmar. Set once per build from the
  /// `MaterialApp.builder`, which sits under `Localizations`; every widget that
  /// shows localized text depends on `Localizations`, so it rebuilds — and
  /// re-reads this — whenever the locale changes.
  static bool get isMyanmar => _myanmar;

  static void setLocale(Locale locale) {
    _myanmar = locale.languageCode == 'my';
  }

  /// Adds the Myanmar fallback to [style] and, in the Myanmar locale, relaxes
  /// the tracking and leading that were tuned for Latin.
  static TextStyle forScript(TextStyle style) {
    final withFallback = style.copyWith(fontFamilyFallback: fontFamilyFallback);
    if (!_myanmar) return withFallback;

    final height = style.height;
    return withFallback.copyWith(
      letterSpacing: 0,
      height: height != null && height < myanmarMinHeight
          ? myanmarMinHeight
          : height,
    );
  }

  /// [forScript] for every role of a [TextTheme] — what the app builder hands
  /// to the theme once the locale is known.
  static TextTheme forScriptTheme(TextTheme t) {
    TextStyle? f(TextStyle? s) => s == null ? null : forScript(s);
    return t.copyWith(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }

  /// Display and headline text. Set tight: large grotesque type opens up
  /// optically, so negative tracking is what keeps a headline reading as one
  /// object instead of a row of letters.
  static TextStyle primary([TextStyle? base]) => forScript(GoogleFonts.inter(
        textStyle: base,
        letterSpacing: _trackingFor(base?.fontSize ?? 22),
      ));

  /// Body copy and inputs. Untracked — the metrics are already right at
  /// reading sizes.
  static TextStyle secondary([TextStyle? base]) =>
      forScript(GoogleFonts.inter(textStyle: base));

  /// Small labels and captions. A touch of positive tracking buys legibility
  /// back at sizes where the counters start to close up.
  static TextStyle tertiary([TextStyle? base]) =>
      forScript(GoogleFonts.inter(textStyle: base, letterSpacing: .1));

  /// The Swiss eyebrow: a small, uppercase, widely tracked label that names a
  /// block without competing with it. Pair with `.toUpperCase()` on the string.
  ///
  /// In Myanmar there is no uppercase to lean on and the tracking would split
  /// clusters, so the label is set untracked and no smaller than
  /// [myanmarMinEyebrowSize] — still small and bold, just readable.
  static TextStyle eyebrow({
    Color? color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final size = _myanmar && fontSize < myanmarMinEyebrowSize
        ? myanmarMinEyebrowSize
        : fontSize;
    return forScript(GoogleFonts.inter(
      color: color,
      fontSize: size,
      fontWeight: fontWeight,
      letterSpacing: size * .09,
      height: 1.2,
    ));
  }

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

    return base
        .copyWith(
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

          // Body — untracked, generous leading. Swiss sets body copy for
          // reading, not for effect.
          bodyLarge: inter.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: inter.bodyMedium?.copyWith(height: 1.5),
          bodySmall: inter.bodySmall?.copyWith(height: 1.45),

          labelLarge: label(inter.labelLarge),
          labelMedium: label(inter.labelMedium),
          labelSmall: label(inter.labelSmall),
        )
        .apply(fontFamilyFallback: fontFamilyFallback);
  }
}

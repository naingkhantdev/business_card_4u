import 'package:flutter/material.dart';

/// The card surfaces shared by the list and the detail page.
///
/// Swiss geometry and a true-neutral ramp. What changed from the violet-tinted
/// wallet: shadows no longer carry the accent (a coloured shadow is decoration,
/// and it dirties a neutral ground), corners are close to square, and depth is
/// carried by a hairline rule in both modes rather than by a glow in one.
///
/// One source for both screens, so a card cannot change colour when you tap it.
class Wallet {
  const Wallet._();

  // ── Geometry ──────────────────────────────────────────────────
  // Rectilinear, but not literally square. The first pass took Swiss geometry
  // to 4px and the cards stopped reading as cards — at phone scale a corner
  // that small is indistinguishable from none, and it fights the frosted
  // panels, which need a visible curve for the blurred edge to look like glass
  // rather than a crop. These are tighter than the 22px they replaced and
  // still unmistakably rounded.
  static const double radiusCard = 16;
  static const double radiusPanel = 20;
  static const double radiusControl = 12;
  static const double radiusTile = 10;

  /// 4pt base grid. Layout steps through these, never between them.
  static const double gridUnit = 4;
  static const double gutter = 16;
  static const double margin = 20;

  static const double hairline = 1;

  // ── Accent ────────────────────────────────────────────────────
  static const accentLight = Color(0xFF6D28D9);
  static const accentDark = Color(0xFFA78BFA);

  // ── Light neutrals ────────────────────────────────────────────
  static const ground = Color(0xFFEFEFF1);
  static const ink = Color(0xFF0A0A0B);
  static const muted = Color(0xFF6B6B72);
  static const faint = Color(0xFF9A9AA2);
  static const line = Color(0xFFE4E4E7);
  static const accentSoft = Color(0xFFF1EDFC);
  static const iconSoft = Color(0xFFF4F4F5);

  // ── Dark neutrals ─────────────────────────────────────────────
  // The card has to step up from the ground, not race it to black. The first
  // pass put the ground at #0A0A0B and the card at #141416 — a luminance ratio
  // of 1.08:1, which is no separation at all, so cards vanished into the page.
  // These sit at 1.20:1, a little wider than Material dark (#121212 / #1E1E1E,
  // 1.12:1), because the rule and the shadow are doing less work here than a
  // filled elevation overlay would. The ground stays near-black for OLED; it
  // is the surface that moves.
  static const darkGround = Color(0xFF0D0D0F);
  static const darkSurface = Color(0xFF202026);
  static const darkLine = Color(0xFF3A3A43);
  static const darkInk = Color(0xFFF4F4F6);
  // Both were too dim against the surface for the sizes they get used at:
  // muted carries contact rows, faint carries the 10px role labels.
  static const darkMuted = Color(0xFFB4B4BE);
  static const darkFaint = Color(0xFF8A8A95);

  // Semantic states stay separate from the accent.
  static const pending = Color(0xFFD97706);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);

  static Color surfaceOf(bool isDark) => isDark ? darkSurface : Colors.white;
  static Color groundOf(bool isDark) => isDark ? darkGround : ground;
  static Color accentOf(bool isDark) => isDark ? accentDark : accentLight;
  static Color inkOf(bool isDark) => isDark ? darkInk : ink;
  static Color mutedOf(bool isDark) => isDark ? darkMuted : muted;
  static Color faintOf(bool isDark) => isDark ? darkFaint : faint;
  static Color lineOf(bool isDark) => isDark ? darkLine : line;

  /// Ground for a tinted tile — an icon square, an avatar, a monogram.
  static Color tintOf(bool isDark) =>
      isDark ? accentDark.withOpacity(.18) : accentSoft;

  /// Ink on the accent, for a filled control.
  static Color onAccentOf(bool isDark) =>
      isDark ? const Color(0xFF14101F) : Colors.white;

  /// Almost nothing. A Swiss surface is separated from its ground by a rule,
  /// not by a drop shadow; this exists only to keep a white card from
  /// dissolving into the light-mode ground at the top edge.
  static List<BoxShadow>? shadowOf(bool isDark) => isDark
      ? const [
          // Dark mode gets one too now. The hairline alone was carrying the
          // whole boundary, and a 1px rule is easy to lose on a dim screen.
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ];

  /// Hairline in both modes — the rule does the work the shadow used to.
  static Border borderOf(bool isDark) =>
      Border.all(color: isDark ? darkLine : line, width: hairline);
}

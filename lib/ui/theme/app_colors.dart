import 'package:flutter/material.dart';

/// Swiss palette: a true neutral ramp plus exactly one saturated hue.
///
/// The International Typographic Style spends colour like currency — the
/// ground, the rules and the type are neutral, and the single accent is
/// reserved for what is actionable. Neutrals here carry no colour cast at all;
/// a tinted grey next to a saturated accent reads as a second, muddier hue and
/// costs the accent its signal value.
///
/// Names are unchanged from the previous palette so every call site keeps
/// working — only the values moved.
class AppColors {
  const AppColors._();

  // ── The one accent ────────────────────────────────────────────
  static const primary = Color(0xFF6D28D9); // violet 700 — light mode accent
  static const primaryDark = Color(0xFF4C1D95); // pressed / container
  static const primaryLight = Color(0xFFA78BFA); // dark mode accent

  static const secondary = Color(0xFF8B5CF6);
  static const secondaryLight = Color(0xFFEDE9FE);

  /// Scaffold ground. Off-white rather than pure white: glass panels need
  /// something to sit on before a blur can read as depth.
  static const tertiary = Color(0xFFEFEFF1);

  static const accent = primary;

  // ── Light neutrals ────────────────────────────────────────────
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF7F7F8);
  static const background = Color(0xFFEFEFF1);

  static const textPrimary = Color(0xFF0A0A0B);
  static const textMuted = Color(0xFF6B6B72);
  static const line = Color(0xFFE4E4E7);

  // ── Dark neutrals ─────────────────────────────────────────────
  // Lifted off true black so surfaces can step up from the ground instead of
  // dissolving into it. Mirrors Wallet, which is the source for card surfaces.
  static const darkSurface = Color(0xFF0D0D0F);
  static const darkSurfaceAlt = Color(0xFF202026);
  static const darkCard = Color(0xFF202026);
  static const darkLine = Color(0xFF3A3A43);

  // ── Signal colours ────────────────────────────────────────────
  // Kept flat and unmixed. These are read as status, never as decoration.
  static const successBg = Color(0xFFF0FDF4);
  static const successBorder = Color(0xFF16A34A);
  static const successText = Color(0xFF14532D);

  static const warningBg = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFD97706);
  static const warningText = Color(0xFF78350F);

  static const errorBgSoft = Color(0xFFFEF2F2);
  static const errorBorderSoft = Color(0xFFDC2626);
  static const errorTextSoft = Color(0xFF7F1D1D);

  static const errorBg = Color(0xFFDC2626);
  static const errorBorder = Color(0xFFB91C1C);
  static const errorText = Colors.white;
}

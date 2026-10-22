import 'package:flutter/material.dart';

import 'wallet_tokens.dart';

/// Swiss palette: a true neutral ramp plus exactly one saturated hue.
///
/// The International Typographic Style spends colour like currency — the
/// ground, the rules and the type are neutral, and the single accent is
/// reserved for what is actionable. Neutrals here carry no colour cast at all;
/// a tinted grey next to a saturated accent reads as a second, muddier hue and
/// costs the accent its signal value.
///
/// Names are unchanged from the previous palette so every call site keeps
/// working. [Wallet] is the canonical source: every value the two share is an
/// alias of it here, so the palette can only change in one place.
class AppColors {
  const AppColors._();

  // ── The one accent ────────────────────────────────────────────
  static const primary = Wallet.accentLight; // violet 700 — light mode accent
  static const primaryDark = Color(0xFF4C1D95); // pressed / container
  static const primaryLight = Wallet.accentDark; // dark mode accent

  static const secondary = Color(0xFF8B5CF6);
  static const secondaryLight = Color(0xFFEDE9FE);

  /// Scaffold ground. Off-white rather than pure white: glass panels need
  /// something to sit on before a blur can read as depth.
  static const tertiary = Wallet.ground;

  static const accent = primary;

  // ── Light neutrals ────────────────────────────────────────────
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF7F7F8);
  static const background = Wallet.ground;

  static const textPrimary = Wallet.ink;
  static const textMuted = Wallet.muted;
  static const line = Wallet.line;

  // ── Dark neutrals ─────────────────────────────────────────────
  // Lifted off true black so surfaces can step up from the ground instead of
  // dissolving into it. Mirrors Wallet, which is the source for card surfaces.
  static const darkSurface = Wallet.darkGround;
  static const darkSurfaceAlt = Wallet.darkSurface;
  static const darkCard = Wallet.darkSurface;
  static const darkLine = Wallet.darkLine;

  // ── Signal colours ────────────────────────────────────────────
  // Kept flat and unmixed. These are read as status, never as decoration.
  static const successBg = Color(0xFFF0FDF4);
  static const successBorder = Wallet.success;
  static const successText = Color(0xFF14532D);

  static const warningBg = Color(0xFFFFFBEB);
  static const warningBorder = Wallet.pending;
  static const warningText = Color(0xFF78350F);

  static const errorBgSoft = Color(0xFFFEF2F2);
  static const errorBorderSoft = Wallet.danger;
  static const errorTextSoft = Color(0xFF7F1D1D);

  static const errorBg = Wallet.danger;
  static const errorBorder = Color(0xFFB91C1C);
  static const errorText = Colors.white;
}

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // User's new brand palette
  static const primary = Color(0xFF6D28D9);        // Deep purple
  static const primaryDark = Color(0xFF4C1D95);    // Darker purple
  static const primaryLight = Color(0xFF8B5CF6);   // Lighter purple

  static const secondary = Color(0xFFC4B5FD);      // Soft lavender
  static const secondaryLight = Color(0xFFE0D7FF); // Very light lavender

  static const tertiary = Color(0xFFFAF7FF);       // Off-white purple tint

  static const accent = Color(0xFF7C3AED);         // Vibrant purple accent

  // Surfaces & backgrounds
  static const surface = Color(0xFFF8FAFD);
  static const surfaceSoft = Color(0xFFF7F8FC);
  static const background = Color(0xFFE9EDF4);

  // Dark surfaces tuned to purple
  static const darkSurface = Color(0xFF0F0A1F);
  static const darkSurfaceAlt = Color(0xFF1A1433);
  static const darkCard = Color(0xFF1F1838);

  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF667085);

  // Keep status colors, or lightly tint them purple-ish if desired
  static const successBg = Color(0xFFDCEBFF);
  static const successBorder = Color(0xFFBFDBFE);
  static const successText = Color(0xFF1E3A8A);

  static const warningBg = Color(0xFFFFEDD5);
  static const warningBorder = Color(0xFFFED7AA);
  static const warningText = Color(0xFF9A3412);

  static const errorBgSoft = Color(0xFFFEE2E2);
  static const errorBorderSoft = Color(0xFFFECACA);
  static const errorTextSoft = Color(0xFFB42318);

  static const errorBg = Color(0xFFB42318);
  static const errorBorder = Color(0xFFDC2626);
  static const errorText = Colors.white;
}

import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';

/// The shared sign-up text field.
///
/// What used to live here — the backdrop, the glass card, the progress bar,
/// the circle button and the loading overlay — was replaced by
/// `onboarding_step_scaffold.dart`, which owns the whole step frame rather
/// than a bag of parts each page had to assemble itself. Only the field
/// survived, because it is the one piece that is genuinely a leaf.

class OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;

  final String hintText;
  final IconData prefixIcon;

  final bool obscureText;
  final Widget? suffix;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  final String? Function(String?)? validator;

  const OnboardingTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusControl),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      // Regular weight: what the user types is content, not a heading. Bold
      // input reads as shouting and makes long values (emails) hard to scan.
      style: AppTypography.secondary(TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Wallet.inkOf(isDark),
      )),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.secondary(TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Wallet.faintOf(isDark),
        )),
        filled: true,
        // Slightly more opaque than the panel behind it, so the field reads as
        // an inset in the glass rather than another pane stacked on it.
        fillColor: isDark
            ? Colors.white.withOpacity(.05)
            : Colors.white.withOpacity(.88),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        prefixIcon: Icon(prefixIcon, size: 19, color: Wallet.faintOf(isDark)),
        suffixIcon: suffix,
        // The field had no focus state at all — only the caret told you where
        // you were typing.
        enabledBorder: border(Wallet.lineOf(isDark), Wallet.hairline),
        focusedBorder: border(Wallet.accentOf(isDark), 1.5),
        errorBorder: border(Wallet.danger, Wallet.hairline),
        focusedErrorBorder: border(Wallet.danger, 1.5),
        disabledBorder: border(Wallet.lineOf(isDark), Wallet.hairline),
        errorStyle: AppTypography.secondary(
          const TextStyle(fontSize: 11.5, color: Wallet.danger),
        ),
      ),
    );
  }
}


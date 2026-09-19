import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';

/// Desktop-web chrome for the auth flow: one neumorphic card — soft-extruded
/// from the same neutral ground it sits on, no illustration, no split panel,
/// no colour but the one accent rule under the wordmark — instead of the
/// mobile hero. Mobile never builds this — callers only reach for it once
/// [Responsive.isDesktop] is true.
class AuthWebCard extends StatelessWidget {
  const AuthWebCard({
    super.key,
    required this.form,
    this.tagline = 'Your business card, always in your pocket.',
  });

  final Widget form;
  final String tagline;

  /// The ground and the card share this colour; the card reads as raised
  /// purely from the dual shadow below, which is the whole neumorphic trick.
  static const _ground = Wallet.ground;
  static const _shadowDark = Color(0xFFC7CBD3);
  static const _shadowLight = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.fromLTRB(48, 48, 48, 44),
            decoration: BoxDecoration(
              color: _ground,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: _shadowLight,
                  offset: Offset(-10, -10),
                  blurRadius: 24,
                ),
                BoxShadow(
                  color: _shadowDark,
                  offset: Offset(10, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'businessCard',
                      style: AppTypography.primary(
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Wallet.ink,
                        ),
                      ),
                      children: const [
                        TextSpan(
                          text: '4U',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // The one accent, spent on a rule rather than a fill — the
                // Swiss keyline standing in for the mobile hero's wave.
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  tagline,
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary(
                    const TextStyle(
                      fontSize: 13,
                      color: Wallet.muted,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                form,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A neumorphic input surface — extruded from [AuthWebCard]'s own ground the
/// same way the card is extruded from the page, at a smaller, tighter radius
/// so it reads as nested rather than as a second unrelated card. Desktop-web
/// auth forms only; mobile keeps its own flat white fields.
class NeumorphicField extends StatelessWidget {
  const NeumorphicField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.focusNode,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final FocusNode? focusNode;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuthWebCard._ground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AuthWebCard._shadowDark,
            offset: Offset(3, 3),
            blurRadius: 6,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: AuthWebCard._shadowLight,
            offset: Offset(-3, -3),
            blurRadius: 6,
            spreadRadius: -2,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: AppTypography.secondary(
          const TextStyle(color: Wallet.ink, fontWeight: FontWeight.w400),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.tertiary(
            const TextStyle(color: Wallet.muted),
          ),
          prefixIcon: Icon(icon, color: Wallet.muted, size: 20),
          suffixIcon: suffix,
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// The primary action, raised the same way the card is — but carrying the
/// one accent, since this is the thing on the page that is actionable.
class NeumorphicButton extends StatelessWidget {
  const NeumorphicButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.primary.withOpacity(.5)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(.35),
                      offset: const Offset(4, 6),
                      blurRadius: 14,
                    ),
                  ],
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: AppTypography.primary(
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

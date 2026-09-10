import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';
import 'loading_view.dart';

/// The primary action: one flat block of accent.
///
/// The gradient and the coloured glow are gone. A Swiss primary reads as
/// primary because it is the only saturated block on the screen and it is
/// wider and heavier than everything near it — not because it glows. Gradients
/// also fight the frosted panels, which need a stable colour behind them to
/// refract cleanly.
class AppPrimaryButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;
  final double height;
  final BorderRadius? borderRadius;
  final double fontSize;

  /// Sets the label in tracked caps. Reserve it for short, standing labels
  /// ("CONTINUE", "SAVE") — a long specific CTA is harder to read in caps,
  /// and specific beats loud.
  final bool uppercase;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.loading,
    required this.onPressed,
    this.height = 52,
    this.borderRadius,
    this.fontSize = 15,
    this.uppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(Wallet.radiusControl);
    final accent = Wallet.accentOf(isDark);
    final onAccent = Wallet.onAccentOf(isDark);
    final isDisabled = onPressed == null || loading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: onAccent,
          // Loading is a busy state, not an unavailable one, so the block keeps
          // most of its weight instead of greying out and losing its place in
          // the hierarchy while the request runs.
          disabledBackgroundColor: accent.withOpacity(loading ? .72 : .34),
          disabledForegroundColor: onAccent.withOpacity(.75),
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
        child: Center(
          child: loading
              ? const LoadingView(size: 22)
              : Text(
                  uppercase ? text.toUpperCase() : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: uppercase
                      ? AppTypography.eyebrow(
                          color: isDisabled
                              ? onAccent.withOpacity(.75)
                              : onAccent,
                          fontSize: fontSize - 1,
                          fontWeight: FontWeight.w700,
                        )
                      : AppTypography.secondary(TextStyle(
                          color: isDisabled
                              ? onAccent.withOpacity(.75)
                              : onAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                          letterSpacing: .2,
                        )),
                ),
        ),
      ),
    );
  }
}

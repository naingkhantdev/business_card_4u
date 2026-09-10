import 'dart:ui';
import 'package:flutter/material.dart';

import 'wallet_tokens.dart';

/// Frosted surfaces, kept on a short leash.
///
/// Glass earns its keep only where a surface is genuinely *above* the page —
/// a toast, a sheet, a sticky header, a floating panel. Applied to everything
/// it stops signalling elevation and just costs a `BackdropFilter` per frame,
/// which is the expensive widget in this file. Ordinary content surfaces
/// should stay opaque and use [Wallet.surfaceOf] with a hairline.
///
/// The Swiss part of the compromise is restraint, not squareness: a hairline
/// edge instead of a soft glow, no gradient fill, and one accent. The corner
/// radius stays generous — a blurred edge needs a visible curve to read as a
/// pane of glass rather than as a rectangular crop.
class Glass {
  const Glass._();

  /// Blur radius. High enough that what is behind reads as light rather than
  /// as content — a legible background through glass makes type on top fight
  /// with it.
  static const double blurSigma = 24;

  /// Fill opacity. Dark mode needs a heavier veil: a translucent dark panel
  /// over a dark ground has almost no luminance difference to work with.
  static double fillOpacity(bool isDark) => isDark ? .78 : .72;

  static Color fillOf(bool isDark) => isDark
      ? Wallet.darkSurface.withOpacity(fillOpacity(isDark))
      : Colors.white.withOpacity(fillOpacity(isDark));

  /// The lit edge. On real glass the top rim catches the light; a uniform
  /// border does not, which is what makes flat translucency look like a
  /// lowered opacity rather than a pane.
  static Color edgeOf(bool isDark) => isDark
      ? Colors.white.withOpacity(.10)
      : Colors.white.withOpacity(.70);

  static Color hairlineOf(bool isDark) => isDark
      ? Colors.white.withOpacity(.14)
      : Colors.black.withOpacity(.07);

  /// Cast shadow. Barely there — Swiss reads depth from the rule, not the glow.
  static List<BoxShadow> shadowOf(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? .40 : .07),
          blurRadius: 28,
          offset: const Offset(0, 12),
          spreadRadius: -8,
        ),
      ];
}

/// A frosted panel: blur, translucent fill, hairline edge, lit top rim.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  /// Cast a shadow beneath the panel. Off for panels that sit flush against
  /// an edge (a sticky header, a bottom bar) where a shadow would read as a
  /// seam rather than as lift.
  final bool elevated;

  /// Paints the accent as a 3px rule down the leading edge — the Swiss
  /// keyline. Used by the toast to carry status without a coloured fill.
  final Color? rule;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = Wallet.radiusPanel,
    this.blur = Glass.blurSigma,
    this.elevated = true,
    this.rule,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Glass.fillOf(isDark),
        borderRadius: shape,
        border: Border.all(color: Glass.hairlineOf(isDark), width: 1),
      ),
      child: child,
    );

    if (rule != null) {
      content = Stack(
        children: [
          content,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: rule),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: elevated ? Glass.shadowOf(isDark) : null,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

/// The ground glass sits on.
///
/// A blur needs something behind it with structure, or it resolves to a flat
/// wash. Two low-saturation accent fields, well off-centre, give the panels
/// something to refract without introducing a second hue into the palette.
class GlassBackdrop extends StatelessWidget {
  final Widget? child;
  const GlassBackdrop({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: Wallet.groundOf(isDark))),
        Positioned(
          top: -140,
          left: -90,
          child: _Field(
            size: 320,
            color: Wallet.accentOf(isDark).withOpacity(isDark ? .16 : .13),
          ),
        ),
        Positioned(
          bottom: -180,
          right: -110,
          child: _Field(
            size: 380,
            color: Wallet.accentOf(isDark).withOpacity(isDark ? .10 : .08),
          ),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final double size;
  final Color color;
  const _Field({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// A frosted scrim for modal loading states.
///
/// Deliberately not `Positioned.fill` — it expands to whatever it is given, so
/// it works both as a page overlay (wrap it in `Positioned.fill` inside a
/// `Stack`) and as an inline block. Baking the positioning in would make the
/// second case impossible.
class GlassScrim extends StatelessWidget {
  final Widget child;
  const GlassScrim({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        constraints: const BoxConstraints.expand(),
        color: isDark
            ? Colors.black.withOpacity(.42)
            : Colors.white.withOpacity(.52),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

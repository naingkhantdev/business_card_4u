import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/wallet_tokens.dart';

/// The very first thing the app shows, while [AuthGate] is still deciding
/// whether anyone is signed in.
///
/// Modelled on a cinematic studio splash (trionn.com): a stage with a
/// drifting ambient glow, a hand-drawn accent curve that traces itself in,
/// and the wordmark rising into place line by line rather than just
/// appearing — instead of the plain fading app icon this replaced. Colors
/// follow the system theme like the rest of the app, rather than the
/// reference's always-dark background.
/// Two pieces of that reference don't translate to an auto-dismissing
/// mobile loading screen and are deliberately left out: the "hold to
/// blast" trigger (there's nothing to explore — this screen just waits on
/// auth) and the custom mouse-trail cursor (a touch screen has no cursor).
/// The percentage counter is real content, not just decoration: it eases
/// up and holds just under 100 because this screen is swapped out the
/// instant auth actually resolves, so it must never claim to be done
/// while still on screen.
class AppSplashView extends StatefulWidget {
  const AppSplashView({super.key});

  @override
  State<AppSplashView> createState() => _AppSplashViewState();
}

class _AppSplashViewState extends State<AppSplashView>
    with TickerProviderStateMixin {
  /// Drives the one-shot entrance: curve draw, then the wordmark and tagline
  /// staggered in behind it.
  late final AnimationController _introController;

  /// Loops for as long as the screen is up, drifting the ambient glow.
  late final AnimationController _glowController;

  /// Eases the percentage counter up and holds it shy of 100.
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// A 0..1 slice of the intro, so each element can be staggered like a
  /// GSAP timeline instead of all animating over the same span.
  double _slice(double start, double end) {
    final t = (_introController.value - start) / (end - start);
    return Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final accent = Wallet.accentOf(isDark);
    final ink = Wallet.inkOf(isDark);
    final muted = Wallet.mutedOf(isDark);
    final faint = Wallet.faintOf(isDark);

    return Scaffold(
      backgroundColor: Wallet.groundOf(isDark),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, __) => CustomPaint(
              painter: _AmbientGlowPainter(
                t: _glowController.value,
                color: accent,
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _introController,
              builder: (_, __) {
                final curveT = _slice(0, 0.45);
                final businessT = _slice(0.15, 0.62);
                final fourUT = _slice(0.35, 0.82);
                final taglineT = _slice(0.62, 1.0);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 20,
                      child: CustomPaint(
                        painter: _StrokePainter(t: curveT, color: accent),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          _RiseReveal(
                            t: businessT,
                            child: Text(
                              'BusinessCard',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.4,
                                color: ink,
                              ),
                            ),
                          ),
                          _RiseReveal(
                            t: fourUT,
                            child: Text(
                              '4U',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      opacity: taglineT,
                      child: Text(
                        l10n.appSplashTagline,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.2,
                          color: faint,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (_, __) {
                final eased =
                    Curves.easeOutCubic.transform(_progressController.value);
                final percent = (eased * 96).round();
                return Center(
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: muted,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Reveals [child] by sliding it up out of an invisible baseline as [t]
/// goes 0→1 — the masked, line-by-line push used for the wordmark and,
/// staggered a beat later, its suffix.
class _RiseReveal extends StatelessWidget {
  final double t;
  final Widget child;

  const _RiseReveal({required this.t, required this.child});

  @override
  Widget build(BuildContext context) {
    final clamped = t.clamp(0.0, 1.0);
    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        // widthFactor: 1.0 keeps this shrink-wrapped to the text's own
        // width — without it, Align expands to fill the Row's available
        // width and "Business" and "4U" both center independently instead
        // of sitting side by side.
        widthFactor: 1.0,
        heightFactor: clamped,
        child: Opacity(opacity: clamped, child: child),
      ),
    );
  }
}

/// The accent curve above the wordmark, tracing itself in — a small nod to
/// the fluid SVG curve that opens the reference site, drawn as a single
/// stroked arc instead of an SVG asset.
class _StrokePainter extends CustomPainter {
  final double t;
  final Color color;

  const _StrokePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.6,
        size.width,
        size.height * 0.8,
      );

    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * t);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [color.withOpacity(0), color, color.withOpacity(0)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

/// Two soft, slowly drifting glows behind the wordmark — the closest a
/// couple of `Canvas` gradients get to the reference's WebGL ripple
/// background without pulling in a shader dependency for one splash frame.
class _AmbientGlowPainter extends CustomPainter {
  final double t; // 0..1, looping
  final Color color;

  const _AmbientGlowPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;

    void blob(Offset center, double radius, double opacity) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final center1 = Offset(
      size.width * 0.3 + math.cos(angle) * size.width * 0.06,
      size.height * 0.35 + math.sin(angle) * size.height * 0.05,
    );
    final center2 = Offset(
      size.width * 0.72 + math.sin(angle) * size.width * 0.05,
      size.height * 0.68 + math.cos(angle) * size.height * 0.06,
    );

    blob(center1, size.shortestSide * 0.45, 0.16);
    blob(center2, size.shortestSide * 0.38, 0.12);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) =>
      oldDelegate.t != t;
}

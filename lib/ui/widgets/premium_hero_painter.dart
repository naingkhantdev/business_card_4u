import 'package:flutter/material.dart';

/// The soft wave used behind the login hero's wordmark, on mobile and
/// (enlarged) on web — shared so both layouts paint the same shape.
class PremiumHeroPainter extends CustomPainter {
  /// White in light mode, a dark surface tone in dark mode — the caller
  /// picks it so this painter doesn't need to know about themes itself.
  final Color color;

  PremiumHeroPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    // Back to a single plain arc — the double-curl meant to echo "လ" didn't
    // read well and went through a few blind size adjustments without
    // landing. A plain wave, confined to a shallow band near the bottom
    // edge, is a safer shape to get right without seeing it rendered.
    final path = Path();
    path.lineTo(0, size.height * 0.85);

    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.02,
      size.width,
      size.height * 0.88,
    );

    path.lineTo(size.width, 0);
    path.close();

    // A flat white fill on a near-white page had no edge to read as a wave
    // at all — it just looked like a flat white background. A soft shadow
    // gives the shape a defined edge, the way every other raised surface in
    // this app gets one.
    canvas.drawShadow(path, Colors.black, 5, false);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PremiumHeroPainter oldDelegate) =>
      oldDelegate.color != color;
}

import 'package:flutter/material.dart';

/// The soft white wave used behind the login hero's wordmark, on mobile and
/// (enlarged) on web — shared so both layouts paint the same shape.
class PremiumHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height * 0.75);

    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 1.05,
      size.width,
      size.height * 0.85,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

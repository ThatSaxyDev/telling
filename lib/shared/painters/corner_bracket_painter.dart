import 'package:flutter/material.dart';

/// Custom painter for tactical corner brackets
class CornerBracketPainter extends CustomPainter {
  final Color color;
  final bool isTopLeft;

  CornerBracketPainter({
    required this.color,
    required this.isTopLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (isTopLeft) {
      // Top-left corner bracket
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else {
      // Bottom-right corner bracket
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CornerBracketPainter oldDelegate) =>
      color != oldDelegate.color || isTopLeft != oldDelegate.isTopLeft;
}

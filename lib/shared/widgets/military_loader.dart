import 'dart:math' as math;
import 'package:flutter/material.dart';

class MilitaryLoader extends StatefulWidget {
  final double size;
  final Color color;
  final String? label;

  const MilitaryLoader({
    super.key,
    this.size = 100.0,
    this.color = Colors.white,
    this.label = 'INITIALIZING...',
  });

  @override
  State<MilitaryLoader> createState() => _MilitaryLoaderState();
}

class _MilitaryLoaderState extends State<MilitaryLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _LoaderPainter(
                  progress: _controller.value,
                  color: widget.color,
                ),
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.label!,
            style: TextStyle(
              color: widget.color,
              fontFamily: 'Syne',
              fontSize: 12,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  _LoaderPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer Ring (Rotating Clockwise)
    final outerRect = Rect.fromCircle(center: center, radius: radius);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);
    
    // Draw segmented outer ring
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        outerRect,
        (i * 90.0 + 15) * math.pi / 180,
        60 * math.pi / 180,
        false,
        paint,
      );
    }
    canvas.restore();

    // Middle Ring (Rotating Counter-Clockwise)
    final middleRadius = radius * 0.7;
    final middleRect = Rect.fromCircle(center: center, radius: middleRadius);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-progress * 2 * math.pi * 1.5); // Faster rotation
    canvas.translate(-center.dx, -center.dy);

    paint.strokeWidth = 1.5;
    // Draw segmented middle ring (3 segments)
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        middleRect,
        (i * 120.0) * math.pi / 180,
        90 * math.pi / 180,
        false,
        paint,
      );
    }
    canvas.restore();

    // Inner Core (Pulsing)
    final innerRadius = radius * 0.3;
    final pulse = (math.sin(progress * 4 * math.pi) + 1) / 2; // 0 to 1
    
    paint.style = PaintingStyle.fill;
    paint.color = color.withAlpha(
      77 + (pulse * 179).round(),
    ); // Pulse alpha: 77-255
    canvas.drawCircle(center, innerRadius, paint);

    // Inner Core Border
    paint.style = PaintingStyle.stroke;
    paint.color = color;
    paint.strokeWidth = 1.0;
    canvas.drawCircle(center, innerRadius, paint);
    
    // Crosshair lines
    paint.strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

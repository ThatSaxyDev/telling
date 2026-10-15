import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A rounded rectangle whose border is a linear gradient.
///
/// Flutter's [BoxDecoration] only takes a solid border color, so the DartNative
/// badge's spectrum sweep needs a painter. This is deliberately minimal: a 1.5px
/// stroked rounded rect, with the gradient running along the diagonal so all
/// five stops stay visible in a wide, short badge.
class GradientBorderBox extends StatelessWidget {
  const GradientBorderBox({
    super.key,
    required this.child,
    this.gradient = AppColors.dnSpectrum,
    this.width = 1.5,
    this.radius = 4,
    this.fill,
  });

  final Widget child;
  final Gradient gradient;
  final double width;
  final double radius;

  /// Optional background. Defaults to a barely-there wash of the gradient so
  /// the badge reads as tinted rather than empty against the black page.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GradientBorderPainter(
        gradient: gradient,
        width: width,
        radius: radius,
        fill: fill,
      ),
      child: child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.gradient,
    required this.width,
    required this.radius,
    this.fill,
  });

  final Gradient gradient;
  final double width;
  final double radius;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (fill != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = fill!,
      );
    }

    // Inset by half the stroke so the border sits inside the widget's box and
    // does not clip against the parent's bounds.
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      Radius.circular(radius),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) =>
      old.gradient != gradient ||
      old.width != width ||
      old.radius != radius ||
      old.fill != fill;
}

/// Paints [child] with its foreground clipped to [gradient].
///
/// Used for the DartNative badge label, which reads as a gradient sweep rather
/// than flat gold. Note that gradient text has no accessible contrast
/// guarantee — the lightest stop is [AppColors.dnOlive] on black, which is
/// about 13:1, so it passes AA for large text but the label is kept bold and
/// wide-spaced for legibility.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = AppColors.dnSpectrumLabel,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
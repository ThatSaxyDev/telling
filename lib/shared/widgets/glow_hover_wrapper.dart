import 'dart:math';
import 'package:flutter/material.dart';

/// A wrapper that applies grayscale filter by default and transitions to
/// full color with neon glow on hover.
class GlowHoverWrapper extends StatefulWidget {
  final Widget child;
  final Color? glowColor;
  final double glowIntensity;
  final Duration animationDuration;

  const GlowHoverWrapper({
    super.key,
    required this.child,
    this.glowColor,
    this.glowIntensity = 0.25,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<GlowHoverWrapper> createState() => _GlowHoverWrapperState();
}

class _GlowHoverWrapperState extends State<GlowHoverWrapper> {
  bool _isHovered = false;
  Color? _selectedGlowColor;

  // Neon color palette
  static final List<Color> _neonColors = [
    const Color(0xFF00FFFF), // Cyan
    const Color(0xFFFF00FF), // Magenta
    const Color(0xFF00FF00), // Lime
    const Color(0xFFFF6600), // Orange
    const Color(0xFFFF0080), // Hot Pink
    const Color(0xFF00D4FF), // Electric Blue
    const Color(0xFFFFFF00), // Yellow
    const Color(0xFF9D00FF), // Purple
    const Color(0xFF39FF14), // Neon Green
    const Color(0xFFFF1493), // Deep Pink
    const Color(0xFF7FFF00), // Chartreuse
    const Color(0xFFFF073A), // Neon Red
  ];

  Color get glowColor {
    if (_selectedGlowColor == null) {
      if (widget.glowColor != null) {
        _selectedGlowColor = widget.glowColor;
      } else {
        // Use microseconds for better entropy
        final random = Random(DateTime.now().microsecondsSinceEpoch);
        _selectedGlowColor = _neonColors[random.nextInt(_neonColors.length)];
      }
    }
    return _selectedGlowColor!;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: glowColor.withOpacity(widget.glowIntensity),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: glowColor.withOpacity(widget.glowIntensity * 0.5),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ]
              : [],
        ),
        child: ColorFiltered(
          colorFilter: _isHovered
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.matrix(<double>[
                  // Grayscale matrix
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
          child: widget.child,
        ),
      ),
    );
  }
}

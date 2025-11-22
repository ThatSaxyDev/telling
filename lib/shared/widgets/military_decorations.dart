import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A widget that adds military-style corner brackets to its child.
class CornerBrackets extends StatelessWidget {
  final Widget child;
  final Color color;
  final double length;
  final double thickness;
  final double offset;

  const CornerBrackets({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.length = 10.0,
    this.thickness = 1.0,
    this.offset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _CornerPainter(
                color: color,
                length: length,
                thickness: thickness,
                offset: offset,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double length;
  final double thickness;
  final double offset;

  _CornerPainter({
    required this.color,
    required this.length,
    required this.thickness,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final path = Path();
    final o = offset;
    final l = length;

    // Top Left
    path.moveTo(o, o + l);
    path.lineTo(o, o);
    path.lineTo(o + l, o);

    // Top Right
    path.moveTo(size.width - o - l, o);
    path.lineTo(size.width - o, o);
    path.lineTo(size.width - o, o + l);

    // Bottom Right
    path.moveTo(size.width - o, size.height - o - l);
    path.lineTo(size.width - o, size.height - o);
    path.lineTo(size.width - o - l, size.height - o);

    // Bottom Left
    path.moveTo(o + l, size.height - o);
    path.lineTo(o, size.height - o);
    path.lineTo(o, size.height - o - l);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A widget that draws a subtle technical grid background.
class GridBackground extends StatefulWidget {
  final Color color;
  final double spacing;
  final double strokeWidth;

  const GridBackground({
    super.key,
    this.color = const Color(0xFF222222),
    this.spacing = 40.0,
    this.strokeWidth = 0.5,
  });

  @override
  State<GridBackground> createState() => _GridBackgroundState();
}

class _GridBackgroundState extends State<GridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<GridPulse> _pulses = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    // Create initial pulses
    _createInitialPulses();

    // Add listener to periodically add new pulses
    _controller.addListener(() {
      if (_random.nextDouble() < 0.005) {
        // 0.5% chance per frame (much less frequent)
        _addRandomPulse();
      }

      // Remove completed pulses
      _pulses.removeWhere((pulse) => pulse.progress > 1.0);
    });
  }

  void _createInitialPulses() {
    // Start with just 1 pulse
    _addRandomPulse();
  }

  void _addRandomPulse() {
    if (_pulses.length < 4) {
      // Max 4 pulses at once (reduced from 8)
      final isVertical = _random.nextBool();

      // Calculate number of grid lines
      // We'll use a large canvas size estimate to get grid line count
      final numLines = isVertical ? 50 : 30; // Approximate grid lines
      final lineIndex = _random.nextInt(numLines);

      _pulses.add(
        GridPulse(
          isVertical: isVertical,
          lineIndex: lineIndex,
          speed:
              0.002 +
              _random.nextDouble() * 0.003, // Much slower (was 0.005-0.015)
          startTime: DateTime.now(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Update pulse progress
          for (var pulse in _pulses) {
            pulse.updateProgress();
          }

          return CustomPaint(
            painter: _GridPainter(
              color: widget.color,
              spacing: widget.spacing,
              strokeWidth: widget.strokeWidth,
              pulses: _pulses,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class GridPulse {
  final bool isVertical;
  final int lineIndex; // Which grid line (0, 1, 2, etc.)
  final double speed;
  final DateTime startTime;
  double progress = 0.0;

  GridPulse({
    required this.isVertical,
    required this.lineIndex,
    required this.speed,
    required this.startTime,
  });

  void updateProgress() {
    progress += speed;
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double strokeWidth;
  final List<GridPulse> pulses;

  _GridPainter({
    required this.color,
    required this.spacing,
    required this.strokeWidth,
    required this.pulses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw pulses
    for (var pulse in pulses) {
      if (pulse.progress <= 1.0) {
        _drawPulse(canvas, size, pulse);
      }
    }
  }

  void _drawPulse(Canvas canvas, Size size, GridPulse pulse) {
    final pulsePaint = Paint()
      ..strokeWidth = strokeWidth * 1.5
      ..style = PaintingStyle.stroke;

    const pulseLength = 100.0; // Shorter pulse (was 150)

    if (pulse.isVertical) {
      // Vertical pulse - align to exact grid line
      final x = (pulse.lineIndex * spacing) % size.width;
      final startY = (size.height * pulse.progress) - pulseLength;
      final endY = size.height * pulse.progress;

      // Create subtle gradient (much dimmer - 30% opacity)
      pulsePaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.3), // Was 1.0, now 0.3
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x, startY, 1, pulseLength));

      canvas.drawLine(
        Offset(x, startY.clamp(0, size.height)),
        Offset(x, endY.clamp(0, size.height)),
        pulsePaint,
      );
    } else {
      // Horizontal pulse - align to exact grid line
      final y = (pulse.lineIndex * spacing) % size.height;
      final startX = (size.width * pulse.progress) - pulseLength;
      final endX = size.width * pulse.progress;

      pulsePaint.shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.3), // Was 1.0, now 0.3
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(startX, y, pulseLength, 1));

      canvas.drawLine(
        Offset(startX.clamp(0, size.width), y),
        Offset(endX.clamp(0, size.width), y),
        pulsePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}

/// A widget that adds an animated scanline effect.
class Scanline extends StatefulWidget {
  final Color color;
  final Duration duration;

  const Scanline({
    super.key,
    this.color = const Color(0x1AFFFFFF), // Low opacity white
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<Scanline> createState() => _ScanlineState();
}

class _ScanlineState extends State<Scanline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ScanlinePainter(
              progress: _controller.value,
              color: widget.color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanlinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(
        0,
        size.height * progress - 100, // Move the gradient
        size.width,
        200, // Height of the scanline
      ));

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * progress - 100,
        size.width,
        200,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// A custom crosshair cursor that follows the mouse.
class CrosshairCursor extends StatefulWidget {
  final Widget child;
  final Color color;

  const CrosshairCursor({
    super.key,
    required this.child,
    this.color = AppColors.white,
  });

  @override
  State<CrosshairCursor> createState() => _CrosshairCursorState();
}

class _CrosshairCursorState extends State<CrosshairCursor> {
  Offset? _mousePosition;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.none, // Hide default cursor
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _mousePosition = null;
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_mousePosition != null)
            Positioned(
              left: _mousePosition!.dx - 15,
              top: _mousePosition!.dy - 15,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CrosshairPainter(color: widget.color),
                  size: const Size(30, 30),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final length = 10.0;
    final gap = 4.0;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - length, center.dy),
      Offset(center.dx - gap, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + length, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - length),
      Offset(center.dx, center.dy - gap),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + length),
      paint,
    );
    
    // Center dot
    canvas.drawCircle(center, 1, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A widget that applies a glitch effect to its child text.
class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double glitchAmount;

  const GlitchText({
    super.key,
    required this.text,
    required this.style,
    this.glitchAmount = 1.0,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  final Random _random = Random();

  double _offset1X = 0;
  double _offset1Y = 0;
  double _offset2X = 0;
  double _offset2Y = 0;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _startGlitchLoop();
  }

  void _startGlitchLoop() {
    _timer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (!mounted) return;
      _triggerGlitch();
    });
  }

  void _triggerGlitch() async {
    if (!mounted) return;

    setState(() => _isGlitching = true);

    // Rapidly change offsets
    for (int i = 0; i < 5; i++) {
      if (!mounted) return;
      setState(() {
        _offset1X = (_random.nextDouble() * 4 - 2) * widget.glitchAmount;
        _offset1Y = (_random.nextDouble() * 4 - 2) * widget.glitchAmount;
        _offset2X = (_random.nextDouble() * 4 - 2) * widget.glitchAmount;
        _offset2Y = (_random.nextDouble() * 4 - 2) * widget.glitchAmount;
      });
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (mounted) {
      setState(() {
        _isGlitching = false;
        _offset1X = 0;
        _offset1Y = 0;
        _offset2X = 0;
        _offset2Y = 0;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Cyan Channel
        if (_isGlitching)
          Transform.translate(
            offset: Offset(_offset1X, _offset1Y),
            child: Text(
              widget.text,
              style: widget.style.copyWith(color: Colors.cyan.withOpacity(0.7)),
            ),
          ),

        // Red Channel
        if (_isGlitching)
          Transform.translate(
            offset: Offset(_offset2X, _offset2Y),
            child: Text(
              widget.text,
              style: widget.style.copyWith(color: Colors.red.withOpacity(0.7)),
            ),
          ),

        // Main Text
        Text(widget.text, style: widget.style),
      ],
    );
  }
}

/// A widget that reveals text character by character.
class TypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final Duration delay;
  final VoidCallback? onComplete;

  const TypingText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 50),
    this.delay = Duration.zero,
    this.onComplete,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayedText = '';
  late Timer _timer;
  int _currentIndex = 0;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }

    if (!mounted) return;

    setState(() => _isStarted = true);

    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            _displayedText = widget.text.substring(0, _currentIndex + 1);
            _currentIndex++;
          });
        }
      } else {
        _timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: _displayedText, style: widget.style),
          if (_isStarted && _currentIndex < widget.text.length)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Container(
                width: 10,
                height: widget.style.fontSize ?? 14,
                color: AppColors.secondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// A container that animates its military decorations on hover.
class MilitaryHoverContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color baseColor;
  final Color hoverColor;
  final bool showGrid;

  const MilitaryHoverContainer({
    super.key,
    required this.child,
    this.onTap,
    this.baseColor = AppColors.slate,
    this.hoverColor = AppColors.white,
    this.showGrid = false,
  });

  @override
  State<MilitaryHoverContainer> createState() => _MilitaryHoverContainerState();
}

class _MilitaryHoverContainerState extends State<MilitaryHoverContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thicknessAnim;
  late Animation<double> _lengthAnim;
  late Animation<Color?> _colorAnim;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _thicknessAnim = Tween<double>(
      begin: 1.0,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _lengthAnim = Tween<double>(
      begin: 8.0,
      end: 16.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _colorAnim = ColorTween(
      begin: widget.baseColor.withOpacity(0.5),
      end: widget.hoverColor,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Optional Grid Background on Hover
                if (widget.showGrid && _isHovered)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: GridBackground(
                        color: widget.hoverColor,
                        spacing: 10,
                      ),
                    ),
                  ),

                // Main Content with Corner Brackets
                CornerBrackets(
                  color: _colorAnim.value ?? widget.baseColor,
                  thickness: _thicknessAnim.value,
                  length: _lengthAnim.value,
                  offset: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? widget.hoverColor.withOpacity(0.08)
                          : Colors.transparent,
                      border: Border.all(
                        color: (_colorAnim.value ?? widget.baseColor)
                            .withOpacity(_isHovered ? 0.6 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../core/models/analytics_models.dart';
import '../../../core/theme/app_colors.dart';

class FunnelChartWidget extends StatelessWidget {
  final FunnelData funnelData;
  final bool isMobile;

  const FunnelChartWidget({
    super.key,
    required this.funnelData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Overall Conversion Rate Card
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.white.withAlpha(26),
            border: Border.all(color: AppColors.white.withAlpha(77)),
          ),
          child: Column(
            children: [
              const Text(
                'OVERALL CONVERSION RATE',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${funnelData.overallConversion.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Urbanist',
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 8),
              if (funnelData.steps.isNotEmpty)
                Text(
                  '${NumberFormat('#,###').format(funnelData.steps.last.count)} of ${NumberFormat('#,###').format(funnelData.steps.first.count)} users',
                  style: TextStyle(
                    color: AppColors.slate.withAlpha(179),
                    fontSize: 13,
                    fontFamily: 'Urbanist',
                  ),
                ),
            ],
          ),
        ),

        // Funnel Visualization
        SizedBox(
          height: isMobile ? 500 : 600,
          child: CustomPaint(
            painter: _FunnelPainter(funnelData: funnelData),
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class _FunnelPainter extends CustomPainter {
  final FunnelData funnelData;

  _FunnelPainter({required this.funnelData});

  @override
  void paint(Canvas canvas, Size size) {
    if (funnelData.steps.isEmpty) return;

    final maxCount = funnelData.steps.first.count.toDouble();
    final stepHeight = size.height / funnelData.steps.length;
    
    for (int i = 0; i < funnelData.steps.length; i++) {
      final step = funnelData.steps[i];
      final yStart = i * stepHeight;
      final widthRatio = step.count / maxCount;
      final barWidth = size.width * 0.6 * widthRatio;
      final xCenter = size.width / 2;

      // Draw funnel bar (trapezoid)
      final barPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            AppColors.white.withAlpha(128),
            AppColors.slate.withAlpha(77),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(
          Rect.fromLTWH(xCenter - barWidth / 2, yStart, barWidth, stepHeight - 20),
        );

      // Using Rect for brutalist look (no rounded corners)
      final barRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        yStart + 10,
        barWidth,
        stepHeight - 30,
      );

      canvas.drawRect(barRect, barPaint);

      // Draw border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.white.withAlpha(128)
        ..strokeWidth = 1.5;

      canvas.drawRect(barRect, borderPaint);

      // Draw step info
      _drawStepInfo(
        canvas,
        size,
        step,
        xCenter,
        yStart,
        stepHeight,
        barWidth,
      );

      // Draw conversion connector (if not first step)
      if (i > 0 && step.conversionFromPrevious != null) {
        _drawConversionConnector(
          canvas,
          size,
          step.conversionFromPrevious!,
          xCenter,
          yStart,
        );
      }
    }
  }

  void _drawStepInfo(
    Canvas canvas,
    Size size,
    FunnelStep step,
    double xCenter,
    double yStart,
    double stepHeight,
    double barWidth,
  ) {
    // Step number and name (left side)
    final stepNumberPainter = TextPainter(
      text: TextSpan(
        text: '${step.stepNumber}',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Urbanist',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    stepNumberPainter.layout();
    stepNumberPainter.paint(
      canvas,
      Offset(20, yStart + stepHeight / 2 - stepNumberPainter.height / 2),
    );

    final stepNamePainter = TextPainter(
      text: TextSpan(
        text: step.name,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontFamily: 'Urbanist',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    stepNamePainter.layout(maxWidth: xCenter - barWidth / 2 - 60);
    stepNamePainter.paint(
      canvas,
      Offset(
        50,
        yStart + stepHeight / 2 - stepNamePainter.height / 2,
      ),
    );

    // Count (right side)
    final countPainter = TextPainter(
      text: TextSpan(
        text: NumberFormat('#,###').format(step.count),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Urbanist',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    countPainter.layout();
    countPainter.paint(
      canvas,
      Offset(
        xCenter + barWidth / 2 + 20,
        yStart + stepHeight / 2 - countPainter.height / 2 - 8,
      ),
    );

    // Percentage (if available)
    if (step.conversionFromPrevious != null) {
      final percentPainter = TextPainter(
        text: TextSpan(
          text: '${step.conversionFromPrevious!.toStringAsFixed(1)}%',
          style: TextStyle(
            color: AppColors.slate.withAlpha(179),
            fontSize: 11,
            fontFamily: 'Urbanist',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      percentPainter.layout();
      percentPainter.paint(
        canvas,
        Offset(
          xCenter + barWidth / 2 + 20,
          yStart + stepHeight / 2 + 8,
        ),
      );
    }
  }

  void _drawConversionConnector(
    Canvas canvas,
    Size size,
    double conversion,
    double xCenter,
    double yStart,
  ) {
    // Draw a small indicator showing drop-off
    final dropOffPaint = Paint()
      ..color = conversion < 50
          ? AppColors.error.withAlpha(128)
          : conversion < 75
              ? Colors.orange.withAlpha(128)
              : Colors.green.withAlpha(128)
      ..style = PaintingStyle.fill;

    final dropOffRect = Rect.fromCenter(
      center: Offset(xCenter, yStart - 5),
      width: 60,
      height: 20,
    );

    canvas.drawRect(dropOffRect, dropOffPaint);

    // Draw conversion percentage in connector
    final conversionPainter = TextPainter(
      text: TextSpan(
        text: '${conversion.toStringAsFixed(0)}%',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Urbanist',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    conversionPainter.layout();
    conversionPainter.paint(
      canvas,
      Offset(
        xCenter - conversionPainter.width / 2,
        yStart - 5 - conversionPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _FunnelPainter oldDelegate) {
    return oldDelegate.funnelData != funnelData;
  }
}

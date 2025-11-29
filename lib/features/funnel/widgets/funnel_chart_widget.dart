import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    if (funnelData.steps.isEmpty) return const SizedBox();

    final maxCount = funnelData.steps.first.count;

    return Column(
      children: [
        // Overall Conversion Rate Card
        _buildOverallConversionCard(),

        const SizedBox(height: 24),

        // Funnel List
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: List.generate(funnelData.steps.length, (index) {
                final step = funnelData.steps[index];
                final nextStep = index < funnelData.steps.length - 1
                    ? funnelData.steps[index + 1]
                    : null;

                return _FunnelStepRow(
                  step: step,
                  nextStep: nextStep,
                  maxCount: maxCount,
                  maxWidth: constraints.maxWidth,
                  isFirst: index == 0,
                  isLast: index == funnelData.steps.length - 1,
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverallConversionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
    );
  }
}

class _FunnelStepRow extends StatelessWidget {
  final FunnelStep step;
  final FunnelStep? nextStep;
  final int maxCount;
  final double maxWidth;
  final bool isFirst;
  final bool isLast;

  const _FunnelStepRow({
    required this.step,
    required this.nextStep,
    required this.maxCount,
    required this.maxWidth,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate width based on count relative to max
    // Cap max width at 70% of available width to leave room for labels
    final widthRatio = maxCount > 0 ? step.count / maxCount : 0.0;
    final barWidth = (maxWidth * 0.7) * widthRatio;

    return Column(
      children: [
        SizedBox(
          height: 60, // Fixed height for each step
          child: Row(
            children: [
              // Left Label (Step Info)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Aligned to start (left)
                    children: [
                      Text(
                        'STEP ${step.stepNumber}',
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 12, // Increased from 10
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14, // Increased from 12
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Urbanist',
                        ),
                        textAlign: TextAlign.left, // Aligned to left
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Center Bar (Rectangle)
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  // Whiter at top (step 1), more transparent as you go down
                  final alpha = (255 * (1 - (step.stepNumber - 1) / maxCount)).toInt().clamp(77, 255);
                  Color barColor = AppColors.white.withAlpha(alpha);
                  return Container(
                    width: barWidth * value,
                    height: 45,
                    decoration: BoxDecoration(color: barColor),
                  );
                },
              ),

              // Right Label (Count)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NumberFormat('#,###').format(step.count),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18, // Increased from 16
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      Text(
                        step.count == 1
                            ? 'USER'
                            : 'USERS', // Fixed pluralization
                        style: TextStyle(
                          color: AppColors.slate.withAlpha(128),
                          fontSize: 12, // Increased from 10
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Connector spacing with Conversion Rate
        if (!isLast &&
            nextStep != null &&
            nextStep!.conversionFromPrevious != null)
          SizedBox(
            height: 36, // Increased height for larger label
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  border: Border.all(
                    color: _getConversionColor(
                      nextStep!.conversionFromPrevious!,
                    ).withAlpha(128),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${nextStep!.conversionFromPrevious!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getConversionColor(
                      nextStep!.conversionFromPrevious!,
                    ),
                    fontSize: 12, // Increased from 10
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
            ),
          )
        else if (!isLast)
          // Fallback if no next step data (shouldn't happen in valid funnel)
          SizedBox(
            height: 20,
            child: Center(
              child: Container(width: 1, color: AppColors.slate.withAlpha(51)),
            ),
          ),
      ],
    );
  }

  Color _getConversionColor(double conversion) {
    if (conversion >= 75) return Colors.green;
    if (conversion >= 50) return Colors.orange;
    return AppColors.error;
  }
}

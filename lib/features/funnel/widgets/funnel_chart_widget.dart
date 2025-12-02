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

        SizedBox(height: isMobile ? 16 : 24),

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
                  isMobile: isMobile,
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
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(26),
        border: Border.all(color: AppColors.white.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            isMobile ? 'CONVERSION RATE' : 'OVERALL CONVERSION RATE',
            style: TextStyle(
              color: AppColors.slate,
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.bold,
              letterSpacing: isMobile ? 1.0 : 2.0,
              fontFamily: 'Urbanist',
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            '${funnelData.overallConversion.toStringAsFixed(1)}%',
            style: TextStyle(
              color: AppColors.white,
              fontSize: isMobile ? 36 : 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'Urbanist',
              letterSpacing: -2,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          if (funnelData.steps.isNotEmpty)
            Text(
              '${NumberFormat('#,###').format(funnelData.steps.last.count)} of ${NumberFormat('#,###').format(funnelData.steps.first.count)} users',
              style: TextStyle(
                color: AppColors.slate.withAlpha(179),
                fontSize: isMobile ? 11 : 13,
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
  final bool isMobile;

  const _FunnelStepRow({
    required this.step,
    required this.nextStep,
    required this.maxCount,
    required this.maxWidth,
    required this.isFirst,
    required this.isLast,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate bar width as percentage of the center area
    final widthRatio = maxCount > 0 ? step.count / maxCount : 0.0;

    return Column(
      children: [
        SizedBox(
          height: isMobile ? 52 : 64,
          child: Row(
            children: [
              // Left Label (Step Info) - Flexible to prevent overflow
              Expanded(
                flex: isMobile ? 2 : 1,
                child: Padding(
                  padding: EdgeInsets.only(right: isMobile ? 8 : 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'STEP ${step.stepNumber}',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: isMobile ? 9 : 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: isMobile ? 0.5 : 1.0,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        step.name,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: isMobile ? 10 : 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Urbanist',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ),

              // Center Bar (Rectangle) - Fixed flex, bar centered inside
              Expanded(
                flex: isMobile ? 3 : 4,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth * widthRatio;
                    // Whiter at top (step 1), more transparent as you go down
                    final alpha = (255 * (1 - (step.stepNumber - 1) / maxCount)).toInt().clamp(77, 255);
                    
                    return Center(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutQuart,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Container(
                            width: barWidth * value,
                            height: isMobile ? 32 : 44,
                            decoration: BoxDecoration(
                              color: AppColors.white.withAlpha(alpha),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // Right Label (Count) - Flexible to prevent overflow
              Expanded(
                flex: isMobile ? 2 : 1,
                child: Padding(
                  padding: EdgeInsets.only(left: isMobile ? 8 : 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NumberFormat('#,###').format(step.count),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: isMobile ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      Text(
                        step.count == 1 ? 'USER' : 'USERS',
                        style: TextStyle(
                          color: AppColors.slate.withAlpha(128),
                          fontSize: isMobile ? 9 : 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: isMobile ? 0.5 : 1.0,
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
            height: isMobile ? 24 : 32,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 10,
                  vertical: isMobile ? 3 : 4,
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
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
            ),
          )
        else if (!isLast)
          SizedBox(
            height: isMobile ? 12 : 16,
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

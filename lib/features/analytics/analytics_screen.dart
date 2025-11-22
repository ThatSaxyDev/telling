import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/military_decorations.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Icon(Icons.analytics, color: AppColors.slate, size: 32),
              const SizedBox(width: 16),
              GlitchText(
                text: 'ANALYTICS',
                style: isMobile
                    ? AppTextStyles.titleMedium
                    : AppTextStyles.headlineSmall,
                glitchAmount: 2.0,
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: MilitaryHoverContainer(
              baseColor: AppColors.surfaceDark,
              hoverColor: AppColors.white,
              showGrid: true,
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bar_chart,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ANALYTICS MODULE',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Charts and visualizations coming in Phase 2',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

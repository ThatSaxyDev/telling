import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/error_formatter.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';
import '../../shared/widgets/app_button.dart';
import 'widgets/funnel_name_selector_widget.dart';
import 'widgets/named_funnel_chart_widget.dart';

class NamedFunnelScreen extends ConsumerWidget {
  const NamedFunnelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFunnelName = ref.watch(selectedFunnelNameProvider);
    final funnelAsync = ref.watch(namedFunnelDataProvider);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Stack(
      children: [
        // Background Effects
        const Positioned.fill(
          child: GridBackground(
            color: Color(0xFF1A1A1A),
            spacing: 40,
            strokeWidth: 0.5,
          ),
        ),
        const Positioned.fill(
          child: Scanline(
            color: Color(0x0DFFFFFF),
            duration: Duration(seconds: 8),
          ),
        ),

        // Main Content
        Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withAlpha(230),
                border: Border(
                  bottom: BorderSide(color: AppColors.slate.withAlpha(77)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_alt,
                        color: AppColors.slate,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: GlitchText(
                          text: 'FUNNELYTICS_2',
                          style: isMobile
                              ? AppTextStyles.titleMedium.copyWith(
                                  fontFamily: 'Syne',
                                )
                              : AppTextStyles.headlineSmall.copyWith(
                                  fontFamily: 'Syne',
                                ),
                          glitchAmount: 2.0,
                        ),
                      ),
                      const Spacer(),
                      AppButton(
                        text: isMobile ? '' : 'REFRESH',
                        icon: Icons.refresh,
                        isOutlined: true,
                       onPressed: () {
                          ref.invalidate(namedFunnelDataProvider);
                          ref.invalidate(availableFunnelNamesProvider);
                        },
                        width: isMobile ? 48 : null,
                        height: isMobile ? 48 : null,
                        padding: isMobile ? EdgeInsets.zero : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Analyze pre-tracked named funnels from your app',
                    style: TextStyle(
                      color: AppColors.slate.withAlpha(204),
                      fontSize: 14,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Funnel Name Selector Section
                    const FunnelNameSelectorWidget(),

                    const SizedBox(height: 32),

                    // Funnel Visualization or Empty State
                    if (selectedFunnelName == null || selectedFunnelName.isEmpty)
                      _buildEmptyState()
                    else
                      _buildFunnelSection(funnelAsync, isMobile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withAlpha(204),
        border: Border.all(color: AppColors.slate.withAlpha(77)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt,
              size: 64,
              color: AppColors.slate.withAlpha(128),
            ),
            const SizedBox(height: 24),
            const Text(
              'NO FUNNEL SELECTED',
              style: TextStyle(
                color: AppColors.slate,
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a funnel above to view its analysis',
              style: TextStyle(
                color: AppColors.slate.withAlpha(179),
                fontSize: 14,
                fontFamily: 'Urbanist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelSection(AsyncValue funnelAsync, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withAlpha(204),
        border: Border.all(color: AppColors.slate.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha(13),
              border: Border(
                bottom: BorderSide(color: AppColors.slate.withAlpha(77)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_down, color: AppColors.white, size: 16),
                const SizedBox(width: 12),
                const Text(
                  'FUNNEL_ANALYSIS',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontFamily: 'Urbanist',
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  color: AppColors.white.withAlpha(128),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: funnelAsync.when(
              loading: () => const SizedBox(
                height: 400,
                child: Center(
                  child: MilitaryLoader(label: 'ANALYZING FUNNEL...'),
                ),
              ),
              error: (err, stack) => SizedBox(
                height: 400,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error.withAlpha(204),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ErrorFormatter.format(err),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (funnelData) {
                if (funnelData == null) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: AppColors.slate.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'NO DATA AVAILABLE',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontFamily: 'Urbanist',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return NamedFunnelChartWidget(
                  funnelData: funnelData,
                  isMobile: isMobile,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

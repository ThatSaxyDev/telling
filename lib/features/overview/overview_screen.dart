import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telling/core/providers/activity_timeline_provider.dart';
import 'package:telling/shared/widgets/app_button.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/providers/log_stats_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/funnel_constants.dart';
import '../../core/utils/error_formatter.dart';
import '../../core/utils/number_formatter.dart';
import '../../core/extensions/responsive_extension.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';
import 'widgets/activity_timeline.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Step 9: Overview Reached - Onboarding Complete! (Onboarding Funnel)
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.onboardingFunnel,
      stepName: FunnelConstants.overviewReached,
      step: 9,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(logStatsProvider);
    final isMobile = context.isMobile;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use width-based breakpoint for better reliability
        final isDesktop = constraints.maxWidth > 1024;
        final screenWidth = constraints.maxWidth;

        // Responsive text style
        final headerStyle = screenWidth > 800
            ? AppTextStyles.headlineSmall
            : screenWidth > 500
            ? AppTextStyles.titleMedium
            : AppTextStyles.titleSmall;

        // Responsive padding
        // Responsive padding
        final horizontalPadding = context.responsive<double>(
          mobile: 12.0,
          tablet: 20.0,
          desktop: 24.0,
        );
        final verticalPadding = isMobile ? 8.0 : 24.0;

        final content = [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.radar,
                      color: AppColors.slate,
                      size: isMobile ? 24 : 32,
                    ),
                    SizedBox(width: isMobile ? 8 : 16),
                    Flexible(
                      child: GlitchText(
                        text: 'COMMAND CENTER',
                        style: headerStyle.copyWith(color: AppColors.white),
                        glitchAmount: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 8 : 16),
              Row(
                children: [
                  AppButton(
                    text: isMobile ? '' : 'REFRESH',
                    icon: Icons.refresh,
                    isOutlined: true,
                    onPressed: () {
                      ref.invalidate(logStatsProvider);
                      ref.invalidate(activityTimelineProvider);
                    },
                    width: isMobile ? 36 : null,
                    height: isMobile ? 36 : null,
                    padding: isMobile ? EdgeInsets.zero : null,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 32),

          // Stats Grid
          statsAsync.when(
            loading: () => Center(
              child: MilitaryLoader(
                label: isMobile ? 'ANALYZING...' : 'ANALYZING SYSTEMS...',
                size: isMobile ? 40 : 60,
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                ErrorFormatter.format(error),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            data: (stats) => _buildStatsGrid(stats, isMobile, screenWidth),
          ),

          SizedBox(height: isMobile ? 16 : 32),

          // Activity Timeline Header
          Text(
            'RECENT ACTIVITY',
            style:
                (isMobile
                        ? AppTextStyles.labelLarge
                        : AppTextStyles.titleMedium)
                    .copyWith(
                      color: AppColors.white,
                      letterSpacing: isMobile ? 1 : 2,
                    ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
        ];

        if (isDesktop) {
          // Desktop: Expandable layout that fills remaining height
          return Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...content,
                const Expanded(child: ActivityTimeline()),
              ],
            ),
          );
        } else {
          // Mobile/Tablet: Scrollable layout with fixed timeline height
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...content,
                // Use remaining space for timeline - calculate based on content above
                SizedBox(
                  height: isMobile ? 520 : 500,
                  child: const ActivityTimeline(),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildStatsGrid(LogStats stats, bool isMobile, double screenWidth) {
    // Determine grid configuration based on screen width
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 800
        ? 4
        : screenWidth > 500
        ? 2
        : 2;

    final spacing = isMobile ? 8.0 : 16.0;

    // Adjust aspect ratio for mobile to make cards taller
    final aspectRatio = isMobile ? 1.6 : 2.0;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: [
        _buildStatCard(
          icon: Icons.list_alt,
          label: 'TOTAL LOGS',
          value: NumberFormatter.format(stats.totalLogs),
          color: AppColors.white,
          isMobile: isMobile,
        ),
        _buildStatCard(
          icon: Icons.error_outline,
          label: 'ERRORS',
          value: NumberFormatter.format(stats.errorCount),
          color: AppColors.error,
          isMobile: isMobile,
        ),
        _buildStatCard(
          icon: Icons.warning_amber,
          label: 'WARNINGS',
          value: NumberFormatter.format(stats.warningCount),
          color: Colors.orange,
          isMobile: isMobile,
        ),
        _buildStatCard(
          icon: Icons.analytics_outlined,
          label: 'EVENTS',
          value: NumberFormatter.format(
            stats.totalLogs - stats.errorCount - stats.warningCount,
          ),
          color: AppColors.white,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on card width
        final isSmall = constraints.maxWidth < 200;
        final isVerySmall = constraints.maxWidth < 150;
        final padding = isVerySmall ? 8.0 : (isSmall ? 10.0 : 20.0);
        final iconSize = isVerySmall ? 18.0 : (isSmall ? 20.0 : 28.0);
        final valueFontSize = isVerySmall ? 18.0 : (isSmall ? 22.0 : 32.0);
        final labelFontSize = isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0);
        final dotSize = isVerySmall ? 5.0 : (isSmall ? 6.0 : 8.0);

        return MilitaryHoverContainer(
          baseColor: AppColors.surfaceDark,
          hoverColor: AppColors.white.withAlpha(204),
          showGrid: !isMobile,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.slate.withAlpha(77)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: iconSize),
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(128),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTextStyles.displaySmall.copyWith(
                            fontSize: valueFontSize,
                            color: color,
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: labelFontSize,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/log_stats_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/number_formatter.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';
import 'widgets/activity_timeline.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(logStatsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use width-based breakpoint for better reliability
        final isDesktop = constraints.maxWidth > 1024;
        final style = constraints.maxWidth > 800
            ? AppTextStyles.headlineSmall
            : AppTextStyles.titleMedium;

        final content = [
          // Header
          Row(
            children: [
              const Icon(Icons.radar, color: AppColors.slate, size: 32),
              const SizedBox(width: 16),
              Flexible(
                child: GlitchText(
                  text: 'COMMAND CENTER',
                  style: style.copyWith(color: AppColors.white),
                  glitchAmount: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Grid
          statsAsync.when(
            loading: () => const Center(
              child: MilitaryLoader(label: 'ANALYZING SYSTEMS...'),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading stats: $error',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            data: (stats) => _buildStatsGrid(stats),
          ),

          const SizedBox(height: 32),

          // Activity Timeline Header
          Text(
            'RECENT ACTIVITY',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
        ];

        if (isDesktop) {
          // Desktop: Expandable layout that fills remaining height
          return Padding(
            padding: const EdgeInsets.all(24),
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth > 800 ? 24.0 : 16.0;
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...content,
                    SizedBox(height: 500, child: const ActivityTimeline()),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildStatsGrid(LogStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        print(constraints.maxWidth);
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 1106
            ? 4
            : 2;

        final padding = constraints.maxWidth > 800 ? 16.0 : 8.0;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: padding,
          crossAxisSpacing: padding,
          childAspectRatio: 2,
          children: [
            _buildStatCard(
              icon: Icons.list_alt,
              label: 'TOTAL LOGS',
              value: NumberFormatter.format(stats.totalLogs),
              color: AppColors.white,
            ),
            _buildStatCard(
              icon: Icons.error_outline,
              label: 'ERRORS',
              value: NumberFormatter.format(stats.errorCount),
              color: AppColors.error,
            ),
            _buildStatCard(
              icon: Icons.warning_amber,
              label: 'WARNINGS',
              value: NumberFormatter.format(stats.warningCount),
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.analytics_outlined,
              label: 'EVENTS',
              value: NumberFormatter.format(
                stats.totalLogs - stats.errorCount - stats.warningCount,
              ),
              color: AppColors.white,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on card width
        final isSmall = constraints.maxWidth < 200;
        final padding = isSmall ? 5.0 : 20.0;
        final iconSize = isSmall ? 20.0 : 28.0;
        final valueFontSize = isSmall ? 20.0 : 32.0;
        final labelFontSize = isSmall ? 10.0 : 12.0;

        return MilitaryHoverContainer(
          baseColor: AppColors.surfaceDark,
          hoverColor: AppColors.white.withOpacity(0.8),
          showGrid: false,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.slate.withOpacity(0.3)),
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
                      width: isSmall ? 6 : 8,
                      height: isSmall ? 6 : 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
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

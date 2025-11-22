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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.radar, color: AppColors.primary, size: 32),
              const SizedBox(width: 16),
              GlitchText(
                text: 'COMMAND CENTER',
                style: AppTextStyles.headlineSmall,
                glitchAmount: 2.0,
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

          // Activity Timeline
          Text(
            'RECENT ACTIVITY',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          const ActivityTimeline(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(LogStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 2
                : 1;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
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
    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      // hoverColor: AppColors.white.withOpacity(0.2),
      showGrid: true,
      child: Container(
        padding: const EdgeInsets.all(20),
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
                Icon(icon, color: color, size: 28),
                Container(
                  width: 8,
                  height: 8,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 32,
                    color: color,
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

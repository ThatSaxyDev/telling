import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telling/core/models/log_level/log_level.dart';
import '../../../core/models/log_model/log_model.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/military_decorations.dart';
import '../../../shared/widgets/military_loader.dart';

class ActivityTimeline extends ConsumerWidget {
  const ActivityTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsProvider);

    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      hoverColor: AppColors.white.withOpacity(0.8),
      showGrid: false,
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withOpacity(0.3)),
        ),
        child: logsAsync.when(
          loading: () => const Center(
            child: MilitaryLoader(label: 'LOADING ACTIVITY...', size: 60),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading activity: $error',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timeline,
                      size: 48,
                      color: AppColors.slate,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NO ACTIVITY DETECTED',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Take only the first 15 logs
            final recentLogs = logs.take(15).toList();

            return ListView.separated(
              itemCount: recentLogs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = recentLogs[index];
                return _buildTimelineItem(log, index == recentLogs.length - 1);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimelineItem(LogModel log, bool isLast) {
    final color = _getLevelColor(log.level);
    final timeStr = _formatTime(log.timestamp);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot and line
        SizedBox(
          width: 24,
          child: Column(
            children: [
              // Dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Vertical line (if not last)
              if (!isLast)
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: AppColors.white.withOpacity(0.1),
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp and Level
              Row(
                children: [
                  Text(
                    timeStr,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      log.level.toString().split('.').last.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (log.userName != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.person, size: 12, color: AppColors.slate),
                    const SizedBox(width: 4),
                    Text(
                      log.userName!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.slate,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Message
              Text(
                log.message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(LogLevel level) {
    return level.when(
      debug: () => AppColors.slate,
      info: () => Colors.blue,
      warning: () => Colors.orange,
      error: () => AppColors.error,
      fatal: () => Colors.red,
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

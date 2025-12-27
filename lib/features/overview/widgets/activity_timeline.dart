import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telling/core/models/log_level/log_level.dart';
import '../../../core/models/log_model/log_model.dart';
import '../../../core/providers/activity_timeline_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/extensions/responsive_extension.dart';
import '../../../shared/widgets/military_decorations.dart';
import '../../../shared/widgets/military_loader.dart';
import '../../../shared/painters/corner_bracket_painter.dart';
import '../../logs/widgets/log_details_dialog.dart';

/// Activity timeline widget - simply watches the provider.
///
/// Data flow:
/// 1. Provider loads initial data (once per project)
/// 2. Provider prepends new logs via Pusher events
/// 3. This widget just displays what's in the provider
class ActivityTimeline extends ConsumerWidget {
  const ActivityTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;
    
    // Watch the provider - rebuilds when data changes (project switch or Pusher event)
    final timelineAsync = ref.watch(activityTimelineProvider);
    
    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      hoverColor: AppColors.slate.withAlpha(128),
      showGrid: !isMobile,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: timelineAsync.when(
          loading: () => Center(
            child: MilitaryLoader(
              label: isMobile ? 'LOADING...' : 'LOADING ACTIVITY...',
              size: isMobile ? 40 : 60,
            ),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error loading activity',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          data: (logs) => _buildContent(context, logs, isMobile),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<LogModel> logs,
    bool isMobile,
  ) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: isMobile ? 36 : 48, color: AppColors.slate),
            SizedBox(height: isMobile ? 8 : 16),
            Text(
              'NO ACTIVITY',
              style: (isMobile ? AppTextStyles.labelLarge : AppTextStyles.titleMedium).copyWith(
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (context, index) => SizedBox(height: isMobile ? 6 : 8),
      itemBuilder: (context, index) {
        final log = logs[index];
        final isLast = index == logs.length - 1;
        return _buildTimelineItem(context, log, isLast, isMobile);
      },
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    LogModel log,
    bool isLast,
    bool isMobile,
  ) {
    final color = _getLevelColor(log.level);
    final typeColor = _getTypeColor(log.type);
    final timeStr = _formatTime(log.timestamp);

    return GestureDetector(
      onTap: () => LogDetailsDialog.show(context, log),
      child: Padding(
        padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot
            SizedBox(
              width: isMobile ? 16 : 20,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: isMobile ? 8 : 10,
                          height: isMobile ? 8 : 10,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: color.withAlpha(128),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: isMobile ? 4 : 6,
                        height: isMobile ? 4 : 6,
                        decoration: BoxDecoration(
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(179),
                              blurRadius: isMobile ? 4 : 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Container(
                      width: 1,
                      height: isMobile ? 40 : 52,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withAlpha(128),
                            AppColors.slate.withAlpha(26),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withAlpha(3),
                      AppColors.backgroundDark.withAlpha(77),
                      AppColors.backgroundDark.withAlpha(38),
                    ],
                  ),
                  border: Border(
                    left: BorderSide(color: color, width: isMobile ? 2 : 3),
                    top: BorderSide(color: color.withAlpha(77), width: 1),
                    right: BorderSide(
                      color: AppColors.slate.withAlpha(51),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: AppColors.slate.withAlpha(51),
                      width: 1,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildLevelBadge(log, color, isMobile),
                              const SizedBox(width: 8),
                              if (log.type != const LogType.general())
                                _buildTypeBadge(log, typeColor, isMobile),
                              const Spacer(),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: AppColors.slate,
                                  fontSize: isMobile ? 9 : 10,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 4 : 6),
                          Text(
                            log.message,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: isMobile ? 11 : 13,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      Positioned(
                        top: 0,
                        left: 0,
                        child: CustomPaint(
                          size: const Size(8, 8),
                          painter: CornerBracketPainter(
                            color: color,
                            isTopLeft: true,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CustomPaint(
                          size: const Size(8, 8),
                          painter: CornerBracketPainter(
                            color: color.withAlpha(77),
                            isTopLeft: false,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(LogModel log, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 6,
        vertical: isMobile ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getLevelIcon(log.level), size: isMobile ? 9 : 11, color: color),
          SizedBox(width: isMobile ? 2 : 3),
          Text(
            log.level.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 8 : 10,
              fontWeight: FontWeight.w900,
              fontFamily: 'Urbanist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(LogModel log, Color typeColor, bool isMobile) {
    final label = log.type.when(
      general: () => 'GEN',
      analytics: () => 'ANA',
      crash: () => 'CRS',
      performance: () => 'PRF',
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 5,
        vertical: isMobile ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: typeColor.withAlpha(26),
        border: Border.all(color: typeColor.withAlpha(128)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: typeColor,
          fontSize: isMobile ? 7 : 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getLevelIcon(LogLevel level) {
    return level.when(
      trace: () => Icons.bug_report,
      debug: () => Icons.bug_report,
      info: () => Icons.info_outline,
      warning: () => Icons.warning_amber,
      error: () => Icons.error_outline,
      fatal: () => Icons.dangerous,
    );
  }

  Color _getTypeColor(LogType type) {
    return type.when(
      general: () => AppColors.slate,
      analytics: () => Colors.purple,
      crash: () => Colors.red.shade900,
      performance: () => Colors.amber,
    );
  }

  Color _getLevelColor(LogLevel level) {
    return level.when(
      trace: () => AppColors.slate.withAlpha(179),
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
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

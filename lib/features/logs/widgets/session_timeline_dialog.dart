import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/log_model/log_model.dart';
import '../../../../core/providers/logs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error_formatter.dart';
import '../../../../shared/widgets/military_decorations.dart';
import '../../../../shared/widgets/military_loader.dart';

class SessionTimelineDialog extends ConsumerWidget {
  final String sessionId;
  final String? userName;
  final int eventCount;
  final Duration duration;

  const SessionTimelineDialog({
    super.key,
    required this.sessionId,
    this.userName,
    required this.eventCount,
    required this.duration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(sessionLogsProvider(sessionId));

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 800),
        child: MilitaryHoverContainer(
          baseColor: AppColors.surfaceDark,
          hoverColor: AppColors.white,
          showGrid: true,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              color: AppColors.backgroundDark.withAlpha(242),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 10,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlitchText(
                            text: 'SESSION DEEP DIVE',
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildBadge(
                                Icons.person,
                                userName ?? 'Unknown User',
                              ),
                              const SizedBox(width: 12),
                              _buildBadge(
                                Icons.timer,
                                '${duration.inMinutes}m ${duration.inSeconds % 60}s',
                              ),
                              const SizedBox(width: 12),
                              _buildBadge(Icons.list, '$eventCount EVENTS'),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Timeline Content
                Expanded(
                  child: logsAsync.when(
                    loading: () => const Center(
                      child: MilitaryLoader(
                        label: 'RECONSTRUCTING TIMELINE...',
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        ErrorFormatter.format(err),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    data: (logs) {
                      if (logs.isEmpty) {
                        return const Center(
                          child: Text(
                            'NO DATA FOUND',
                            style: TextStyle(color: AppColors.slate),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(32),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isLast = index == logs.length - 1;
                          final nextLog = isLast ? null : logs[index + 1];

                          // Calculate time gap
                          Duration? timeGap;
                          if (nextLog != null) {
                            timeGap = nextLog.timestamp.difference(
                              log.timestamp,
                            );
                          }

                          return _TimelineNode(
                            log: log,
                            isLast: isLast,
                            timeGap: timeGap,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final LogModel log;
  final bool isLast;
  final Duration? timeGap;

  const _TimelineNode({required this.log, required this.isLast, this.timeGap});

  Color _getLevelColor() {
    switch (log.level.toString().split('.').last.toUpperCase()) {
      case 'FATAL()':
        return Colors.red.shade900;
      case 'ERROR()':
        return AppColors.error;
      case 'WARNING()':
        return Colors.orange;
      case 'INFO()':
        return AppColors.white;
      case 'DEBUG()':
        return AppColors.primary;
      case 'TRACE()':
        return AppColors.slate;
      default:
        return AppColors.slate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor();
    final dateFormat = DateFormat('HH:mm:ss.SSS');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 80,
            child: Text(
              dateFormat.format(log.timestamp),
              style: const TextStyle(
                fontFamily: 'Urbanist',
                color: AppColors.slate,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),

          // Line & Node Column
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(128),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.slate.withAlpha(77),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          log.level.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (log.type.toString().contains('screen'))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(26),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'SCREEN VIEW',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.message,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (timeGap != null && timeGap!.inMinutes >= 1) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate.withAlpha(26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.slate.withAlpha(51),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timelapse,
                            size: 12,
                            color: AppColors.slate,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${timeGap!.inMinutes} min idle',
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

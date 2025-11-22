import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telling/core/models/log_level/log_level.dart';
import '../../../core/models/log_model/log_model.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/repositories/logs_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/military_decorations.dart';
import '../../../shared/widgets/military_loader.dart';

class ActivityTimeline extends ConsumerStatefulWidget {
  const ActivityTimeline({super.key});

  @override
  ConsumerState<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends ConsumerState<ActivityTimeline> {
  LogLevel? _filterLevel;
  LogType? _filterType;

  List<LogModel> _filterLogs(List<LogModel> logs) {
    return logs.where((log) {
      // Level filter
      if (_filterLevel != null && log.level != _filterLevel) {
        return false;
      }

      // Type filter
      if (_filterType != null && log.type != _filterType) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            // Compact Filter Bar
            _buildCompactFilterBar(),
            const SizedBox(height: 16),

            // Timeline Content
            Expanded(
              child: logsAsync.when(
                loading: () => const Center(
                  child: MilitaryLoader(label: 'LOADING ACTIVITY...', size: 60),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading activity: $error',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                data: (logs) {
                  final filteredLogs = _filterLogs(logs);

                  if (filteredLogs.isEmpty) {
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
                            logs.isEmpty
                                ? 'NO ACTIVITY DETECTED'
                                : 'NO MATCHING ACTIVITY',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Take only the first 15 filtered logs
                  final recentLogs = filteredLogs.take(15).toList();

                  return ListView.separated(
                    itemCount: recentLogs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = recentLogs[index];
                      return _buildTimelineItem(
                        log,
                        index == recentLogs.length - 1,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFilterBar() {
    return Row(
      children: [
        // Level filter
        _buildCompactDropdown<LogLevel>(
          value: _filterLevel,
          hint: 'ALL LEVELS',
          items: const [
            LogLevel.debug(),
            LogLevel.info(),
            LogLevel.warning(),
            LogLevel.error(),
            LogLevel.fatal(),
          ],
          onChanged: (level) => setState(() => _filterLevel = level),
          itemLabel: (level) => level.toString().split('.').last.toUpperCase(),
        ),

        const SizedBox(width: 12),

        // Type filter
        _buildCompactDropdown<LogType>(
          value: _filterType,
          hint: 'TYPE',
          items: const [
            LogType.log(),
            LogType.errorr(),
            LogType.analytics(),
            LogType.event(),
            LogType.performance(),
            LogType.network(),
          ],
          onChanged: (type) => setState(() => _filterType = type),
          itemLabel: (type) => type.when(
            log: () => 'LOG',
            errorr: () => 'ERROR',
            analytics: () => 'ANALYTICS',
            event: () => 'EVENT',
            performance: () => 'PERFORMANCE',
            network: () => 'NETWORK',
            custom: (name) => name.toUpperCase(),
          ),
        ),

        // Clear filters
        if (_filterLevel != null || _filterType != null) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _filterLevel = null;
                _filterType = null;
              });
            },
            icon: const Icon(Icons.clear, size: 18, color: AppColors.error),
            tooltip: 'Clear Filters',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border.all(color: AppColors.slate.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.slate),
          ),
          isDense: true,
          dropdownColor: AppColors.surfaceDark,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.secondary,
            size: 18,
          ),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(
                hint,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                ),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
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

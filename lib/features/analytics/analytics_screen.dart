import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:telling/shared/widgets/app_button.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../core/models/analytics_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/military_decorations.dart';
import '../../../shared/widgets/military_loader.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeRange = ref.watch(analyticsTimeRangeProvider);
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final timelineAsync = ref.watch(logsTimelineProvider);
    final levelsAsync = ref.watch(logLevelsProvider);
    final errorsAsync = ref.watch(topErrorsProvider);
    final usersAsync = ref.watch(activeUsersProvider);

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
            // Header with Time Range Selector
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
                        Icons.analytics,
                        color: AppColors.slate,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: GlitchText(
                          text: 'ANALYTICS_MODULE',
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
                          ref.invalidate(analyticsSummaryProvider);
                          ref.invalidate(logsTimelineProvider);
                          ref.invalidate(logLevelsProvider);
                          ref.invalidate(topErrorsProvider);
                          ref.invalidate(activeUsersProvider);
                        },
                        width: isMobile ? 48 : null,
                        height: isMobile ? 48 : null,
                        padding: isMobile ? EdgeInsets.zero : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time Range Tabs
                  Row(
                    children: [
                      _TimeRangeTab(
                        label: '24H',
                        hours: 24,
                        isSelected: timeRange == 24,
                        onTap: () => ref
                            .read(analyticsTimeRangeProvider.notifier)
                            .set(24),
                      ),
                      const SizedBox(width: 12),
                      _TimeRangeTab(
                        label: '07D',
                        hours: 168,
                        isSelected: timeRange == 168,
                        onTap: () => ref
                            .read(analyticsTimeRangeProvider.notifier)
                            .set(168),
                      ),
                      const SizedBox(width: 12),
                      _TimeRangeTab(
                        label: '30D',
                        hours: 720,
                        isSelected: timeRange == 720,
                        onTap: () => ref
                            .read(analyticsTimeRangeProvider.notifier)
                            .set(720),
                      ),
                    ],
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
                    // Key Metrics Grid
                    summaryAsync.when(
                      loading: () => const Center(
                        child: MilitaryLoader(label: 'ANALYZING DATA...'),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (summary) => GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 2 : 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: isMobile ? 1.2 : 1.5,
                        children: [
                          _MetricCard(
                            icon: Icons.description,
                            label: 'TOTAL_LOGS',
                            value: summary.totalLogs.toString(),
                            trend: summary.logsTrend,
                            code: 'LOG-01',
                          ),
                          _MetricCard(
                            icon: Icons.error_outline,
                            label: 'ERROR_RATE',
                            value: '${summary.errorRate.toStringAsFixed(1)}%',
                            isError: summary.errorRate > 5,
                            code: 'ERR-02',
                          ),
                          _MetricCard(
                            icon: Icons.timer,
                            label: 'ACTV_SESS',
                            value: summary.activeSessions.toString(),
                            code: 'SES-03',
                          ),
                          _MetricCard(
                            icon: Icons.people,
                            label: 'ACTV_USRS',
                            value: summary.activeUsers.toString(),
                            code: 'USR-04',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Charts Row
                    isMobile
                        ? Column(
                            children: [
                              _buildLogsTimelineSection(timelineAsync),
                              const SizedBox(height: 24),
                              _buildLogLevelsSection(levelsAsync),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildLogsTimelineSection(timelineAsync),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildLogLevelsSection(levelsAsync),
                              ),
                            ],
                          ),

                    const SizedBox(height: 32),

                    // Insights Row
                    isMobile
                        ? Column(
                            children: [
                              _buildTopErrorsSection(errorsAsync),
                              const SizedBox(height: 24),
                              _buildActiveUsersSection(usersAsync),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTopErrorsSection(errorsAsync),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildActiveUsersSection(usersAsync),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogsTimelineSection(AsyncValue timelineAsync) {
    return _SectionCard(
      title: 'LOGS_TIMELINE_VISUALIZATION',
      icon: Icons.show_chart,
      child: timelineAsync.when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (timeline) => _LogsTimelineChart(data: timeline),
      ),
    );
  }

  Widget _buildLogLevelsSection(AsyncValue levelsAsync) {
    return _SectionCard(
      title: 'LOG_LEVEL_DISTRIBUTION',
      icon: Icons.pie_chart,
      child: levelsAsync.when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (levels) => _LogLevelChart(data: levels),
      ),
    );
  }

  Widget _buildTopErrorsSection(AsyncValue errorsAsync) {
    return _SectionCard(
      title: 'CRITICAL_ERRORS_REPORT',
      icon: Icons.bug_report,
      child: errorsAsync.when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (errors) => _TopErrorsList(errors: errors),
      ),
    );
  }

  Widget _buildActiveUsersSection(AsyncValue usersAsync) {
    return _SectionCard(
      title: 'USER_ACTIVITY_TRACKING',
      icon: Icons.leaderboard,
      child: usersAsync.when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (users) => _ActiveUsersList(users: users),
      ),
    );
  }
}

// Time Range Tab Widget
class _TimeRangeTab extends StatelessWidget {
  final String label;
  final int hours;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeRangeTab({
    required this.label,
    required this.hours,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.white : AppColors.slate.withAlpha(77),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: isSelected ? AppColors.primary : AppColors.slate,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// Metric Card with Corner Brackets
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int? trend;
  final bool isError;
  final String code;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
    this.isError = false,
    this.code = 'DAT-00',
  });

  @override
  Widget build(BuildContext context) {
    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      hoverColor: isError ? AppColors.error : AppColors.white,
      showGrid: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withAlpha(204),
          border: Border.all(
            color: isError
                ? AppColors.error.withAlpha(77)
                : AppColors.slate.withAlpha(77),
          ),
        ),
        child: Stack(
          children: [
            // Technical Code
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                code,
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 10,
                  color: AppColors.slate.withAlpha(128),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      icon,
                      color: isError ? AppColors.error : AppColors.white,
                      size: 24,
                    ),
                    if (trend != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (trend! > 0 ? Colors.green : Colors.red)
                              .withAlpha(26),
                          border: Border.all(
                            color: (trend! > 0 ? Colors.green : Colors.red)
                                .withAlpha(77),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              trend! > 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: trend! > 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trend!.abs()}%',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 11,
                                color: trend! > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isError ? AppColors.error : AppColors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
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

// Section Card Container
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(icon, color: AppColors.white, size: 16),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
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
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

// Logs Timeline Chart - Enhanced with stacked bars by log level
class _LogsTimelineChart extends StatefulWidget {
  final List<LogTimelinePoint> data;

  const _LogsTimelineChart({required this.data});

  @override
  State<_LogsTimelineChart> createState() => _LogsTimelineChartState();
}

class _LogsTimelineChartState extends State<_LogsTimelineChart> {
  final Set<String> _hiddenLevels = {};

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'fatal':
        return Colors.red.shade900;
      case 'error':
        return AppColors.error;
      case 'warning':
        return Colors.orange;
      case 'info':
        return AppColors.white;
      case 'debug':
        return AppColors.slate;
      case 'trace':
        return AppColors.slate.withAlpha(179);
      case 'total': // Backend returns single count without level breakdown
        return AppColors.white;
      default:
        return AppColors.slate;
    }
  }

  List<String> _getLogLevels() {
    final levels = <String>{};
    for (final point in widget.data) {
      levels.addAll(point.counts.keys);
    }
    // Order by severity
    final ordered = ['fatal', 'error', 'warning', 'info', 'debug', 'trace'];
    return ordered.where((l) => levels.contains(l)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 48,
                color: AppColors.slate.withAlpha(128),
              ),
              const SizedBox(height: 16),
              const Text(
                'NO TIMELINE DATA',
                style: TextStyle(
                  color: AppColors.slate,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No logs found for selected time range',
                style: TextStyle(
                  color: AppColors.slate.withAlpha(179),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final levels = _getLogLevels();

    // Debug: Check if we have any data at all
    final hasAnyData = widget.data.any((point) => point.total > 0);

    if (!hasAnyData) {
      return SizedBox(
        height: 300,
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
                'ALL COUNTS ARE ZERO',
                style: TextStyle(
                  color: AppColors.slate,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Timeline data exists but contains no logs',
                style: TextStyle(
                  color: AppColors.slate.withAlpha(179),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxValue = widget.data
        .map((e) => e.total)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: [
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: levels.map((level) {
            final isHidden = _hiddenLevels.contains(level);
            final color = _getLevelColor(level);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isHidden) {
                    _hiddenLevels.remove(level);
                  } else {
                    _hiddenLevels.add(level);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHidden ? Colors.transparent : color.withAlpha(26),
                  border: Border.all(
                    color: isHidden ? AppColors.slate.withAlpha(77) : color,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      color: isHidden ? AppColors.slate.withAlpha(77) : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      level.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Urbanist',
                        color: isHidden ? AppColors.slate : color,
                        fontWeight: FontWeight.bold,
                        decoration: isHidden
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 280,
          child: Stack(
            children: [
              // Grid Lines with labels
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  children: [
                    // Y-axis labels
                    SizedBox(
                      width: 35,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(6, (index) {
                          final value = (maxValue * (5 - index) / 5).toInt();
                          return Text(
                            value.toString(),
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 9,
                              fontFamily: 'Urbanist',
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Grid
                    Expanded(
                      child: Column(
                        children: List.generate(6, (index) {
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.slate.withAlpha(26),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // Stacked Bars
              Padding(
                padding: const EdgeInsets.only(left: 43, bottom: 30),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.data.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final point = widget.data[index];
                    return _buildStackedBar(point, maxValue, levels);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStackedBar(
    LogTimelinePoint point,
    double maxValue,
    List<String> levels,
  ) {
    final visibleLevels = levels
        .where((l) => !_hiddenLevels.contains(l))
        .toList();

    // Calculate total to show even if all levels are hidden
    final totalCount = point.total;

    // Build segments from bottom to top
    final segments = <Widget>[];

    for (final level in visibleLevels.reversed) {
      final count = point.counts[level] ?? 0;
      if (count > 0) {
        final height = maxValue > 0 ? (count / maxValue * 250) : 0.0;
        // Ensure minimum height for visibility
        final actualHeight = height < 2 && count > 0 ? 2.0 : height;

        segments.add(
          Container(
            width: 24,
            height: actualHeight,
            color: _getLevelColor(level),
          ),
        );
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Show placeholder if no segments but has data
        if (segments.isEmpty && totalCount > 0)
          Container(
            width: 24, height: 2, color: AppColors.slate.withAlpha(77))
        else if (segments.isNotEmpty)
          ...segments,
        const SizedBox(height: 8),
        SizedBox(
          width: 40,
          child: Text(
            _formatTimestamp(point.timestamp),
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 9,
              fontFamily: 'Urbanist',
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    // Format based on time range - you could pass timeRange as parameter
    return DateFormat('HH:mm').format(timestamp);
  }
}

// Log Level Chart - Enhanced with percentages and clickable filtering
class _LogLevelChart extends ConsumerWidget {
  final List<LogLevelStat> data;

  const _LogLevelChart({required this.data});

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'fatal':
        return Colors.red.shade900;
      case 'error':
        return AppColors.error;
      case 'warning':
        return Colors.orange;
      case 'info':
        return AppColors.white;
      case 'debug':
        return AppColors.slate;
      case 'trace':
        return AppColors.slate.withAlpha(179);
      default:
        return AppColors.slate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'NO_DATA_AVAILABLE',
            style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
          ),
        ),
      );
    }

    final maxValue = data
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    
    final totalCount = data.fold<int>(0, (sum, stat) => sum + stat.count);

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          // Total Counter
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha(13),
              border: Border.all(color: AppColors.slate.withAlpha(77)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL LOGS',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 11,
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  totalCount.toString().padLeft(4, '0'),
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Level Bars
          Expanded(
            child: ListView.separated(
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final stat = data[index];
                final percentage = totalCount > 0
                    ? (stat.count / totalCount)
                    : 0.0;
                final barPercentage = maxValue > 0
                    ? (stat.count / maxValue)
                    : 0.0;
                final color = _getLevelColor(stat.level);

                return GestureDetector(
                  onTap: () {
                    // Navigate to logs explorer filtered by this level
                    context.go('/logs?level=${stat.level}');
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            stat.level.toUpperCase().substring(0, 3),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              // Background track with ticks
                              Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color.withAlpha(26),
                                  border: Border.all(
                                    color: color.withAlpha(51),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    10,
                                    (i) => Container(
                                      width: 1,
                                      color: color.withAlpha(51),
                                    ),
                                  ),
                                ),
                              ),
                              // Fill
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: barPercentage,
                                child: Container(
                                  height: 24,
                                  color: color.withAlpha(204),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    '${(percentage * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontFamily: 'Urbanist',
                                      color: barPercentage > 0.15
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 70,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                stat.count.toString().padLeft(4, '0'),
                                style: const TextStyle(
                                  fontFamily: 'Urbanist',
                                  color: AppColors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.slate.withAlpha(128),
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Top Errors List - Enhanced with clickable navigation and visual indicators
class _TopErrorsList extends ConsumerWidget {
  final List<TopErrorItem> errors;

  const _TopErrorsList({required this.errors});

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Color _getSeverityColor(int count) {
    if (count > 100) return Colors.red.shade900;
    if (count > 50) return AppColors.error;
    if (count > 10) return Colors.orange;
    return AppColors.slate;
  }

  void _showErrorDetails(BuildContext context, TopErrorItem error) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 600),
          child: MilitaryHoverContainer(
            baseColor: AppColors.surfaceDark,
            hoverColor: AppColors.error,
            showGrid: true,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.error),
                color: AppColors.backgroundDark.withAlpha(242),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.error),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GlitchText(
                            text: 'ERROR DETAILS',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.white),
                          onPressed: () => Navigator.pop(context),
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
                          // Error Message
                          _buildDetailSection('ERROR MESSAGE', error.message),

                          // Occurrence Count
                          _buildDetailSection(
                            'OCCURRENCES',
                            '${error.count} times',
                          ),

                          // Last Seen
                          _buildDetailSection(
                            'LAST SEEN',
                            DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format(error.lastSeen),
                          ),

                          // Relative Time
                          _buildDetailSection(
                            'RECENCY',
                            _getRelativeTime(error.lastSeen),
                          ),

                          const SizedBox(height: 24),

                          // Action Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(26),
                              border: Border.all(
                                color: AppColors.error.withAlpha(77),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppColors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'INVESTIGATION REQUIRED',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                        fontFamily: 'Urbanist',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'View related logs in Logs Explorer to investigate this error.',
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppButton(
                                  text: 'VIEW IN LOGS EXPLORER',
                                  icon: Icons.search,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.go(
                                      '/logs?search=${Uri.encodeComponent(error.message)}',
                                    );
                                  },
                                  isOutlined: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withAlpha(128),
              border: Border.all(color: AppColors.slate.withAlpha(77)),
            ),
            child: Text(
              content,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontFamily: 'Urbanist',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (errors.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'SYSTEM_OPTIMAL',
                style: TextStyle(color: Colors.green, fontFamily: 'Urbanist'),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.separated(
        itemCount: errors.length,
        separatorBuilder: (_, __) =>
            Divider(color: AppColors.slate.withAlpha(51)),
        itemBuilder: (context, index) {
          final error = errors[index];
          final severityColor = _getSeverityColor(error.count);
          final isHighSeverity = error.count > 50;

          return GestureDetector(
            onTap: () {
              _showErrorDetails(context, error);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: severityColor,
                      width: isHighSeverity ? 3 : 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rank badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: severityColor.withAlpha(26),
                          border: Border.all(color: severityColor),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'Urbanist',
                              color: severityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              error.message,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontFamily: 'Urbanist',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 10,
                                  color: AppColors.slate,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getRelativeTime(error.lastSeen),
                                  style: const TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 10,
                                    fontFamily: 'Urbanist',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  isHighSeverity
                                      ? Icons.warning
                                      : Icons.info_outline,
                                  size: 10,
                                  color: severityColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isHighSeverity ? 'CRITICAL' : 'ACTIVE',
                                  style: TextStyle(
                                    color: severityColor,
                                    fontSize: 10,
                                    fontFamily: 'Urbanist',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: severityColor.withAlpha(26),
                              border: Border.all(
                                color: severityColor.withAlpha(128),
                              ),
                            ),
                            child: Text(
                              'x${error.count}',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                color: severityColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.slate.withAlpha(128),
                            size: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Active Users List - Enhanced with email, timestamps, and activity indicators
class _ActiveUsersList extends ConsumerWidget {
  final List<ActiveUserStat> users;

  const _ActiveUsersList({required this.users});

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  bool _isRecentlyActive(DateTime lastActive) {
    return DateTime.now().difference(lastActive).inHours < 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (users.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'NO_ACTIVE_SIGNALS',
            style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.separated(
        itemCount: users.length,
        separatorBuilder: (_, __) =>
            Divider(color: AppColors.slate.withAlpha(51)),
        itemBuilder: (context, index) {
          final user = users[index];
          final isRecent = _isRecentlyActive(user.lastActive);
          
          return GestureDetector(
            onTap: () => context.go('/users/${user.userId}'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Rank Badge with activity pulse
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isRecent)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(51),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(26),
                            borderRadius: BorderRadius.circular(16),
                            border: isRecent
                                ? Border.all(
                                    color: AppColors.secondary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: isRecent ? 13 : 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User name or ID
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.userName ?? user.userId,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isRecent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(26),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 8,
                                      fontFamily: 'Urbanist',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Email or User ID
                          if (user.userEmail != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 10,
                                  color: AppColors.slate,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    user.userEmail!,
                                    style: const TextStyle(
                                      color: AppColors.slate,
                                      fontSize: 10,
                                      fontFamily: 'Urbanist',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                          ],
                          // Last active time
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 10,
                                color: AppColors.slate,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getRelativeTime(user.lastActive),
                                style: TextStyle(
                                  color: isRecent
                                      ? Colors.green
                                      : AppColors.slate,
                                  fontSize: 10,
                                  fontFamily: 'Urbanist',
                                  fontWeight: isRecent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Log count badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 12,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.logCount}',
                                style: const TextStyle(
                                  fontFamily: 'Urbanist',
                                  color: AppColors.secondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.slate.withAlpha(128),
                          size: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

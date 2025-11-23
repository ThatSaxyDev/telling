import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
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
                color: AppColors.surfaceDark.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(color: AppColors.slate.withOpacity(0.3)),
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
                          text: 'ANALYTICS_MODULE // v2.0',
                          style: isMobile
                              ? AppTextStyles.titleMedium.copyWith(
                                  fontFamily: 'Urbanist',
                                  letterSpacing: 2,
                                )
                              : AppTextStyles.headlineSmall.copyWith(
                                  fontFamily: 'Urbanist',
                                  letterSpacing: 4,
                                ),
                          glitchAmount: 2.0,
                        ),
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
                        onTap: () =>
                            ref
                                    .read(analyticsTimeRangeProvider.notifier)
                                    .state =
                                24,
                      ),
                      const SizedBox(width: 12),
                      _TimeRangeTab(
                        label: '07D',
                        hours: 168,
                        isSelected: timeRange == 168,
                        onTap: () =>
                            ref
                                    .read(analyticsTimeRangeProvider.notifier)
                                    .state =
                                168,
                      ),
                      const SizedBox(width: 12),
                      _TimeRangeTab(
                        label: '30D',
                        hours: 720,
                        isSelected: timeRange == 720,
                        onTap: () =>
                            ref
                                    .read(analyticsTimeRangeProvider.notifier)
                                    .state =
                                720,
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
            color: isSelected
                ? AppColors.white
                : AppColors.slate.withOpacity(0.3),
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
          color: AppColors.surfaceDark.withOpacity(0.8),
          border: Border.all(
            color: isError
                ? AppColors.error.withOpacity(0.3)
                : AppColors.slate.withOpacity(0.3),
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
                  color: AppColors.slate.withOpacity(0.5),
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
                              .withOpacity(0.1),
                          border: Border.all(
                            color: (trend! > 0 ? Colors.green : Colors.red)
                                .withOpacity(0.3),
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
        color: AppColors.surfaceDark.withOpacity(0.8),
        border: Border.all(color: AppColors.slate.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: AppColors.slate.withOpacity(0.3)),
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
                  color: AppColors.white.withOpacity(0.5),
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

// Logs Timeline Chart (simplified bar visualization)
class _LogsTimelineChart extends StatelessWidget {
  final List<LogTimelinePoint> data;

  const _LogsTimelineChart({required this.data});

  @override
  Widget build(BuildContext context) {
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
        .map((e) => e.total)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Grid Lines
          Column(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.slate.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Bars
          ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final point = data[index];
              final height = maxValue > 0
                  ? (point.total / maxValue * 250)
                  : 0.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 20,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.white.withOpacity(0.1),
                          AppColors.white,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      DateFormat('HH:mm').format(point.timestamp),
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 10,
                        fontFamily: 'Urbanist',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Log Level Chart (bar chart)
class _LogLevelChart extends StatelessWidget {
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
        return AppColors.darkSlate;
      default:
        return AppColors.slate;
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return SizedBox(
      height: 300,
      child: ListView.separated(
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final stat = data[index];
          final percentage = maxValue > 0 ? (stat.count / maxValue) : 0.0;
          final color = _getLevelColor(stat.level);

          return Row(
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
                        color: color.withOpacity(0.1),
                        border: Border.all(
                          color: color.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          10,
                          (i) => Container(
                            width: 1,
                            color: color.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        height: 24,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text(
                  stat.count.toString().padLeft(4, '0'),
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Top Errors List
class _TopErrorsList extends StatelessWidget {
  final List<TopErrorItem> errors;

  const _TopErrorsList({required this.errors});

  @override
  Widget build(BuildContext context) {
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
            Divider(color: AppColors.slate.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final error = errors[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[${(index + 1).toString().padLeft(2, '0')}]',
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 4),
                      Text(
                        'LAST_SEEN: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(error.lastSeen)}',
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 10,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.error.withOpacity(0.5)),
                  ),
                  child: Text(
                    'x${error.count}',
                    style: const TextStyle(
                      fontFamily: 'Urbanist',
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Active Users List
class _ActiveUsersList extends ConsumerWidget {
  final List<ActiveUserStat> users;

  const _ActiveUsersList({required this.users});

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
            Divider(color: AppColors.slate.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final user = users[index];
          return GestureDetector(
            onTap: () => context.go('/users/${user.userId}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
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
                          user.userName ?? user.userId,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.userId,
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 11,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${user.logCount}',
                      style: const TextStyle(
                        fontFamily: 'Urbanist',
                        color: AppColors.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

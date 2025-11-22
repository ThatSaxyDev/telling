import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/users_provider.dart';
import '../../core/models/user.dart';
import '../../core/models/log_entry.dart';
import '../../core/theme/app_colors.dart';

class UserDetailsScreen extends ConsumerWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider(userId));
    final sessionsAsync = ref.watch(userSessionsProvider(userId));
    final logsAsync = ref.watch(userLogsProvider(userId));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Treat tablet (< 1100px) as small for grid purposes to ensure cards have space
        final isSmallScreen = constraints.maxWidth < 1100;
        final isMobile = constraints.maxWidth < 600;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/users'),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'USER PROFILE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.slate,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        userId,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Stats Grid - Use 2 columns for tablet/mobile, 4 for desktop
              statsAsync.when(
                data: (stats) => _buildStatsGrid(context, stats, isSmallScreen),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading stats: $err'),
              ),
              
              const SizedBox(height: 32),

              // Split View vs Tabs
              Expanded(
                child: isSmallScreen
                    ? DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.3))),
                              ),
                              child: TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                indicatorColor: AppColors.primary,
                                labelColor: AppColors.white,
                                unselectedLabelColor: AppColors.slate.withOpacity(0.6),
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                tabs: const [
                                  Tab(text: 'SESSION HISTORY'),
                                  Tab(text: 'RECENT ACTIVITY'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildSessionsList(context, sessionsAsync),
                                  _buildLogsList(context, logsAsync),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sessions List
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(context, 'SESSION HISTORY'),
                                const SizedBox(height: 16),
                                Expanded(child: _buildSessionsList(context, sessionsAsync)),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 24),
                          
                          // Recent Logs
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(context, 'RECENT ACTIVITY'),
                                const SizedBox(height: 16),
                                Expanded(child: _buildLogsList(context, logsAsync)),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionsList(BuildContext context, AsyncValue<List<UserSession>> sessionsAsync) {
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(child: Text('No sessions recorded', style: TextStyle(color: AppColors.slate)));
        }
        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) => _SessionCard(session: sessions[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err', style: const TextStyle(color: AppColors.error)),
    );
  }

  Widget _buildLogsList(BuildContext context, AsyncValue<List<LogEntry>> logsAsync) {
    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No logs recorded', style: TextStyle(color: AppColors.slate)));
        }
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) => _LogItem(log: logs[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err', style: const TextStyle(color: AppColors.error)),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, UserStats stats, bool isSmallScreen) {
    return GridView.count(
      crossAxisCount: isSmallScreen ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      childAspectRatio: isSmallScreen ? 2.0 : 2.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: 'TOTAL LOGS',
          value: stats.totalLogs.toString(),
          icon: Icons.list_alt,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'SESSIONS',
          value: stats.sessionCount.toString(),
          icon: Icons.timer,
          color: AppColors.secondary,
        ),
        _StatCard(
          label: 'ERRORS',
          value: stats.errorCount.toString(),
          icon: Icons.warning_amber,
          color: AppColors.error,
        ),
        _StatCard(
          label: 'LAST ACTIVE',
          value: DateFormat('MMM d, HH:mm').format(stats.lastActive),
          icon: Icons.access_time,
          color: AppColors.slate,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.slate,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final UserSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, HH:mm:ss');
    final duration = Duration(seconds: session.durationSeconds);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(left: BorderSide(color: AppColors.secondary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(session.startTime),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${duration.inMinutes}m ${duration.inSeconds % 60}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${session.eventCount} events logged',
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${session.sessionId}',
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final LogEntry log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm:ss.SSS');
    
    Color levelColor;
    switch (log.level.toLowerCase()) {
      case 'error':
      case 'fatal':
        levelColor = AppColors.error;
        break;
      case 'warning':
        levelColor = AppColors.warning;
        break;
      default:
        levelColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: AppColors.slate.withOpacity(0.1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(log.timestamp),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              log.level.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: levelColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              log.message,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

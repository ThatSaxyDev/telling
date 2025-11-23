import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/users_provider.dart';
import '../../core/models/user.dart';

import '../../core/theme/app_colors.dart';
import 'widgets/paginated_sessions_list.dart';
import 'widgets/paginated_logs_list.dart';

class UserDetailsScreen extends ConsumerWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final statsAsync = ref.watch(userStatsProvider(userId));
    // final sessionsAsync = ref.watch(userSessionsProvider(userId));
    // final logsAsync = ref.watch(userLogsProvider(userId));

    // Find the current user from the users list to get the userName
    final currentUser = usersAsync.when(
      data: (users) => users.firstWhere(
        (u) => u.userId == userId,
        orElse: () => User(userId: userId, lastSeen: DateTime.now()),
      ),
      loading: () => null,
      error: (_, __) => null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Treat tablet (< 1100px) as small for grid purposes to ensure cards have space
        final isSmallScreen = constraints.maxWidth < 1100;

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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.secondary,
                    ),
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Urbanist',
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
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              child: TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                indicatorColor: AppColors.primary,
                                labelColor: AppColors.white,
                                unselectedLabelColor: AppColors.slate
                                    .withOpacity(0.6),
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
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
                                  PaginatedSessionsList(
                                    userId: userId,
                                    userName: currentUser?.userName,
                                  ),
                                  PaginatedLogsList(userId: userId),
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
                                Expanded(
                                  child: PaginatedSessionsList(
                                    userId: userId,
                                    userName: currentUser?.userName,
                                  ),
                                ),
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
                                Expanded(
                                  child: PaginatedLogsList(userId: userId),
                                ),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: AppColors.primary),
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

  Widget _buildStatsGrid(
    BuildContext context,
    UserStats stats,
    bool isSmallScreen,
  ) {
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
          color: AppColors.secondary,
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
                    fontFamily: 'Urbanist',
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

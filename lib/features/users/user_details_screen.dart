import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/users_provider.dart';
import '../../core/providers/user_properties_provider.dart';
import '../../core/models/user.dart';
import '../../core/extensions/responsive_extension.dart';
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
    final propertiesAsync = ref.watch(userPropertiesProvider(userId));
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
        final isMobile = context.isMobile;
        // Treat tablet (< 1100px) as small for grid purposes to ensure cards have space
        final isSmallScreen = constraints.maxWidth < 1100;
        final horizontalPadding = isMobile ? 12.0 : 24.0;
        final verticalPadding = isMobile ? 12.0 : 24.0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/users'),
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.secondary,
                      size: isMobile ? 20 : 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 32 : 40,
                      minHeight: isMobile ? 32 : 40,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'USER PROFILE',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.slate,
                            letterSpacing: isMobile ? 1 : 2,
                            fontSize: isMobile ? 10 : 11,
                          ),
                        ),
                        Text(
                          userId,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Urbanist',
                                color: AppColors.white,
                                fontSize: isMobile ? 16 : 24,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 32),

              // Stats Grid - Use 2 columns for tablet/mobile, 4 for desktop
              statsAsync.when(
                data: (stats) => _buildStatsGrid(context, stats, isSmallScreen, isMobile),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading stats: $err'),
              ),

              SizedBox(height: isMobile ? 16 : 32),

              // Split View vs Tabs
              Expanded(
                child: isSmallScreen
                    ? DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Container(
                              height: isMobile ? 36 : 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.primary.withAlpha(77),
                                  ),
                                ),
                              ),
                              child: TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                indicatorColor: AppColors.primary,
                                labelColor: AppColors.white,
                                unselectedLabelColor: AppColors.slate
                                    .withAlpha(
                                  153,
                                ),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: isMobile ? 0.5 : 1,
                                  fontSize: isMobile ? 11 : 14,
                                ),
                                tabs: [
                                  Tab(text: isMobile ? 'SESSIONS' : 'SESSION HISTORY'),
                                  Tab(text: isMobile ? 'ACTIVITY' : 'RECENT ACTIVITY'),
                                  // Tab(text: 'PROPERTIES'),
                                ],
                              ),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  PaginatedSessionsList(
                                    userId: userId,
                                    userName: currentUser?.userName,
                                  ),
                                  PaginatedLogsList(userId: userId),
                                  // _UserPropertiesCard(
                                  //   userId: userId,
                                  //   propertiesAsync: propertiesAsync,
                                  // ),
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

                          // Recent Logs and Properties
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(context, 'RECENT ACTIVITY'),
                                const SizedBox(height: 16),
                                Expanded(
                                  flex: 2,
                                  child: PaginatedLogsList(userId: userId),
                                ),
                                const SizedBox(height: 24),
                                _buildSectionHeader(context, 'PROPERTIES'),
                                const SizedBox(height: 16),
                                // Expanded(
                                //   child: _UserPropertiesCard(
                                //     userId: userId,
                                //     propertiesAsync: propertiesAsync,
                                //   ),
                                // ),
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
    bool isMobile,
  ) {
    return GridView.count(
      crossAxisCount: isSmallScreen ? 2 : 4,
      crossAxisSpacing: isMobile ? 8 : 16,
      mainAxisSpacing: isMobile ? 8 : 16,
      shrinkWrap: true,
      childAspectRatio: isMobile ? 2.2 : (isSmallScreen ? 2.0 : 2.5),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: 'TOTAL LOGS',
          value: stats.totalLogs.toString(),
          icon: Icons.list_alt,
          color: AppColors.secondary,
          isMobile: isMobile,
        ),
        _StatCard(
          label: 'SESSIONS',
          value: stats.sessionCount.toString(),
          icon: Icons.timer,
          color: AppColors.secondary,
          isMobile: isMobile,
        ),
        _StatCard(
          label: 'ERRORS',
          value: stats.errorCount.toString(),
          icon: Icons.warning_amber,
          color: AppColors.error,
          isMobile: isMobile,
        ),
        _StatCard(
          label: isMobile ? 'LAST SEEN' : 'LAST ACTIVE',
          value: DateFormat(isMobile ? 'MMM d' : 'MMM d, HH:mm').format(stats.lastActive),
          icon: Icons.access_time,
          color: AppColors.slate,
          isMobile: isMobile,
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
  final bool isMobile;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: color.withAlpha(77)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: isMobile ? 16 : 20),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.slate,
                    letterSpacing: isMobile ? 0.5 : 1,
                    fontSize: isMobile ? 9 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Urbanist',
                    color: AppColors.white,
                    fontSize: isMobile ? 16 : 22,
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

class _UserPropertiesCard extends ConsumerWidget {
  final String userId;
  final AsyncValue propertiesAsync;

  const _UserPropertiesCard({
    required this.userId,
    required this.propertiesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.slate.withAlpha(77)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: propertiesAsync.when(
        data: (properties) {
          if (properties.properties.isEmpty) {
            return const Center(
              child: Text(
                'NO PROPERTIES SET',
                style: TextStyle(
                  color: AppColors.slate,
                  fontFamily: 'Urbanist',
                  fontSize: 12,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: properties.properties.entries.map<Widget>((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontFamily: 'Urbanist',
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontFamily: 'Urbanist',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load properties',
            style: const TextStyle(
              color: AppColors.error,
              fontFamily: 'Urbanist',
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

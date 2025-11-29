import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/activity_timeline_provider.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/filtered_logs_provider.dart';
import '../../core/providers/log_stats_provider.dart';
import '../../core/providers/logs_provider.dart';
import '../../core/providers/users_provider.dart';
import '../../core/theme/app_colors.dart';

class BottomNav extends ConsumerWidget {
  final String currentRoute;

  const BottomNav({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.primary, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                ref,
                icon: Icons.radar,
                route: '/',
                isActive: currentRoute == '/',
              ),
              _buildNavItem(
                context,
                ref,
                icon: Icons.list_alt,
                route: '/logs',
                isActive: currentRoute == '/logs',
              ),
              _buildNavItem(
                context,
                ref,
                icon: Icons.people_alt,
                route: '/users',
                isActive: currentRoute == '/users',
              ),
              // _buildNavItem(
              //   context,
              //   ref,
              //   icon: Icons.analytics,
              //   route: '/analytics',
              //   isActive: currentRoute == '/analytics',
              // ),
              _buildNavItem(
                context,
                ref,
                icon: Icons.filter_list,
                route: '/funnelytics',
                isActive: currentRoute == '/funnelytics',
              ),
              _buildNavItem(
                context,
                ref,
                icon: Icons.settings,
                route: '/settings',
                isActive: currentRoute == '/settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String route,
    required bool isActive,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          switch (route) {
            case '/':
              ref.invalidate(logStatsProvider);
              ref.invalidate(activityTimelineProvider);
              break;
            case '/logs':
              ref.invalidate(logsProvider);
              ref.invalidate(filteredLogsProvider);
              break;
            case '/users':
              ref.invalidate(usersListProvider);
              break;
            case '/analytics':
              ref.invalidate(analyticsSummaryProvider);
              ref.invalidate(logsTimelineProvider);
              ref.invalidate(logLevelsProvider);
              ref.invalidate(topErrorsProvider);
              ref.invalidate(activeUsersProvider);
              break;
            case '/funnelytics':
              ref.invalidate(namedFunnelDataProvider);
              break;
          }
          context.go(route);
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withAlpha(38)
                : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isActive
                ? AppColors.secondary
                : AppColors.slate.withAlpha(204),
            size: 28,
          ),
        ),
      ),
    );
  }
}

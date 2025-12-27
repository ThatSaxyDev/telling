import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/users_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/extensions/responsive_extension.dart';

/// Navigation item data
class _NavItemData {
  final IconData icon;
  final String label;
  final String route;

  const _NavItemData({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class BottomNav extends ConsumerWidget {
  final String currentRoute;

  const BottomNav({super.key, required this.currentRoute});

  static const List<_NavItemData> _navItems = [
    _NavItemData(icon: Icons.radar, label: 'Command', route: '/'),
    _NavItemData(icon: Icons.list_alt, label: 'Logs', route: '/logs'),
    _NavItemData(icon: Icons.people_alt, label: 'Users', route: '/users'),
    _NavItemData(
      icon: Icons.analytics,
      label: 'Analytics',
      route: '/analytics',
    ),
    _NavItemData(icon: Icons.filter_list, label: 'Funnels', route: '/funnelytics'),
    _NavItemData(icon: Icons.settings, label: 'Settings', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Responsive height - taller on mobile for better touch targets
    final navHeight = context.responsive<double>(
      mobile: 80.0,
      tablet: 70.0,
      desktop: 60.0,
    );
    
    // Check if we should show labels (hide on very small screens)
    final showLabels = context.screenWidth > 320;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.primary, width: 1)),
        // Add subtle shadow for depth on mobile
        boxShadow: context.isNativeMobile
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        height: navHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _navItems.map((item) {
            return Expanded(
              child: _buildNavItem(
                context,
                ref,
                icon: item.icon,
                label: item.label,
                route: item.route,
                isActive: currentRoute == item.route,
                showLabel: showLabels,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    required bool showLabel,
  }) {
    // Responsive icon size
    final iconSize = context.responsive<double>(
      mobile: 24.0,
      tablet: 26.0,
      desktop: 24.0,
    );
    
    // Responsive label size
    final labelSize = context.responsive<double>(
      mobile: 10.0,
      tablet: 11.0,
      desktop: 10.0,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Haptic feedback on mobile
          if (context.isNativeMobile) {
            HapticFeedback.selectionClick();
          }
          
          // Invalidate providers based on route
          // Note: logs, stats, and timeline are now handled by Pusher real-time updates
          switch (route) {
            case '/':
              // Overview - handled by Pusher (logStatsProvider, activityTimelineProvider)
              break;
            case '/logs':
              // Logs - handled by Pusher (logsProvider updates via log_created events)
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
        splashColor: AppColors.primary.withAlpha(51),
        highlightColor: AppColors.primary.withAlpha(26),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? AppColors.secondary
                    : AppColors.slate.withAlpha(204),
                size: iconSize,
              ),
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: isActive
                        ? AppColors.secondary
                        : AppColors.slate.withAlpha(179),
                    fontSize: labelSize,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

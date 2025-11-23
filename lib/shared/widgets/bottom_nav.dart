import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  final String currentRoute;
  
  const BottomNav({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppColors.primary,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.radar,
                route: '/',
                isActive: currentRoute == '/',
              ),
              _buildNavItem(
                context,
                icon: Icons.list_alt,
                route: '/logs',
                isActive: currentRoute == '/logs',
              ),
              _buildNavItem(
                context,
                icon: Icons.people_alt,
                route: '/users',
                isActive: currentRoute == '/users',
              ),
              _buildNavItem(
                context,
                icon: Icons.analytics,
                route: '/analytics',
                isActive: currentRoute == '/analytics',
              ),
              _buildNavItem(
                context,
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
    BuildContext context, {
    required IconData icon,
    required String route,
    required bool isActive,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(route),
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

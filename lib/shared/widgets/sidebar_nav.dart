import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'military_decorations.dart';

class SidebarNav extends StatefulWidget {
  final String currentRoute;

  const SidebarNav({super.key, required this.currentRoute});

  @override
  State<SidebarNav> createState() => _SidebarNavState();
}

class _SidebarNavState extends State<SidebarNav> {
  bool _isCollapsed = false;

  final List<NavItem> _navItems = [
    NavItem(icon: Icons.radar, label: 'COMMAND CENTER', route: '/'),
    NavItem(icon: Icons.list_alt, label: 'LOGS EXPLORER', route: '/logs'),
    NavItem(icon: Icons.people_alt, label: 'USERS', route: '/users'),
    NavItem(icon: Icons.analytics, label: 'ANALYTICS', route: '/analytics'),
    NavItem(icon: Icons.settings, label: 'SETTINGS', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = _isCollapsed ? 100.0 : 280.0;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(right: BorderSide(color: AppColors.primary, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          const Divider(color: AppColors.primary, height: 1),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                return _buildNavItem(_navItems[index]);
              },
            ),
          ),

          const Divider(color: AppColors.primary, height: 1),

          // Collapse Toggle
          _buildCollapseButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CornerBrackets(
            length: 8,
            thickness: 1.5,
            color: AppColors.primary,
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.backgroundDark,
              child: Center(
                child: Text(
                  'T',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 30,
                    letterSpacing: 2,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          if (!_isCollapsed) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TELLING',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'TACTICAL LOGGER',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(NavItem item) {
    final isActive = widget.currentRoute == item.route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: MilitaryHoverContainer(
        onTap: () => context.go(item.route),
        baseColor: isActive ? AppColors.secondary : AppColors.slate,
        hoverColor: AppColors.white,
        showGrid: false,
        child: Container(
          height: 56,
          padding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withAlpha(13)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              if (_isCollapsed)
                Expanded(
                  child: Icon(
                    item.icon,
                    color: isActive
                        ? AppColors.white
                        : AppColors.slate.withAlpha(204),
                    size: 24,
                  ),
                )
              else ...[
                Icon(
                  item.icon,
                  color: isActive
                      ? AppColors.white
                      : AppColors.slate.withAlpha(204),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isActive
                          ? AppColors.white
                          : AppColors.slate.withAlpha(204),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return MilitaryHoverContainer(
      onTap: () => setState(() => _isCollapsed = !_isCollapsed),
      baseColor: Colors.transparent,
      hoverColor: AppColors.tertiary,
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
              color: AppColors.slate,
            ),
            if (!_isCollapsed) ...[
              const SizedBox(width: 8),
              Text(
                'COLLAPSE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final String route;

  NavItem({required this.icon, required this.label, required this.route});
}

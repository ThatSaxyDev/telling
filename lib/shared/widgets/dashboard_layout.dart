import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/extensions/responsive_extension.dart';
import 'military_decorations.dart';
import 'sidebar_nav.dart';
import 'bottom_nav.dart';
import '../../features/projects/widgets/project_selector.dart';
import 'unit_indicator.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final bool showScanline;
  final bool showGrid;
  final String currentRoute;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.header,
    this.showScanline = true,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use new responsive helpers
    final showSidebarNav = context.showSidebar;
    final showBottomNavBar = context.showBottomNav;
    
    // Responsive padding values
    final contentPadding = context.responsive<double>(
      mobile: 12.0,
      tablet: 16.0,
      desktop: 16.0,
    );
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CrosshairCursor(
        child: Row(
          children: [
            // Sidebar Navigation (Desktop only, not on native mobile)
            if (showSidebarNav) SidebarNav(currentRoute: currentRoute),

            // Main Content Area
            Expanded(
              child: Stack(
                children: [
                  // 1. Grid Background
                  if (showGrid)
                    const Positioned.fill(
                      child: GridBackground(
                        color: Color(0xFF222222),
                        spacing: 40,
                      ),
                    ),

                  // 2. Main Content with proper safe area
                  SafeArea(
                    // Don't add bottom padding if we have bottom nav
                    bottom: !showBottomNavBar,
                    child: Column(
                      children: [
                        // Project selector with responsive padding
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: contentPadding,
                            vertical: context.responsive<double>(
                              mobile: 8.0,
                              tablet: 12.0,
                              desktop: 16.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Active-unit context — visible on every screen
                              const Flexible(child: UnitIndicator()),
                              const SizedBox(width: 8),
                              const ProjectSelector(),
                            ],
                          ),
                        ),
                        if (header != null) header!,
                        Expanded(child: child),
                      ],
                    ),
                  ),

                  // 3. Scanline Overlay
                  if (showScanline)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Scanline(
                          color: Color(0x0DFFFFFF)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation (Mobile/Tablet only, or always on native mobile)
      bottomNavigationBar: showBottomNavBar
          ? BottomNav(currentRoute: currentRoute)
          : null,
    );
  }
}


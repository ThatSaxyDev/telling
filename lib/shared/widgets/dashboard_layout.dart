import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'military_decorations.dart';
import 'sidebar_nav.dart';
import 'bottom_nav.dart';
import '../../features/projects/widgets/project_selector.dart';

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
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final showSidebar = !isMobile && !isTablet;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CrosshairCursor(
        child: Row(
          children: [
            // Sidebar Navigation (Desktop only)
            if (showSidebar) SidebarNav(currentRoute: currentRoute),

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

                  // 2. Main Content
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [const ProjectSelector()],
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
      // Bottom Navigation (Mobile/Tablet only)
      bottomNavigationBar: (isMobile || isTablet)
          ? BottomNav(currentRoute: currentRoute)
          : null,
    );
  }
}


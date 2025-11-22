import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'military_decorations.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final bool showScanline;
  final bool showGrid;

  const DashboardLayout({
    super.key,
    required this.child,
    this.header,
    this.showScanline = true,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CrosshairCursor(
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
                  if (header != null) header!,
                  Expanded(child: child),
                ],
              ),
            ),

            // 3. Scanline Overlay (Top layer)
            if (showScanline)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Scanline(
                    color: Color(0x0DFFFFFF), // Very subtle
                  ),
                ),
              ),
              
            // 4. Vignette / CRT Edge Effect (Optional, maybe later)
          ],
        ),
      ),
    );
  }
}

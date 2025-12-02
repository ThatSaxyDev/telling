/// Responsive spacing and sizing constants for consistent UI across all screen sizes.
/// 
/// Use these constants instead of hardcoded values to ensure consistency
/// and make future adjustments easier.
library;

/// Spacing constants (padding, margin, gaps)
abstract class AppSpacing {
  // ============ BASE UNITS ============
  /// 4dp - Minimal spacing
  static const double xs = 4.0;
  
  /// 8dp - Small spacing
  static const double sm = 8.0;
  
  /// 12dp - Medium-small spacing
  static const double md = 12.0;
  
  /// 16dp - Medium spacing (base unit)
  static const double base = 16.0;
  
  /// 20dp - Medium-large spacing
  static const double lg = 20.0;
  
  /// 24dp - Large spacing
  static const double xl = 24.0;
  
  /// 32dp - Extra large spacing
  static const double xxl = 32.0;
  
  /// 48dp - Huge spacing
  static const double xxxl = 48.0;
  
  /// 64dp - Maximum spacing
  static const double max = 64.0;

  // ============ SCREEN PADDING ============
  /// Mobile horizontal screen padding
  static const double screenPaddingMobile = 16.0;
  
  /// Tablet horizontal screen padding
  static const double screenPaddingTablet = 24.0;
  
  /// Desktop horizontal screen padding
  static const double screenPaddingDesktop = 32.0;

  // ============ CARD PADDING ============
  /// Mobile card internal padding
  static const double cardPaddingMobile = 16.0;
  
  /// Tablet card internal padding
  static const double cardPaddingTablet = 20.0;
  
  /// Desktop card internal padding
  static const double cardPaddingDesktop = 24.0;

  // ============ SECTION SPACING ============
  /// Mobile section vertical spacing
  static const double sectionSpacingMobile = 24.0;
  
  /// Tablet section vertical spacing
  static const double sectionSpacingTablet = 32.0;
  
  /// Desktop section vertical spacing
  static const double sectionSpacingDesktop = 48.0;
}

/// Touch target and interactive element sizes
abstract class AppSizes {
  // ============ TOUCH TARGETS ============
  /// Minimum touch target size (48dp is recommended for mobile)
  static const double minTouchTarget = 48.0;
  
  /// Standard button height on mobile
  static const double buttonHeightMobile = 48.0;
  
  /// Standard button height on desktop
  static const double buttonHeightDesktop = 40.0;

  // ============ ICONS ============
  /// Small icon size
  static const double iconSm = 16.0;
  
  /// Medium icon size (default)
  static const double iconMd = 24.0;
  
  /// Large icon size
  static const double iconLg = 32.0;
  
  /// Extra large icon size
  static const double iconXl = 48.0;

  // ============ AVATARS ============
  /// Small avatar size
  static const double avatarSm = 32.0;
  
  /// Medium avatar size
  static const double avatarMd = 40.0;
  
  /// Large avatar size
  static const double avatarLg = 56.0;

  // ============ NAVIGATION ============
  /// Bottom navigation bar height
  static const double bottomNavHeight = 70.0;
  
  /// Sidebar width (collapsed)
  static const double sidebarCollapsed = 80.0;
  
  /// Sidebar width (expanded)
  static const double sidebarExpanded = 280.0;

  // ============ CONTENT ============
  /// Maximum content width for readability
  static const double maxContentWidth = 1200.0;
  
  /// Maximum width for text content
  static const double maxTextWidth = 800.0;
  
  /// Maximum card width on mobile
  static const double maxCardWidthMobile = 400.0;
}

/// Border radius constants
abstract class AppRadius {
  /// No radius
  static const double none = 0.0;
  
  /// Small radius (4dp)
  static const double sm = 4.0;
  
  /// Medium radius (8dp)
  static const double md = 8.0;
  
  /// Large radius (12dp)
  static const double lg = 12.0;
  
  /// Extra large radius (16dp)
  static const double xl = 16.0;
  
  /// Full/circular radius
  static const double full = 999.0;
}

/// Animation duration constants
abstract class AppDurations {
  /// Fast animation (100ms)
  static const Duration fast = Duration(milliseconds: 100);
  
  /// Normal animation (200ms)
  static const Duration normal = Duration(milliseconds: 200);
  
  /// Slow animation (300ms)
  static const Duration slow = Duration(milliseconds: 300);
  
  /// Page transition (400ms)
  static const Duration pageTransition = Duration(milliseconds: 400);
}

/// Elevation constants for shadows
abstract class AppElevation {
  /// No elevation
  static const double none = 0.0;
  
  /// Low elevation (cards, buttons)
  static const double low = 2.0;
  
  /// Medium elevation (dialogs, dropdowns)
  static const double medium = 4.0;
  
  /// High elevation (modals, overlays)
  static const double high = 8.0;
  
  /// Maximum elevation (floating action buttons)
  static const double max = 12.0;
}

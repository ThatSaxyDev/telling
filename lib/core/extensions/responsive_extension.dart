import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Extension on BuildContext for convenient responsive access
extension ResponsiveExtension on BuildContext {
  // ============ SIZE ACCESS ============
  
  /// Get screen size
  Size get screenSize => MediaQuery.sizeOf(this);
  
  /// Get screen width
  double get screenWidth => screenSize.width;
  
  /// Get screen height
  double get screenHeight => screenSize.height;

  // ============ BREAKPOINT CHECKS ============
  
  /// Check if screen is mobile sized
  bool get isMobile => Responsive.isMobile(this);
  
  /// Check if screen is mobile or smaller
  bool get isMobileOrSmaller => Responsive.isMobileLarge(this);
  
  /// Check if screen is tablet sized
  bool get isTablet => Responsive.isTablet(this);
  
  /// Check if screen is desktop sized
  bool get isDesktop => Responsive.isDesktop(this);
  
  /// Check if screen is large desktop
  bool get isLargeDesktop => Responsive.isLargeDesktop(this);

  // ============ DEVICE CHECKS ============
  
  /// Check if running on native mobile platform
  bool get isNativeMobile => Responsive.isNativeMobile;
  
  /// Check if running on native desktop platform
  bool get isNativeDesktop => Responsive.isNativeDesktop;
  
  /// Check if running on web
  bool get isWeb => Responsive.isWeb;

  /// Get current device type
  DeviceType get deviceType => Responsive.getDeviceType(this);

  // ============ RESPONSIVE VALUES ============
  
  /// Get a value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    required T desktop,
  }) => Responsive.value(this, mobile: mobile, tablet: tablet, desktop: desktop);

  /// Get a value with more granular breakpoints
  T responsiveGranular<T>({
    T? mobileSmall,
    required T mobile,
    T? mobileLarge,
    T? tablet,
    required T desktop,
    T? desktopLarge,
  }) => Responsive.valueGranular(
    this,
    mobileSmall: mobileSmall,
    mobile: mobile,
    mobileLarge: mobileLarge,
    tablet: tablet,
    desktop: desktop,
    desktopLarge: desktopLarge,
  );

  // ============ SPACING ============
  
  /// Get horizontal padding
  double get horizontalPadding => Responsive.horizontalPadding(this);
  
  /// Get vertical padding
  double get verticalPadding => Responsive.verticalPadding(this);
  
  /// Get symmetric padding as EdgeInsets
  EdgeInsets get responsivePadding => Responsive.padding(this);
  
  /// Get max content width
  double get maxContentWidth => Responsive.maxContentWidth(this);

  // ============ GRID ============
  
  /// Get grid cross axis count
  int gridColumns({int? mobileCount}) => 
      Responsive.gridCrossAxisCount(this, mobileCount: mobileCount);
  
  /// Get grid child aspect ratio
  double get gridAspectRatio => Responsive.gridChildAspectRatio(this);

  // ============ TYPOGRAPHY ============
  
  /// Get font scale factor
  double get fontScale => Responsive.fontScale(this);
  
  /// Scale a font size responsively
  double scaledFontSize(double baseSize) => baseSize * fontScale;

  // ============ TOUCH TARGETS ============
  
  /// Get minimum touch target size
  double get minTouchTarget => Responsive.minTouchTarget(this);
  
  /// Get responsive icon size
  double responsiveIconSize({double base = 24.0}) => 
      Responsive.iconSize(this, base: base);

  // ============ LAYOUT ============
  
  /// Whether to show sidebar navigation
  bool get showSidebar => Responsive.showSidebar(this);
  
  /// Whether to show bottom navigation
  bool get showBottomNav => Responsive.showBottomNav(this);
  
  /// Get safe area padding
  EdgeInsets get safeAreaPadding => Responsive.safeAreaPadding(this);
}

/// Extension for responsive text styling
extension ResponsiveTextStyleExtension on TextStyle {
  /// Scale this text style based on screen size
  TextStyle responsive(BuildContext context) {
    final scale = context.fontScale;
    return copyWith(
      fontSize: fontSize != null ? fontSize! * scale : null,
    );
  }
}

/// Extension for responsive EdgeInsets
extension ResponsiveEdgeInsetsExtension on EdgeInsets {
  /// Scale this EdgeInsets based on screen size
  EdgeInsets responsive(BuildContext context) {
    final scale = context.isMobile ? 0.75 : (context.isTablet ? 0.9 : 1.0);
    return EdgeInsets.only(
      left: left * scale,
      right: right * scale,
      top: top * scale,
      bottom: bottom * scale,
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Breakpoint thresholds for responsive design
abstract class ResponsiveBreakpoint {
  static const double mobileSmall = 320;
  static const double mobile = 450;
  static const double mobileLarge = 600;
  static const double tablet = 800;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;
  static const double desktop4K = 1920;
}

/// Device type enumeration for clearer conditionals
enum DeviceType { mobileSmall, mobile, mobileLarge, tablet, desktop, desktopLarge }

/// Core responsive utility class with comprehensive helpers
class Responsive {
  /// Check if running on native mobile platform (not web)
  static bool get isNativeMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if running on native desktop platform
  static bool get isNativeDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  // ============ BREAKPOINT CHECKS ============

  /// Extra small phones (< 320px)
  static bool isMobileSmall(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ResponsiveBreakpoint.mobileSmall;

  /// Standard mobile (< 450px) - matches responsive_framework MOBILE
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ResponsiveBreakpoint.mobile;

  /// Large mobile/small tablet (< 600px)
  static bool isMobileLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ResponsiveBreakpoint.mobileLarge;

  /// Tablet range (600px - 800px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= ResponsiveBreakpoint.mobileLarge &&
        width < ResponsiveBreakpoint.tablet;
  }

  /// Desktop and above (>= 800px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ResponsiveBreakpoint.tablet;

  /// Large desktop (>= 1024px)
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ResponsiveBreakpoint.desktop;

  /// Extra large screens (>= 1440px)
  static bool isExtraLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ResponsiveBreakpoint.desktopLarge;

  /// Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < ResponsiveBreakpoint.mobileSmall) return DeviceType.mobileSmall;
    if (width < ResponsiveBreakpoint.mobile) return DeviceType.mobile;
    if (width < ResponsiveBreakpoint.mobileLarge) return DeviceType.mobileLarge;
    if (width < ResponsiveBreakpoint.tablet) return DeviceType.tablet;
    if (width < ResponsiveBreakpoint.desktopLarge) return DeviceType.desktop;
    return DeviceType.desktopLarge;
  }

  // ============ RESPONSIVE VALUES ============

  /// Get a value based on screen size (mobile, tablet, desktop)
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get a value with more granular breakpoints
  static T valueGranular<T>(
    BuildContext context, {
    T? mobileSmall,
    required T mobile,
    T? mobileLarge,
    T? tablet,
    required T desktop,
    T? desktopLarge,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return mobileSmall ?? mobile;
      case DeviceType.mobile:
        return mobile;
      case DeviceType.mobileLarge:
        return mobileLarge ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? desktop;
      case DeviceType.desktop:
        return desktop;
      case DeviceType.desktopLarge:
        return desktopLarge ?? desktop;
    }
  }

  // ============ SPACING HELPERS ============

  /// Get horizontal padding based on screen size
  static double horizontalPadding(BuildContext context) {
    return value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);
  }

  /// Get vertical padding based on screen size
  static double verticalPadding(BuildContext context) {
    return value(context, mobile: 12.0, tablet: 16.0, desktop: 24.0);
  }

  /// Get symmetric padding
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: verticalPadding(context),
    );
  }

  /// Get content max width (for centered layouts)
  static double maxContentWidth(BuildContext context) {
    return valueGranular(
      context,
      mobile: double.infinity,
      tablet: 700.0,
      desktop: 1000.0,
      desktopLarge: 1200.0,
    );
  }

  // ============ GRID HELPERS ============

  /// Get grid cross axis count
  static int gridCrossAxisCount(BuildContext context, {int? mobileCount}) {
    return value(context, mobile: mobileCount ?? 1, tablet: 2, desktop: 4);
  }

  /// Get grid child aspect ratio
  static double gridChildAspectRatio(BuildContext context) {
    return value(context, mobile: 1.4, tablet: 1.2, desktop: 1.2);
  }

  // ============ TYPOGRAPHY SCALING ============

  /// Scale factor for fonts on mobile
  static double fontScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 0.85;
      case DeviceType.mobile:
        return 0.9;
      case DeviceType.mobileLarge:
        return 0.95;
      case DeviceType.tablet:
        return 1.0;
      case DeviceType.desktop:
        return 1.0;
      case DeviceType.desktopLarge:
        return 1.1;
    }
  }

  // ============ TOUCH TARGET HELPERS ============

  /// Minimum touch target size (48dp for mobile, can be smaller on desktop)
  static double minTouchTarget(BuildContext context) {
    return isNativeMobile || isMobile(context) ? 48.0 : 36.0;
  }

  /// Icon size adjusted for screen
  static double iconSize(BuildContext context, {double base = 24.0}) {
    return value(context, mobile: base * 0.9, tablet: base, desktop: base);
  }

  // ============ LAYOUT HELPERS ============

  /// Whether to show sidebar navigation
  static bool showSidebar(BuildContext context) =>
      isDesktop(context) && !isNativeMobile;

  /// Whether to show bottom navigation
  static bool showBottomNav(BuildContext context) =>
      !isDesktop(context) || isNativeMobile;

  /// Get safe area padding (useful for notched devices)
  static EdgeInsets safeAreaPadding(BuildContext context) =>
      MediaQuery.paddingOf(context);
}

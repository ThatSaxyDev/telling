# Mobile Optimization Guide for Telling

This guide documents the responsive patterns and best practices for maintaining mobile-first development in the Telling app.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Responsive Utilities](#responsive-utilities)
3. [Breakpoints](#breakpoints)
4. [Usage Patterns](#usage-patterns)
5. [Best Practices](#best-practices)
6. [Common Patterns](#common-patterns)

---

## Architecture Overview

The mobile optimization system is built on three core components:

```
lib/core/
├── utils/
│   └── responsive.dart          # Core responsive utilities
├── extensions/
│   └── responsive_extension.dart # BuildContext extensions
└── constants/
    └── app_spacing.dart         # Spacing & sizing constants
```

### Key Principles
1. **Mobile-first**: Default values should work on mobile, then scale up
2. **Platform-aware**: Detect native mobile vs web for appropriate UX
3. **Consistent spacing**: Use predefined constants for all spacing
4. **Touch-friendly**: Minimum 48dp touch targets on mobile

---

## Responsive Utilities

### Core Responsive Class (`lib/core/utils/responsive.dart`)

```dart
import 'package:telling/core/utils/responsive.dart';

// Check device type
if (Responsive.isMobile(context)) { ... }
if (Responsive.isTablet(context)) { ... }
if (Responsive.isDesktop(context)) { ... }

// Check platform
if (Responsive.isNativeMobile) { ... }  // iOS/Android app
if (Responsive.isWeb) { ... }           // Web browser

// Get responsive values
final padding = Responsive.value(context,
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
);

// More granular control
final fontSize = Responsive.valueGranular(context,
  mobileSmall: 12.0,
  mobile: 14.0,
  mobileLarge: 15.0,
  tablet: 16.0,
  desktop: 16.0,
  desktopLarge: 18.0,
);
```

### Context Extensions (`lib/core/extensions/responsive_extension.dart`)

```dart
import 'package:telling/core/extensions/responsive_extension.dart';

// Convenient access via context
final isMobile = context.isMobile;
final padding = context.horizontalPadding;
final columns = context.gridColumns(mobileCount: 1);

// Responsive values
final size = context.responsive<double>(
  mobile: 24.0,
  tablet: 32.0,
  desktop: 40.0,
);

// Scale text styles
Text(
  'Hello',
  style: AppTextStyles.bodyLarge.responsive(context),
)
```

---

## Breakpoints

### Current Breakpoint Configuration

| Name | Range | Use Case |
|------|-------|----------|
| MOBILE_SMALL | 0-320px | Very small phones |
| MOBILE | 321-450px | Standard phones |
| MOBILE_LARGE | 451-600px | Large phones, small tablets |
| TABLET | 601-800px | Tablets in portrait |
| DESKTOP | 801-1024px | Tablets landscape, small laptops |
| DESKTOP_LARGE | 1025-1440px | Standard desktops |
| 4K | 1441px+ | Large monitors |

### Matching Breakpoint Classes

```dart
// In responsive.dart
abstract class ResponsiveBreakpoint {
  static const double mobileSmall = 320;
  static const double mobile = 450;
  static const double mobileLarge = 600;
  static const double tablet = 800;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;
}
```

---

## Usage Patterns

### 1. Layout Switching

```dart
@override
Widget build(BuildContext context) {
  // Use context extension
  if (context.showSidebar) {
    return Row(
      children: [
        SidebarNav(),
        Expanded(child: content),
      ],
    );
  }
  
  return Scaffold(
    body: content,
    bottomNavigationBar: BottomNav(),
  );
}
```

### 2. Responsive Padding

```dart
// Using constants
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: context.responsive<double>(
      mobile: AppSpacing.screenPaddingMobile,
      tablet: AppSpacing.screenPaddingTablet,
      desktop: AppSpacing.screenPaddingDesktop,
    ),
  ),
  child: content,
)

// Or using the helper
Padding(
  padding: context.responsivePadding,
  child: content,
)
```

### 3. Responsive Grids

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: context.gridColumns(mobileCount: 1),
    childAspectRatio: context.gridAspectRatio,
    crossAxisSpacing: context.horizontalPadding,
    mainAxisSpacing: context.verticalPadding,
  ),
  itemBuilder: (context, index) => GridItem(),
)
```

### 4. Responsive Typography

```dart
Text(
  'Title',
  style: context.responsive<TextStyle>(
    mobile: AppTextStyles.titleMedium,
    desktop: AppTextStyles.headlineSmall,
  ),
)
```

### 5. Conditional Widgets

```dart
Row(
  children: [
    Icon(Icons.refresh),
    // Only show text on larger screens
    if (!context.isMobile) ...[
      SizedBox(width: 8),
      Text('REFRESH'),
    ],
  ],
)
```

---

## Best Practices

### DO ✅

1. **Use the responsive helpers instead of raw MediaQuery**
   ```dart
   // Good
   final isMobile = context.isMobile;
   
   // Avoid
   final isMobile = MediaQuery.of(context).size.width < 600;
   ```

2. **Use consistent spacing constants**
   ```dart
   // Good
   SizedBox(height: AppSpacing.md);
   
   // Avoid
   SizedBox(height: 12);
   ```

3. **Ensure minimum touch targets on mobile**
   ```dart
   SizedBox(
     height: context.minTouchTarget,
     child: button,
   )
   ```

4. **Handle safe areas properly**
   ```dart
   SafeArea(
     bottom: !context.showBottomNav, // Don't double-pad
     child: content,
   )
   ```

5. **Add haptic feedback on native mobile**
   ```dart
   onTap: () {
     if (context.isNativeMobile) {
       HapticFeedback.selectionClick();
     }
     // ... action
   }
   ```

### DON'T ❌

1. **Don't hardcode pixel values for spacing**
   ```dart
   // Bad
   padding: EdgeInsets.all(24)
   
   // Good
   padding: EdgeInsets.all(AppSpacing.xl)
   ```

2. **Don't use fixed widths without constraints**
   ```dart
   // Bad
   Container(width: 400)
   
   // Good
   Container(
     constraints: BoxConstraints(maxWidth: context.maxContentWidth),
   )
   ```

3. **Don't forget platform differences**
   ```dart
   // Bad - assumes all mobile is touch
   if (context.isMobile) showTouchUI();
   
   // Good - checks actual platform
   if (context.isNativeMobile) showTouchUI();
   ```

---

## Common Patterns

### Screen Layout Template

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;
    final padding = context.horizontalPadding;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: context.verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(isMobile),
                SizedBox(height: AppSpacing.xl),
                
                // Content
                _buildContent(isMobile, constraints.maxWidth),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Icon(Icons.dashboard, size: isMobile ? 24 : 32),
        SizedBox(width: AppSpacing.md),
        Text(
          'DASHBOARD',
          style: isMobile 
            ? AppTextStyles.titleMedium 
            : AppTextStyles.headlineSmall,
        ),
      ],
    );
  }
}
```

### Responsive Card Grid

```dart
Widget _buildCardGrid(List<Item> items) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final crossAxisCount = context.gridColumns(mobileCount: 1);
      final spacing = context.horizontalPadding;
      
      return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: context.gridAspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => ItemCard(item: items[index]),
      );
    },
  );
}
```

### Responsive Dialog/Modal

```dart
void showResponsiveDialog(BuildContext context, Widget content) {
  if (context.isMobile) {
    // Full-screen modal on mobile
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, controller) => content,
      ),
    );
  } else {
    // Centered dialog on desktop
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: content,
        ),
      ),
    );
  }
}
```

---

## Testing Responsiveness

1. **Use Flutter DevTools** to simulate different screen sizes
2. **Test on actual devices** when possible
3. **Use `LayoutBuilder`** to inspect constraints
4. **Consider orientation changes** on tablets

```dart
// Debug helper to show current breakpoint
if (kDebugMode) {
  print('Device: ${context.deviceType}');
  print('Width: ${context.screenWidth}');
  print('isMobile: ${context.isMobile}');
}
```

---

## Migration Guide

When updating existing screens to use the new responsive system:

1. **Import the extensions**
   ```dart
   import 'package:telling/core/extensions/responsive_extension.dart';
   ```

2. **Replace raw breakpoint checks**
   ```dart
   // Before
   final isMobile = MediaQuery.of(context).size.width < 600;
   
   // After
   final isMobile = context.isMobile;
   ```

3. **Replace hardcoded spacing**
   ```dart
   // Before
   padding: EdgeInsets.all(24)
   
   // After
   padding: EdgeInsets.all(context.horizontalPadding)
   ```

4. **Use responsive values for conditionals**
   ```dart
   // Before
   fontSize: isMobile ? 14 : 18
   
   // After
   fontSize: context.responsive<double>(mobile: 14, desktop: 18)
   ```

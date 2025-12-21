# App Configuration & Force Update

The App Configuration module allows you to manage min-version requirements for your mobile apps directly from the dashboard. This essentially gives you "Kill Switch" functionality to force users to update to the latest version.

## How it Works

When your app launches, the Telling SDK checks the current app version against the rules you define here.

### Fields

- **Minimum iOS Version**: The lowest semantic version (e.g., `1.0.2`) allowed for iOS devices.
- **iOS Store URL**: The App Store link where users will be redirected if they need to update.
- **Minimum Android Version**: The lowest semantic version allowed for Android devices.
- **Android Store URL**: The Play Store link for updates.
- **Force Update Message**: The message displayed to users on the update screen (e.g., "A critical security update is available.").
- **Blocking Update**: 
    - **Enabled**: Users CANNOT dismiss the update screen. They must update to continue.
    - **Disabled**: Users see a "Later" button and can skip the update.

## Best Practices

1. **SemVer Compliance**: Ensure your app uses Semantic Versioning (`X.Y.Z`).
2. **Grace Periods**: When releasing a new version, consider making the update **non-blocking** for a few days before enforcing it.
3. **Emergency Fixes**: If you release a critical bug fix (e.g., `1.0.5`), set the minimum version to `1.0.5` and enable **Blocking Update** to ensure all users get the fix immediately.

## Implementation Guide

To enforce these rules in your app, use the `telling_logger` SDK version 1.4.0+.

### 1. Check for Updates

```dart
// Check on app startup (e.g., in main.dart or Splash Screen)
final result = await Telling.instance.checkVersion();

if (result.requiresUpdate) {
  if (result.isRequired) {
    // Blocking update - show non-dismissible UI
  } else {
    // Optional update - user can skip
  }
}
```

### 2. Handle Optional Updates with Snooze

When the user skips an optional update, call `snoozeUpdate()` to suppress the prompt for a few days:

```dart
if (result.requiresUpdate && !result.isRequired) {
  final skipped = await showUpdateDialog();
  
  if (skipped && result.minVersion != null) {
    await Telling.instance.snoozeUpdate(
      days: 3, // 0 = no snooze, 1-3 = days to suppress
      minVersion: result.minVersion!,
    );
  }
}
```

**Snooze Behavior:**
- **0 days**: No snooze, prompt every app launch
- **1-3 days**: Suppress prompt until snooze expires
- **Version change**: Snooze resets when you update the minimum version


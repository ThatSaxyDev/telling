# App Configuration & Force Update

The App Configuration module allows you to manage min-version requirements for your mobile apps directly from the dashboard. This essentially gives you "Kill Switch" functionality to force users to update to the latest version.

## How it Works

After SDK initialization, your app calls `checkVersion()` to compare its installed version and build against the rules you define here. This is an explicit call, not an automatic check on every launch.

### Fields

- **Minimum iOS Version**: The lowest semantic version (e.g., `1.0.2`) allowed for iOS devices.
- **Minimum iOS Build**: Optional positive whole number (e.g., `24`); clear it to disable the build check.
- **iOS Store URL**: The App Store link where users will be redirected if they need to update.
- **Minimum Android Version**: The lowest semantic version allowed for Android devices.
- **Minimum Android Build**: Optional positive whole number, independent of the iOS minimum.
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

For build-aware checks, use `telling_logger` 1.5.0+ for Flutter or `telling_kit` 1.0.1+ for DartNative. Older SDKs keep checking versions only.

Version and build thresholds are independent: falling below either triggers an update. For minimum version `1.0.4` and minimum build `24`, `1.0.4+23` and `1.0.5+23` both trigger an update, while `1.0.4+24` passes. Builds must increase across releases per platform. Missing or nonnumeric installed builds skip the build comparison without skipping the version comparison.

The SDK sends `GET /api/v1/project/version-check?platform=ios&version=1.0.4&build=23` with the project's `x-api-key`. Minimum builds are stored under `min_ios_build` and `min_android_build` in the existing project config. Update responses add `minBuild`, `target` (for example `1.0.4+24`) and `decisionSource` (`version`, `build` or `version+build`). `minBuild` is set only when the build threshold triggers. Pass `result.snoozeTarget` to the methods below so a changed build target is not hidden by an older snooze.

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
      target: result.snoozeTarget,
    );
  }
}
```

**Snooze Behavior:**
- **0 days**: No snooze, prompt every app launch
- **1-3 days**: Suppress prompt until snooze expires
- **Target change**: Snooze resets when the returned version/build target changes

### 3. Track Update Acceptance

When the user accepts an update, call `acceptUpdate()` before opening the store URL:

```dart
if (shouldUpdate == true) {
  await Telling.instance.acceptUpdate(
    minVersion: result.minVersion,
    target: result.snoozeTarget,
  );
  launchUrl(Uri.parse(result.storeUrl!));
}
```

## Automatic Analytics

The SDK automatically tracks update-related events—no manual logging required:

| Event | When Logged | Properties |
|-------|-------------|------------|
| `update_check_completed` | Every `checkVersion()` call | `requires_update`, `is_required`, `min_version`, `current_version`, `current_build`, `min_build`, `target`, `decision_source`, `is_snoozed` |
| `update_prompted` | When update is required (not snoozed) | `is_required`, `min_version`, `current_version`, `current_build`, `min_build`, `target`, `decision_source` |
| `update_snoozed` | When `snoozeUpdate()` is called | `snooze_days`, `min_version`, `current_version`, `current_build`, `target` |
| `update_accepted` | When `acceptUpdate()` is called | `min_version`, `current_version`, `current_build`, `target` |

This gives you a complete funnel: **check → prompt → (snooze OR accept)**.

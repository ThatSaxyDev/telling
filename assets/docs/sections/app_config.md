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
    - **Disabled**: Users see a "Not Now" button and can skip the update.

## Best Practices

1. **SemVer Compliance**: Ensure your app uses Semantic Versioning (`X.Y.Z`).
2. **Grace Periods**: When releasing a new version, consider making the update **non-blocking** for a few days before enforcing it.
3. **Emergency Fixes**: If you release a critical bug fix (e.g., `1.0.5`), set the minimum version to `1.0.5` and enable **Blocking Update** to ensure all users get the fix immediately.

## Implementation Guide

To enforce these rules in your app, use the `telling_logger` SDK version 1.3.0+.

### 1. Check for Updates

```dart
// Check on app startup
final result = await Telling.instance.checkVersion();

if (result.requiresUpdate) {
  // Update is available
}
```

### 2. Show Update Screen

Use the built-in widget for a seamless experience:

```dart
if (result.requiresUpdate) {
  runApp(MaterialApp(
    home: TellingForceUpdateScreen(
      result: result,
      primaryColor: Colors.blue, 
      onSkip: () {
        // Navigate to home for optional updates
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      },
    ),
  ));
}
```

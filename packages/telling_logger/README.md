# telling_logger

A comprehensive crash reporting and analytics SDK for Flutter apps, similar to Sentry and Mixpanel combined.

## Features

- 🐛 **Automatic Crash Reporting**: Catches unhandled errors and exceptions
- 📊 **Activity Tracking**: Track user events and actions
- 📱 **Device Metadata**: Automatically collects platform, OS version, device model, and app info
- 🔄 **Buffered Logging**: Smart batching to avoid network spam
- 🌐 **Multi-platform**: Works on iOS, Android, Web, macOS, Windows, and Linux

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  telling_logger:
    path: packages/telling_logger
```

## Usage

### Initialize

```dart
import 'package:telling_logger/telling_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with your API key
  await Telling.instance.init('YOUR_API_KEY');
  
  // Enable automatic crash reporting
  Telling.instance.enableCrashReporting();
  
  runApp(MyApp());
}
```

### Manual Logging

```dart
// Simple log
Telling.instance.log('User logged in');

// Log with level
Telling.instance.log(
  'Failed to load data',
  level: LogLevel.warning,
);

// Log with metadata
Telling.instance.log(
  'Purchase completed',
  metadata: {'amount': 99.99, 'currency': 'USD'},
);
```

### Track Events (Analytics)

```dart
// Track a user action
Telling.instance.event('Button Clicked', properties: {
  'button_name': 'Sign Up',
  'screen': 'Home',
});

// Track screen views
Telling.instance.event('Screen Viewed', properties: {
  'screen_name': 'Profile',
});
```

### Automatic Crash Reporting

Once you call `enableCrashReporting()`, all uncaught errors will be automatically logged:

```dart
// This crash will be caught automatically
throw Exception('Something went wrong!');
```

## Device Metadata

Every log event automatically includes:
- Platform (iOS, Android, Web, etc.)
- OS Version
- Device Model
- App Version
- Build Number
- Session ID

## API Reference

### `Telling.instance.init(String apiKey, {String? baseUrl})`
Initialize the SDK with your API key.

### `Telling.instance.enableCrashReporting()`
Enable automatic crash and error reporting.

### `Telling.instance.log(String message, {LogLevel level, Map<String, dynamic>? metadata})`
Log a message with optional level and metadata.

### `Telling.instance.event(String name, {Map<String, dynamic>? properties})`
Track an analytics event.

## Example

See the main `telling` app for a complete example with all features.

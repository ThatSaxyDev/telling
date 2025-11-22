# telling_logger

A comprehensive crash reporting and analytics SDK for Flutter apps, designed to work seamlessly with the Telling Dashboard.

## 🚀 Features

- **🐛 Automatic Crash Reporting**: Catches unhandled errors and exceptions.
- **📊 Activity Tracking**: Track user events and actions.
- **📱 Device Metadata**: Automatically collects platform, OS version, device model, and app info.
- **📝 Structured Logging**: Support for various log levels (Debug, Info, Warning, Error, Fatal) and types (Log, Analytics, Network, Performance).
- **🔄 Buffered Logging**: Smart batching to avoid network spam.
- **🌐 Multi-platform**: Works on iOS, Android, Web, macOS, Windows, and Linux.

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  telling_logger:
    path: packages/telling_logger
```

## 💻 Usage

### Initialize

Initialize the SDK in your `main.dart` before running the app.

```dart
import 'package:telling_logger/telling_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with your backend URL
  await Telling.instance.init(
    'YOUR_API_KEY', // API Key (placeholder for now)
    baseUrl: 'http://localhost:8080/api/v1/logs', // Your backend URL
  );
  
  // Enable automatic crash reporting
  Telling.instance.enableCrashReporting();
  
  runApp(MyApp());
}
```

### Logging

```dart
// Standard Log
Telling.instance.log('User logged in');

// Warning with Metadata
Telling.instance.log(
  'API Latency High',
  level: LogLevel.warning,
  type: LogType.performance,
  metadata: {'latency_ms': 450, 'endpoint': '/users'},
);

// Error Log
try {
  throw Exception('Database connection failed');
} catch (e, stack) {
  Telling.instance.log(
    'Database Error',
    level: LogLevel.error,
    type: LogType.error,
    stackTrace: stack.toString(),
  );
}
```

### Analytics & Events

```dart
// Track a user action
Telling.instance.event('Button Clicked', properties: {
  'button_name': 'Sign Up',
  'screen': 'Onboarding',
});

// Track a screen view
Telling.instance.event('Screen Viewed', properties: {
  'screen_name': 'Profile',
});
```

### Automatic Crash Reporting

Once `enableCrashReporting()` is called, any unhandled exception in your Flutter app will be automatically caught and sent to the dashboard with a full stack trace and device metadata.

```dart
// This crash will be caught automatically!
throw Exception('Unexpected Crash!');
```

## 📊 Data Models

The SDK uses structured data models compatible with the Telling Dashboard:

- **LogLevel**: `debug`, `info`, `warning`, `error`, `fatal`
- **LogType**: `log`, `error`, `analytics`, `event`, `performance`, `network`, `custom`

## 📱 Device Metadata

Every log automatically includes:
- Platform (iOS, Android, Web, etc.)
- OS Version
- Device Model
- App Version & Build Number
- Session ID

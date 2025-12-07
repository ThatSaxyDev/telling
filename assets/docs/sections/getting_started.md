# Getting Started

## 📦 Installation
Add `telling_logger` to your `pubspec.yaml`:

```yaml
dependencies:
  telling_logger: ^1.2.1
```

Then install:

```bash
flutter pub get
```

## 🔑 Get Your API Key
To use Telling Logger, you need an API key.

1. Go to the [Telling Dashboard](https://telling.cv/).
2. Log in or create an account.
3. Create a new project to obtain your API key.

## 🚀 Quick Start

### 1. Initialize the SDK
In your `main.dart`, initialize Telling before running your app:

```dart
import 'package:flutter/material.dart';
import 'package:telling_logger/telling_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Telling SDK
  await Telling.instance.init(
    'YOUR_API_KEY',
    enableDebugLogs: true, 
  );

  // Enable automatic crash reporting
  Telling.instance.enableCrashReporting();

  runApp(MyApp());
}
```

### 2. Log Events

```dart
// Simple info log
Telling.instance.log('User completed onboarding');

// Log with metadata
Telling.instance.log(
  'Payment processed',
  level: LogLevel.info,
  metadata: {
    'amount': 29.99,
    'currency': 'USD',
    'payment_method': 'stripe',
  },
);

// Error logging
try {
  await processPayment();
} catch (e, stack) {
  Telling.instance.captureException(
    error: e,
    stackTrace: stack,
    context: 'payment_processing',
    metadata: {'amount': 29.99},
  );
}
```

### 3. Track Analytics

```dart
// Track custom events
Telling.instance.event(
  'button_clicked',
  properties: {
    'button_name': 'Sign Up',
    'screen': 'Landing Page',
    'user_segment': 'free_trial',
  },
);
```

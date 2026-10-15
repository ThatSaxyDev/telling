# Getting Started with DartNative

`telling_kit` is the DartNative edition of `telling_logger`. Same public API,
same wire format, same dashboard — code written against the Flutter SDK ports by
changing one import.

> **Porting from Flutter?** The API is almost entirely unchanged. Two things
> are genuinely different and both bite silently: the **bootstrap order** and
> **screen tracking**. Read [Bootstrap & Crash Capture](bootstrap.md) before you
> ship, and do not skip it.

## Install

```yaml
dependencies:
  telling_kit:
    hosted: https://dartpub.dev
    version: ^1.0.0
```

```sh
dn pub get
```

`dn pub get` picks the package up and generates the plugin registrant for you.
There is nothing to link: no `.xcframework`, no `.aar`, no podspec, no gradle
module. See [Device Metadata](device_metadata.md) for why it ships no native
code.

## Bootstrap

Two steps, and the order matters.

```dart
import 'package:dartnative/dartnative.dart';
import 'dartnative_plugin_registrant.dart';
import 'package:telling_kit/telling_kit.dart';

void main() {
  // FIRST line: platform bindings and every plugin's FFI symbols.
  DartNativePluginRegistrant.registerAll();

  // Before anything else has a chance to throw.
  Telling.instance.armCrashCapture();

  // Wraps the app body so unhandled async errors keep their user context.
  Telling.instance.run(() => runApp(const MyApp()));
}

Future<void> startTelling(String apiKey) async {
  await Telling.instance.init(apiKey, enableDebugLogs: true);

  // Only now that the SDK can receive reports.
  Telling.instance.enableCrashReporting();
}
```

`armCrashCapture()` runs before `init()` on purpose, and `run()` wraps the body
on purpose. [Bootstrap & Crash Capture](bootstrap.md) explains what you lose if
you reorder them.

## Tracking events

Identical to the Flutter SDK.

```dart
Telling.instance.event('button_clicked', properties: {
  'button_name': 'Sign Up',
  'screen': 'Landing Page',
  'user_segment': 'free_trial',
});
```

## Logging

```dart
Telling.instance.log('User completed onboarding');

// With metadata
Telling.instance.log(
  'Payment processed',
  level: LogLevel.info,
  metadata: {
    'amount': 29.99,
    'currency': 'USD',
    'payment_method': 'stripe',
  },
);
```

## Errors

```dart
try {
  await processPayment();
} catch (error, stackTrace) {
  Telling.instance.captureException(
    error: error,
    stackTrace: stackTrace,
    context: 'payment_processing',
    metadata: {'amount': 29.99},
  );
}
```

## Identity

Call `setUser` **before** tracking a funnel — it ends the current session, so
calling it mid-funnel splits the steps across users in the backend.

```dart
Telling.instance.setUser(
  userId: 'usr_123',
  userName: 'Ada',
  userEmail: 'ada@example.com',
);

Telling.instance.setUserProperties({'tier': 'pro'});
```

## Identical to Flutter

Everything below behaves exactly as it does in `telling_logger` — no toggle, no
alternate form:

`log` · `event` · `trackFunnel` · `captureException` · `setUser` · `clearUser` ·
`setUserName` · `setUserProperty` · `setUserProperties` · `getUserProperty` ·
`clearUserProperty` · `clearUserProperties` · `flush` · `checkVersion` ·
`snoozeUpdate` · `acceptUpdate` · `TellingTryCatch` · `LogLevel` · `LogType` ·
`.nowTelling()`

See [Core Concepts](../core_concepts.md) and
[Error Handling](../advanced_features.md).
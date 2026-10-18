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
  dartnative: ^1.0.0
  dartnative_shared_preferences: ^1.0.0
  dartnative_system: ^1.0.0
  telling_kit:
    hosted: https://dartpub.dev
    version: ^1.0.1
```

```sh
dn pub get
```

`dn pub get` resolves the package and generates the plugin registrant. Declare
`dartnative_shared_preferences` and `dartnative_system` directly in the app as
shown above; the registry omits SDK-managed dependencies from its pub source archive.
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

## Build-aware update checks

`telling_kit` 1.0.1+ sends the installed build with `checkVersion()`, matching
`telling_logger` 1.5.0+. Customers set minimum iOS and Android builds alongside
versions in the same project configuration screen on mobile and web. Either
minimum can trigger an update. Pass `result.snoozeTarget` as the optional `target`
to `snoozeUpdate()` and `acceptUpdate()` so snoozes follow the exact build target.
See [App Configuration & Force Update](../app_config.md) for API examples and
compatibility with older clients.

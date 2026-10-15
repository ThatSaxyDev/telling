# Bootstrap & Crash Capture

How DartNative reports uncaught errors, and why the ordering is different from
Flutter.

## Why this is not the same as Flutter

With `telling_logger` the whole setup is one linear sequence:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Telling.instance.init('YOUR_API_KEY');
  Telling.instance.enableCrashReporting();
  runApp(MyApp());
}
```

With `telling_kit` it is not:

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  Telling.instance.armCrashCapture();
  Telling.instance.run(() => runApp(const MyApp()));
}

Future<void> startTelling(String apiKey) async {
  await Telling.instance.init(apiKey);
  Telling.instance.enableCrashReporting();
}
```

Two differences — and **both fail silently**. Nothing throws, nothing warns. The
app simply reports less than you think it does, which is why this page exists.

## 1. Arm before you initialise

`armCrashCapture()` installs an `Isolate.addErrorListener` over a
`RawReceivePort`. It must run **before** `init()`, so anything thrown during
startup is buffered rather than lost.

This is strictly stronger than Flutter's `PlatformDispatcher.instance.onError`,
which only sees errors raised inside a zone. The isolate listener also catches a
synchronous throw inside `main()` itself.

```dart
// Wrong — this throw reaches nobody.
Future<void> main() async {
  await Telling.instance.init(apiKey);  // awaits…
  throw StateError('boom');             // …and is lost
}

// Right — armed first, buffered, flushed once init completes.
Future<void> main() async {
  Telling.instance.armCrashCapture();
  await Telling.instance.init(apiKey);
  Telling.instance.enableCrashReporting();
}
```

## 2. Wrap the app body

`run()` installs a `runZonedGuarded` zone. It catches the async gaps the isolate
reports with no user context — a `Future` with no `errorHandler`, a bare `await`
that throws.

```dart
// Wrong — async errors reach no handler.
void main() {
  DartNativePluginRegistrant.registerAll();
  Telling.instance.armCrashCapture();
  runApp(const MyApp());
}

// Right
void main() {
  DartNativePluginRegistrant.registerAll();
  Telling.instance.armCrashCapture();
  Telling.instance.run(() => runApp(const MyApp()));
}
```

`run()` is a **no-op passthrough** when crash reporting was never enabled, so
calling it unconditionally is safe.

Already own a zone? Forward into `TellingCrashReporter.handleZoneError` rather
than nesting a second zone:

```dart
runZonedGuarded(
  () => runApp(const MyApp()),
  (error, stack) => TellingCrashReporter.handleZoneError(error, stack),
);
```

## One crash, one report

A fatal error is commonly caught by **both** paths, because an error propagating
out of `runZonedGuarded` still reaches the isolate. Crashes are fingerprinted by
type + message + top stack frame, and repeats inside a 2-second window collapse
into a single report. One crash, one row.

## Layout failures are warnings

`RenderFlex overflowed`, `constraints`, `disposed` and similar are classified as
**warnings** rather than fatal — the same heuristic the Flutter SDK uses, so a
dashboard keeps separating layout noise from real crashes across both SDKs.

## Verifying it works

Do not wait for a real crash. After the first launch, force one through and
confirm it lands:

```dart
Telling.instance.captureException(
  error: StateError('crash pipeline check'),
  context: 'manual_verification',
);
await Telling.instance.flush();
```

Both this and a real uncaught throw should appear in the dashboard immediately.
`flush()` bypasses the batching timer, so you are not waiting on a debounce.
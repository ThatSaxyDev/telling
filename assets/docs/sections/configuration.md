# Configuration

## Initialization Parameters

```dart
await Telling.instance.init(
  String apiKey,           // Required
  {
    String? userId,        // Optional initial context
    bool? enableDebugLogs, // Control console output
  }
);
```

## Environment Setup

```dart
const isProduction = bool.fromEnvironment('dart.vm.product');

await Telling.instance.init(
  isProduction ? 'PROD_API_KEY' : 'DEV_API_KEY',
);
```

## Debug Logs

```dart
// Explicitly enable
await Telling.instance.init('KEY', enableDebugLogs: true);

// Disable
await Telling.instance.init('KEY', enableDebugLogs: false);
```

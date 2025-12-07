# Advanced Features

## Exception Capture
Report handled exceptions from try-catch blocks without crashing your app:

```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  Telling.instance.captureException(
    error: e,
    stackTrace: stackTrace,
    context: 'checkout_flow',
    metadata: {'orderId': '12345'},
  );
}
```

## TellingTryCatch Mixin
For cleaner code, use the `TellingTryCatch` mixin to automatically capture exceptions:

```dart
class PaymentService with TellingTryCatch {
  Future<Receipt?> processPayment(double amount) async {
    return tryRun(
      context: 'process_payment',
      metadata: {'amount': amount},
      func: () async {
        final result = await api.charge(amount);
        return Receipt.fromJson(result);
      },
    );
  }
}
```

## User Context Tracking
Associate logs with specific users for better debugging and analytics:

```dart
// Set user context
Telling.instance.setUser(
  userId: 'user_12345',
  userName: 'Jane Doe',
  userEmail: 'jane@example.com',
);

// Clear on logout
Telling.instance.clearUser();
```

## User Properties
Track custom user attributes for segmentation:

```dart
Telling.instance.setUserProperties({
  'subscription_tier': 'premium',
  'seats': 5,
});
```

## Automatic Screen Tracking

### With MaterialApp
```dart
MaterialApp(
  navigatorObservers: [
    Telling.instance.screenTracker,
  ],
  home: HomeScreen(),
)
```

### With go_router
```dart
final router = GoRouter(
  observers: [
    Telling.instance.goRouterScreenTracker,
  ],
  routes: [...],
);
```

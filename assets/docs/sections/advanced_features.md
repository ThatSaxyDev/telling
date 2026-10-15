# Error Handling & User Context


<br>


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


<br>


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


<br>


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


<br>


## User Properties
Track custom user attributes for segmentation:

```dart
Telling.instance.setUserProperties({
  'subscription_tier': 'premium',
  'seats': 5,
});
```


<br>

## Automatic Screen Tracking

Moved. Screen tracking is Flutter-only (DartNative has no observer hook), so it
now has its own page:

- **[Screen Tracking (Flutter)](flutter_screen_tracking.md)** — `MaterialApp` and
  `go_router` observer setup.

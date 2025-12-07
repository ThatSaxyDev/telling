# Funnel Tracking

Track user journeys through multi-step flows to identify drop-off points.

> [!CAUTION]
> **Critical: Set User Context First**
> Always call `Telling.instance.setUser()` **BEFORE** tracking funnel steps to connect the journey to a single user.

## Basic Usage

```dart
Telling.instance.trackFunnel(
  funnelName: 'onboarding',
  stepName: 'email_entered',
  step: 1,
  properties: {'source': 'google_ads'},
);
```

## Example: Checkout Flow

```dart
final checkoutFunnel = 'checkout_flow';

// Step 1: Cart viewed
Telling.instance.trackFunnel(
  funnelName: checkoutFunnel,
  stepName: 'cart_viewed',
  step: 1,
);

// Step 2: Shipping
Telling.instance.trackFunnel(
  funnelName: checkoutFunnel,
  stepName: 'shipping_submitted',
  step: 2,
);

// Step 3: Payment (Conversion)
Telling.instance.trackFunnel(
  funnelName: checkoutFunnel,
  stepName: 'payment_completed',
  step: 3,
);
```

## Best Practices
1. **Consistent Naming**: Use exact same `funnelName` for all steps.
2. **Sequential Steps**: Use `step` numbers (1, 2, 3).
3. **Descriptive Names**: Use action-oriented step names.
4. **Anonymous Users**: Generate a temporary ID for non-logged-in users.

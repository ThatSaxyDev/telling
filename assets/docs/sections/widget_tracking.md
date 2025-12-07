# Widget Tracking

Use the `.nowTelling()` extension to track any widget's visibility:

```dart
// Basic usage
Column(children: [Text('Hello')]).nowTelling()

// With custom name
ProductCard(product: item).nowTelling(
  name: 'Product Card Impression',
)

// With metadata
PremiumFeature().nowTelling(
  name: 'Premium Feature Shown',
  metadata: {
    'feature_id': 'dark_mode',
    'user_tier': 'free',
  },
)
```

**Parameters:**
- `name` – Custom name (defaults to runtimeType)
- `type` – Log type (defaults to analytics)
- `level` – Log level (defaults to info)
- `metadata` – Additional context
- `trackOnce` – Track only first appearance (defaults to true)

# Named Funnel Analysis - Frontend Integration Guide

## Overview
We've implemented Named Funnel Analysis endpoints that automatically discover and analyze funnels tracked using `Telling.instance.trackFunnel()`.

---

## Backend Endpoints

### 1. Get Available Funnels
**Endpoint:** `GET /api/v1/analytics/funnels`

**Query Parameters:**
- `projectId` (Required): The project ID

**Headers:**
- `Authorization`: `Bearer <JWT_TOKEN>`

**Response:**
```json
["checkout_flow", "onboarding_flow", "signup_flow"]
```

---

### 2. Analyze Named Funnel
**Endpoint:** `GET /api/v1/analytics/funnel-analysis`

**Query Parameters:**
- `projectId` (Required): The project ID
- `funnelName` (Required): Name of the funnel to analyze
- `startDate` (Optional): ISO 8601 string (defaults to 30 days ago)
- `endDate` (Optional): ISO 8601 string (defaults to now)

**Headers:**
- `Authorization`: `Bearer <JWT_TOKEN>`

**Response:**
```json
{
  "funnelName": "checkout_flow",
  "steps": [
    {
      "name": "cart_viewed",
      "count": 150,
      "stepNumber": 1
    },
    {
      "name": "checkout_started",
      "count": 90,
      "stepNumber": 2,
      "conversionFromPrevious": 60.0
    },
    {
      "name": "payment_completed",
      "count": 45,
      "stepNumber": 3,
      "conversionFromPrevious": 50.0
    }
  ],
  "overallConversion": 30.0
}
```

---

## Data Models (Dart/Flutter)

```dart
class FunnelStep {
  final String name;
  final int count;
  final int stepNumber;
  final double? conversionFromPrevious;

  FunnelStep({
    required this.name,
    required this.count,
    required this.stepNumber,
    this.conversionFromPrevious,
  });

  factory FunnelStep.fromJson(Map<String, dynamic> json) {
    return FunnelStep(
      name: json['name'],
      count: json['count'],
      stepNumber: json['stepNumber'],
      conversionFromPrevious: json['conversionFromPrevious']?.toDouble(),
    );
  }
}

class NamedFunnelData {
  final String funnelName;
  final List<FunnelStep> steps;
  final double overallConversion;

  NamedFunnelData({
    required this.funnelName,
    required this.steps,
    required this.overallConversion,
  });

  factory NamedFunnelData.fromJson(Map<String, dynamic> json) {
    return NamedFunnelData(
      funnelName: json['funnelName'],
      steps: (json['steps'] as List)
          .map((e) => FunnelStep.fromJson(e))
          .toList(),
      overallConversion: json['overallConversion'].toDouble(),
    );
  }
}
```

---

## Implementation Flow

### 1. Fetch Available Funnels
```dart
Future<List<String>> getFunnelNames(String projectId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/analytics/funnels?projectId=$projectId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    return (json.decode(response.body) as List).cast<String>();
  }
  throw Exception('Failed to load funnel names');
}
```

### 2. Display Funnel Selector
Create a dropdown or list UI that shows all available funnel names for the user to select.

### 3. Fetch & Display Funnel Analysis
```dart
Future<NamedFunnelData> analyzeFunnel(String projectId, String funnelName) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/analytics/funnel-analysis?projectId=$projectId&funnelName=$funnelName'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    return NamedFunnelData.fromJson(json.decode(response.body));
  }
  throw Exception('Failed to analyze funnel');
}
```

---

## Visualization Recommendations

### Funnel Chart Widget
Create a visual funnel where each step's width represents the user count:

```
┌────────────────────────────────┐
│   cart_viewed: 150             │ 100%
└────────────────────────────────┘
         ↓ 60% conversion
    ┌────────────────────┐
    │ checkout_started: 90    │
    └────────────────────┘
         ↓ 50% conversion
        ┌──────────┐
        │ payment: 45   │
        └──────────┘
```

**Display Elements:**
- Step name and count inside/beside each bar
- Conversion percentage in the connector between bars
- Overall conversion prominently at the top
- Color gradient (green → yellow → red) based on conversion rates

### Alternative: Bar Chart
If a funnel chart is complex, use a simple bar chart with tooltips showing conversion rates.

---

## UI/UX Tips

1. **Empty State**: If `getFunnelNames` returns empty, show message: "No funnels tracked yet. Use `Telling.instance.trackFunnel()` in your app."
2. **Date Range Picker**: Allow users to filter by date range for trend analysis.
3. **Step Details**: Make each step clickable to show detailed user lists or event metadata.
4. **Export**: Add CSV export for funnel data.

---

## Example Usage in App

Track funnels in your Flutter app like this:

```dart
// Step 1
Telling.instance.trackFunnel('checkout_flow', 'cart_viewed', step: 1);

// Step 2
Telling.instance.trackFunnel('checkout_flow', 'checkout_started', step: 2);

// Step 3
Telling.instance.trackFunnel('checkout_flow', 'payment_completed', step: 3);
```

The dashboard will automatically discover these steps and calculate conversions!

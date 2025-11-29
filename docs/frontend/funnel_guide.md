# Frontend Implementation Guide: Funnel Analysis

## Overview
We have implemented a new backend endpoint for **Funnel Analysis**. This allows you to track user conversion rates through a sequence of events (e.g., `signup_started` -> `email_entered` -> `completed`).

## API Endpoint

### `GET /api/v1/analytics/funnel`

**Query Parameters:**
- `projectId` (Required): The ID of the project.
- `steps` (Required): A comma-separated list of event names defining the funnel order.
  - Example: `steps=view_item,add_to_cart,checkout_start,purchase`
- `startDate` (Optional): ISO 8601 string (e.g., `2023-01-01T00:00:00.000Z`). Defaults to 30 days ago.
- `endDate` (Optional): ISO 8601 string. Defaults to now.

**Headers:**
- `Authorization`: `Bearer <JWT_TOKEN>`

---

## Data Models (Dart/Flutter)

```dart
class FunnelStep {
  final String name;
  final int count;
  final int stepNumber;
  final double? conversionFromPrevious; // Null for the first step

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

class FunnelData {
  final List<FunnelStep> steps;
  final double overallConversion;

  FunnelData({
    required this.steps,
    required this.overallConversion,
  });

  factory FunnelData.fromJson(Map<String, dynamic> json) {
    return FunnelData(
      steps: (json['steps'] as List)
          .map((e) => FunnelStep.fromJson(e))
          .toList(),
      overallConversion: json['overallConversion'].toDouble(),
    );
  }
}
```

---

## Example Response

```json
{
  "steps": [
    {
      "name": "signup_started",
      "count": 150,
      "stepNumber": 1
    },
    {
      "name": "email_entered",
      "count": 90,
      "stepNumber": 2,
      "conversionFromPrevious": 60.0
    },
    {
      "name": "completed",
      "count": 45,
      "stepNumber": 3,
      "conversionFromPrevious": 50.0
    }
  ],
  "overallConversion": 30.0
}
```

---

## Visualization Recommendations

### 1. Funnel Chart (Preferred)
A vertical or horizontal funnel chart where the width of each bar represents the count.
- **Visuals**: Use a gradient color scheme that gets darker or lighter as the funnel progresses.
- **Labels**: Show the step name and the absolute count inside or next to the bar.
- **Connectors**: Show the conversion rate (e.g., "60%") in the space between bars.

### 2. Bar Chart (Alternative)
A simple bar chart if a funnel widget is not available.
- X-Axis: Step Names
- Y-Axis: User Count
- Tooltip: Show conversion rate from previous step.

### 3. Summary Card
Display the **Overall Conversion Rate** prominently at the top of the chart (e.g., "30% Conversion Rate").

---

## Implementation Checklist
- [ ] Create `FunnelRepository` to fetch data from the API.
- [ ] Add `FunnelChartWidget` using a charting library (e.g., `fl_chart` or custom painter).
- [ ] Add a "Funnel Configuration" UI where users can input/select the steps they want to analyze.

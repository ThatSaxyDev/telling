# Frontend Integration Guide

This document outlines the new backend features and how to integrate them into the frontend dashboard.

## 1. User Properties

### Endpoints

- **GET** `/api/v1/users/{userId}/properties`
  - **Headers**: `x-api-key: {PROJECT_API_KEY}`
  - **Response**:
    ```json
    {
      "userId": "user_123",
      "properties": {
        "subscription_tier": "premium",
        "custom_key": "custom_value"
      },
      "updatedAt": "2025-01-01T12:00:00.000Z"
    }
    ```

- **POST** `/api/v1/users/{userId}/properties`
  - **Headers**: `Content-Type: application/json`, `x-api-key: {PROJECT_API_KEY}`
  - **Body**:
    ```json
    {
      "properties": {
        "subscription_tier": "enterprise"
      }
    }
    ```
  - **Response**: `{"success": true, "updated": 1}`

### UI Integration
- **User Detail Page**: Add a "Properties" section to display key-value pairs.
- **Edit Properties**: Allow admins to add/edit properties for a user.

## 2. Performance Analytics

### Endpoints

- **GET** `/api/v1/analytics/performance/overview`
  - **Headers**: `x-api-key: {PROJECT_API_KEY}` (or User Auth if implemented)
  - **Query Params**:
    - `projectId`: Required
    - `startDate`: ISO 8601 (optional, default 30 days ago)
    - `endDate`: ISO 8601 (optional, default now)
    - `metric`: Filter by metric type (optional)
  - **Response**:
    ```json
    {
      "period": {
        "start": "...",
        "end": "..."
      },
      "metrics": {
        "startup_time": {
          "avg": 1250.5,
          "p50": 1100,
          "p90": 1800,
          "p95": 2200,
          "p99": 3500,
          "samples": 1500
        },
        "fps": { ... }
      }
    }
    ```

### UI Integration
- **Performance Dashboard**: Create a new dashboard or tab.
- **Charts**:
  - Display cards for key metrics (Startup Time, FPS, Memory).
  - Show P50/P90/P95 values.
  - (Future) Time-series charts (endpoint not yet optimized for time-series, currently gives aggregate).

## 3. Log Ingestion Updates

- The backend now automatically extracts `_user_properties` from log metadata and updates the user properties table.
- Performance logs (type=`performance`) are automatically extracted and stored in `performance_metrics`.

### SDK Usage
- To track user properties:
  ```dart
  Telling.log(
    'User updated profile',
    type: 'analytics',
    metadata: {
      '_user_properties': {
        'plan': 'pro',
        'role': 'admin'
      }
    }
  );
  ```
- To track performance:
  ```dart
  Telling.log(
    'App Startup',
    type: 'performance',
    metadata: {
      'startup_time_ms': 1200
    }
  );
  ```

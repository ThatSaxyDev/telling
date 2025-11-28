# Backend Implementation Guide: Events Endpoint for Funnel Analysis

## Overview

To support funnel analysis event discovery on the frontend, we need a new backend endpoint that returns all unique event names for a given project.

## Required Endpoint

### `GET /api/v1/analytics/events`

Returns a list of all unique event names that have been logged for the specified project.

**Query Parameters:**
- `projectId` (Required, String): The ID of the project

**Headers:**
- `Authorization` (Required): `Bearer <JWT_TOKEN>`
  - The JWT should contain the user's ID
  - Backend should verify that the user has access to this project

**Response Format:**
```json
{
  "events": [
    "signup_started",
    "email_entered",
    "checkout_started",
    "purchase_completed",
    "profile_viewed",
    "settings_opened"
  ]
}
```

**Response Codes:**
- `200 OK`: Successfully retrieved events list
- `400 Bad Request`: Missing or invalid `projectId`
- `401 Unauthorized`: Missing or invalid JWT token
- `403 Forbidden`: User does not have access to this project
- `500 Internal Server Error`: Server error

---

## Implementation Notes

### Database Query

The endpoint should query the database for distinct event names. Assuming you have a `logs` or `events` table:

```sql
SELECT DISTINCT event_name
FROM events
WHERE project_id = $1
ORDER BY event_name ASC;
```

**Considerations:**
- Add an index on `(project_id, event_name)` for performance
- Consider caching this result (e.g., Redis) with a short TTL since event names don't change frequently
- Limit the number of returned events (e.g., max 1000) to prevent overly large responses

### Authorization

1. Extract `userId` from the JWT token
2. Verify that the user has permission to access the specified `projectId`
3. This should use the same authorization logic as other analytics endpoints

### Performance Optimization

For projects with millions of events, consider:
- Implementing pagination if the event list grows very large
- Caching the results:
  ```
  Key: `events:${projectId}`
  TTL: 5 minutes
  ```
- Building a separate `event_names` table that's updated on event insert

---

## Testing

### Test Cases

1. **Valid Request**
   ```
   GET /api/v1/analytics/events?projectId=abc123
   Authorization: Bearer <valid_token>
   
   Expected: 200 OK with events array
   ```

2. **Missing projectId**
   ```
   GET /api/v1/analytics/events
   Authorization: Bearer <valid_token>
   
   Expected: 400 Bad Request
   ```

3. **Unauthorized Access**
   ```
   GET /api/v1/analytics/events?projectId=abc123
   
   Expected: 401 Unauthorized
   ```

4. **User without project access**
   ```
   GET /api/v1/analytics/events?projectId=xyz789
   Authorization: Bearer <token_for_different_user>
   
   Expected: 403 Forbidden
   ```

5. **Empty Event List**
   ```
   // Project with no events logged yet
   Expected: 200 OK with empty array: {"events": []}
   ```

---

## Integration with Existing Funnel Endpoint

The events endpoint works in tandem with the existing funnel endpoint:

1. **User Flow:**
   - Frontend calls `GET /analytics/events` to populate event selector
   - User selects events (e.g., `["signup_started", "email_entered", "completed"]`)
   - Frontend calls `GET /analytics/funnel?steps=signup_started,email_entered,completed`

2. **Data Consistency:**
   - Events returned by `/analytics/events` should match the event names used in `/analytics/funnel`
   - Both endpoints should use the same event name field from the database

---

## Questions?

If you have questions about the implementation or need clarification, please refer to the existing analytics endpoints (`/analytics/summary`, `/analytics/timeline`, etc.) for consistent patterns around:
- JWT authentication
- Project authorization
- Error handling
- Response formatting

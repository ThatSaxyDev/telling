# Backend API Endpoints - Settings Features

This document specifies the new API endpoints required for the settings screen enhancements.

## Required Endpoints

### 1. Get User Profile

**Endpoint:** `GET /api/auth/profile`

**Authentication:** Required (Bearer token)

**Description:** Returns the authenticated user's profile information.

**Request Headers:**
```
Authorization: Bearer {jwt_token}
```

**Response 200 (Success):**
```json
{
  "id": "user-uuid",
  "email": "user@example.com",
  "name": "John Doe",
  "createdAt": "2025-11-20T10:30:00Z",
  "updatedAt": "2025-11-25T07:47:00Z"
}
```

**Response 401 (Unauthorized):**
```json
{
  "error": "Invalid or missing authentication token"
}
```

**Notes:**
- `name` field is optional (can be null or omitted if not set)
- `createdAt` and `updatedAt` should be ISO 8601 formatted timestamps

---

### 2. Request Password Reset

**Endpoint:** `POST /api/auth/request-password-reset`

**Authentication:** Required (Bearer token)

**Description:** Initiates password reset by sending an OTP to the user's email.

**Request Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response 200 (Success):**
```json
{
  "userId": "user-uuid",
  "message": "OTP sent to email"
}
```

**Response 400 (Bad Request):**
```json
{
  "error": "Email not found"
}
```

**Response 401 (Unauthorized):**
```json
{
  "error": "Invalid or missing authentication token"
}
```

**Notes:**
- Generate a 6-digit numeric OTP
- OTP should expire after 10 minutes
- Email the OTP to the user
- Return the `userId` for the next verification step

---

### 3. Verify Password Reset OTP

**Endpoint:** `POST /api/auth/verify-password-reset`

**Authentication:** Not required (public endpoint)

**Description:** Verifies the OTP and returns a temporary reset token.

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "userId": "user-uuid",
  "otp": "123456"
}
```

**Response 200 (Success):**
```json
{
  "resetToken": "temporary-reset-token-jwt-or-uuid",
  "message": "OTP verified successfully"
}
```

**Response 400 (Bad Request):**
```json
{
  "error": "Invalid or expired OTP"
}
```

**Notes:**
- Validate that the OTP matches and hasn't expired
- Generate a temporary reset token (JWT or UUID)
- Reset token should expire after 15 minutes
- Invalidate the OTP after successful verification

---

### 4. Reset Password

**Endpoint:** `POST /api/auth/reset-password`

**Authentication:** Not required (uses reset token)

**Description:** Sets a new password using the reset token from OTP verification.

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "resetToken": "temporary-reset-token-jwt-or-uuid",
  "newPassword": "newSecurePassword456"
}
```

**Response 200 (Success):**
```json
{
  "message": "Password reset successfully"
}
```

**Response 400 (Bad Request):**
```json
{
  "error": "Invalid or expired reset token"
}
```

**Response 422 (Validation Error):**
```json
{
  "error": "Password does not meet requirements"
}
```

**Notes:**
- Validate the reset token
- Password requirements:
  - Minimum 8 characters
  - Must contain at least one number or special character
- Hash the new password before storing
- Invalidate the reset token after use
- Optionally: invalidate all existing user sessions/tokens

---

### 5. Regenerate Project API Key

**Endpoint:** `POST /api/projects/{projectId}/regenerate-key`

**Authentication:** Required (Bearer token)

**Description:** Regenerates the API key for a specific project, invalidating the old key.

**Request Headers:**
```
Authorization: Bearer {jwt_token}
```

**URL Parameters:**
- `projectId` - The UUID of the project

**Response 200 (Success):**
```json
{
  "apiKey": "newly-generated-api-key-value",
  "message": "API key regenerated successfully"
}
```

**Response 403 (Forbidden):**
```json
{
  "error": "Insufficient permissions to regenerate API key"
}
```

**Response 404 (Not Found):**
```json
{
  "error": "Project not found"
}
```

**Notes:**
- Verify the authenticated user owns/has access to the project
- Generate a new unique API key
- Immediately invalidate the old API key
- Return the new API key (this is the only time it will be shown in full)
- Consider logging this action for security audit

---

## Security Considerations

1. **Rate Limiting:** 
   - Implement rate limiting on OTP requests (e.g., max 3 per 15 minutes per user)
   - Rate limit password reset attempts

2. **OTP Security:**
   - Use cryptographically random OTPs
   - Store hashed OTPs in database
   - Implement attempt limits (e.g., max 5 incorrect attempts)

3. **Reset Token:**
   - Use JWT with short expiration or secure random UUID
   - Store hash if using UUID approach
   - Include user ID in token payload

4. **API Key Generation:**
   - Generate cryptographically secure random keys
   - Ensure uniqueness across all projects
   - Consider using a prefix for easy identification (e.g., `tl_live_...`)

5. **Audit Logging:**
   - Log all password reset attempts
   - Log API key regenerations with timestamp and user

---

## Testing Checklist

- [ ] User can fetch their profile successfully
- [ ] Profile returns 401 for unauthenticated requests
- [ ] Password reset OTP is sent to email
- [ ] OTP verification works with correct code
- [ ] OTP verification fails with incorrect/expired code
- [ ] Password reset works with valid reset token
- [ ] Password reset validates password requirements
- [ ] Old password no longer works after reset
- [ ] API key regeneration creates new key
- [ ] Old API key is immediately invalidated
- [ ] Unauthorized users cannot regenerate others' API keys
- [ ] Rate limiting prevents abuse

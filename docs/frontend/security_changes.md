# Frontend Changes Required for Backend Security Hardening

**Project**: Telling Dashboard  
**Backend Changes**: Security hardening (rate limiting, OTP enhancement, account lockout)  
**Priority**: CRITICAL - Required for production deployment  
**Estimated Effort**: 4-6 hours

---

## 📋 Executive Summary

The backend has undergone critical security hardening to prevent account takeover attacks. The frontend must be updated to handle new OTP formats, rate limiting responses, and account lockout scenarios.

**Breaking Changes**:
- ✅ OTP format changed from 6 digits to 8 alphanumeric characters
- ✅ New HTTP status codes (429 for rate limiting)
- ✅ New error response formats

---

## 🎯 Changes Overview

| Change | Component | Priority |
|--------|-----------|----------|
| OTP input field (6 → 8 chars alphanumeric) | Auth screens | 🔴 CRITICAL |
| Handle 429 rate limit responses | API layer | 🔴 CRITICAL |
| Display account lockout messages | Auth screens | 🟡 HIGH |
| Update OTP validation logic | Form validators | 🟡 HIGH |
| Show retry countdown timers | Error UI | 🟢 MEDIUM |

---

## 1. OTP Format Change (CRITICAL)

### What Changed

**Before**: 6-digit numeric OTP (e.g., `123456`)  
**After**: 8-character alphanumeric OTP (e.g., `A3X7K9P2`)

**Characters used**: `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`  
**Excluded**: `O`, `0`, `I`, `1`, `l` (to prevent user confusion)

### Files to Update

#### 1.1 OTP Input Widget

**Search for**: Any `TextField` or `TextFormField` with `maxLength: 6` in auth screens

**Update**:
```dart
// BEFORE
TextFormField(
  maxLength: 6,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
)

// AFTER
TextFormField(
  maxLength: 8,
  keyboardType: TextInputType.text,
  textCapitalization: TextCapitalization.characters,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
    UpperCaseTextFormatter(), // Auto-uppercase
  ],
)
```

**Helper formatter to add**:
```dart
// Add to lib/utils/text_formatters.dart or similar
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
```

#### 1.2 OTP Validation

**Search for**: OTP validation functions (likely in validators or form fields)

**Update**:
```dart
// BEFORE
String? validateOtp(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the 6-digit code';
  }
  if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
    return 'OTP must be 6 digits';
  }
  return null;
}

// AFTER
String? validateOtp(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the 8-character code';
  }
  if (value.length != 8) {
    return 'OTP must be 8 characters';
  }
  if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(value.toUpperCase())) {
    return 'OTP must contain only letters and numbers';
  }
  return null;
}
```

#### 1.3 UI Text Updates

**Search for**: Any UI text mentioning "6-digit" or "6 digit"

**Examples**:
```dart
// BEFORE
Text('Enter the 6-digit code sent to your email')
Text('Didn't receive the 6-digit code?')

// AFTER
Text('Enter the 8-character code sent to your email')
Text('Didn't receive the code?')
```

---

## 2. Rate Limiting Handling (CRITICAL)

### New Response Format

When rate limits are exceeded, the backend returns:

```json
HTTP 429 Too Many Requests

{
  "error": "Too many requests",
  "message": "Rate limit exceeded. Please try again later.",
  "retryAfter": 900
}
```

**Fields**:
- `error`: Short error identifier
- `message`: User-friendly error message
- `retryAfter`: Seconds until user can retry

### Files to Update

#### 2.1 API Service/Repository Layer

**Location**: Wherever you make HTTP requests (likely `lib/services/auth_service.dart` or `lib/repositories/auth_repository.dart`)

**Add custom exception**:
```dart
// Add to lib/exceptions/api_exceptions.dart or similar
class RateLimitException implements Exception {
  final String message;
  final int retryAfterSeconds;

  RateLimitException({
    required this.message,
    required this.retryAfterSeconds,
  });

  String get retryAfterFormatted {
    if (retryAfterSeconds < 60) {
      return '$retryAfterSeconds seconds';
    } else {
      final minutes = (retryAfterSeconds / 60).ceil();
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }
}
```

**Update HTTP client**:
```dart
// In your API client/service
Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
  final response = await http.post(
    Uri.parse('$baseUrl$path'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  // Add this handling
  if (response.statusCode == 429) {
    final data = jsonDecode(response.body);
    throw RateLimitException(
      message: data['message'] ?? 'Too many requests. Please try again later.',
      retryAfterSeconds: data['retryAfter'] ?? 60,
    );
  }

  if (response.statusCode >= 400) {
    final data = jsonDecode(response.body);
    throw ApiException(
      message: data['error'] ?? 'An error occurred',
      statusCode: response.statusCode,
    );
  }

  return jsonDecode(response.body);
}
```

#### 2.2 UI Error Handling

**Location**: Auth screens (login, register, OTP verification)

**Update error handling**:
```dart
// In login/register/OTP screens
Future<void> handleAuthAction() async {
  try {
    await authRepository.login(email, password);
    // Success handling
  } on RateLimitException catch (e) {
    // Show rate limit error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  } on ApiException catch (e) {
    // Other API errors
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  } catch (e) {
    // Unknown errors
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred ($e)')),
      );
    }
  }
}
```

**Optional: Retry countdown dialog**:
```dart
void showRateLimitDialog(BuildContext context, RateLimitException error) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Too Many Attempts'),
      content: Text(
        '${error.message}\n\nPlease try again in ${error.retryAfterFormatted}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## 3. Account Lockout Handling (HIGH)

### New Response Format

When an account is locked due to failed OTP attempts:

```json
HTTP 429 Too Many Requests

{
  "error": "Account temporarily locked",
  "message": "Too many failed attempts. Try again in 25 minutes."
}
```

### Files to Update

#### 3.1 OTP Verification Screen

**Add lockout handling**:
```dart
// In OTP verification method
Future<void> verifyOtp(String otp) async {
  setState(() => isLoading = true);
  
  try {
    final result = await authRepository.verifyOtp(
      userId: widget.userId,
      otp: otp,
    );
    
    // Success - navigate to home
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } on RateLimitException catch (e) {
    // Account locked or rate limited
    if (mounted) {
      if (e.message.contains('locked')) {
        // Show account locked dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(Icons.lock_outline, size: 48, color: Colors.red),
            title: Text('Account Temporarily Locked'),
            content: Text(
              e.message + '\n\nThis is a security measure to protect your account.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to login
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Regular rate limit
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  } on ApiException catch (e) {
    // Invalid OTP or other errors
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}
```

---

## 4. Password Reset Flow Updates (HIGH)

### What Changed

The password reset flow now has stricter rate limits:
- **3 requests per hour** for password reset
- **5 OTP attempts** with 30-minute lockout

### Files to Update

#### 4.1 Forgot Password Screen

**Update to handle rate limits**:
```dart
Future<void> requestPasswordReset() async {
  if (!formKey.currentState!.validate()) return;
  
  setState(() => isLoading = true);
  
  try {
    await authRepository.requestPasswordReset(email: emailController.text);
    
    // Navigate to OTP screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordResetOtpScreen(
            email: emailController.text,
          ),
        ),
      );
    }
  } on RateLimitException catch (e) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Request Limit Reached'),
          content: Text(
            '${e.message}\n\nYou can request password reset ${e.retryAfterFormatted}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Other errors
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}
```

---

## 5. User Feedback Improvements (MEDIUM)

### 5.1 Show Remaining Attempts (Optional Enhancement)

While the backend doesn't currently expose remaining attempts, you can track them client-side:

```dart
// In OTP verification screen state
int failedAttempts = 0;
static const maxAttempts = 5;

Future<void> verifyOtp(String otp) async {
  try {
    await authRepository.verifyOtp(userId: widget.userId, otp: otp);
    // Success
  } on ApiException catch (e) {
    if (e.message.contains('Invalid OTP')) {
      setState(() => failedAttempts++);
      
      final remaining = maxAttempts - failedAttempts;
      if (remaining > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid code. You have $remaining attempt${remaining > 1 ? 's' : ''} remaining.',
            ),
          ),
        );
      }
    }
  }
}
```

---

## 6. Testing Checklist

### Manual Testing

**OTP Input**:
- [ ] OTP field accepts 8 characters
- [ ] OTP field converts lowercase to uppercase automatically
- [ ] OTP field rejects special characters
- [ ] OTP field shows correct keyboard (alphanumeric)
- [ ] Validation shows error for less than 8 characters
- [ ] Validation shows error for more than 8 characters

**Rate Limiting**:
- [ ] Attempting 6+ logins shows rate limit message
- [ ] Rate limit message displays correct retry time
- [ ] Rate limit clears after waiting
- [ ] Register endpoint respects rate limits
- [ ] Password reset respects rate limits

**Account Lockout**:
- [ ] 5 failed OTP attempts locks account
- [ ] Lockout shows clear message with time
- [ ] Locked account cannot verify OTP
- [ ] Lockout clears after 30 minutes
- [ ] New OTP request works after lockout

**Error Messages**:
- [ ] All error messages are user-friendly
- [ ] No technical error details shown to user
- [ ] Status codes don't leak in UI
- [ ] Loading states prevent double-submission

### Edge Cases

- [ ] What if user closes app during lockout?
- [ ] What if backend returns unexpected status code?
- [ ] What if retryAfter is missing in 429 response?
- [ ] What if OTP contains lowercase (backend should handle)?

---

## 7. API Endpoint Changes Summary

### No Breaking Endpoint Changes

All API endpoints remain the same. Only response formats changed:

| Endpoint | Method | Changes |
|----------|--------|---------|
| `/api/v1/auth/register` | POST | May return 429 |
| `/api/v1/auth/login` | POST | May return 429 |
| `/api/v1/auth/verify` | POST | May return 429; OTP now 8 chars |
| `/api/v1/auth/resend-otp` | POST | May return 429 |
| `/api/v1/auth/request-password-reset` | POST | May return 429 |
| `/api/v1/auth/verify-password-reset` | POST | May return 429; OTP now 8 chars |
| `/api/v1/auth/reset-password` | POST | No changes |

---

## 8. Deployment Strategy

### Recommended Rollout

1. **Deploy backend changes** (already done on `fix/security` branch)
2. **Deploy frontend changes** immediately after
3. **Monitor error rates** for 24 hours
4. **Clear old OTPs** (optional - they'll expire naturally within 10 minutes)

### User Communication

**Email/In-app notification**:
> "We've enhanced security! Verification codes are now 8 characters with letters and numbers for better protection."

---

## 9. Quick Reference: Error Response Formats

```dart
// 429 Rate Limit
{
  "error": "Too many requests",
  "message": "Rate limit exceeded. Please try again later.",
  "retryAfter": 900  // seconds
}

// 429 Account Locked
{
  "error": "Account temporarily locked",
  "message": "Too many failed attempts. Try again in 25 minutes."
}

// 403 Invalid OTP
{
  "error": "Invalid OTP"
}

// 400 Bad Request
{
  "error": "Missing userId or otp"
}
```

---

## 10. Code Snippets Repository

### Complete Exception Classes

```dart
// lib/exceptions/api_exceptions.dart

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class RateLimitException implements Exception {
  final String message;
  final int retryAfterSeconds;

  RateLimitException({
    required this.message,
    required this.retryAfterSeconds,
  });

  String get retryAfterFormatted {
    if (retryAfterSeconds < 60) {
      return '$retryAfterSeconds seconds';
    }
    final minutes = (retryAfterSeconds / 60).ceil();
    return '$minutes minute${minutes > 1 ? 's' : ''}';
  }

  @override
  String toString() => message;
}
```

### Complete Text Formatter

```dart
// lib/utils/text_formatters.dart

import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
```

---

## ✅ Implementation Checklist

Copy this checklist to track your progress:

```markdown
## Frontend Security Updates

- [ ] Update OTP input fields (maxLength: 8, alphanumeric)
- [ ] Add UpperCaseTextFormatter to OTP inputs
- [ ] Update OTP validation regex
- [ ] Update all "6-digit" text to "8-character"
- [ ] Create RateLimitException class
- [ ] Update API client to throw RateLimitException on 429
- [ ] Add rate limit error handling to login screen
- [ ] Add rate limit error handling to register screen
- [ ] Add rate limit error handling to OTP verification
- [ ] Add rate limit error handling to password reset
- [ ] Add account lockout dialog for OTP verification
- [ ] Test all auth flows end-to-end
- [ ] Update any API documentation/comments
- [ ] Manual QA testing complete
```

---

## 📞 Questions?

If you encounter any issues or need clarification:

1. Check the backend source code: `telling_server/lib/handlers/auth_handler.dart`
2. Review backend API spec: `telling_server/backend_endpoints_spec.md`
3. Test endpoints manually with curl/Postman to see exact responses

**Backend deployed at**: Check your deployment URL  
**API version**: v1  
**Breaking changes**: OTP format only

---

**Generated**: November 26, 2025  
**Backend Branch**: `fix/security`  
**Frontend Target**: Main dashboard application

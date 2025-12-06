# Account Deletion - Flutter Integration Guide

## Overview

The backend supports full account deletion (GDPR-compliant). When a user deletes their account, all associated data is permanently removed:

- User record
- All projects
- All logs
- All performance metrics
- OTP attempts
- User properties

## API Endpoint

```
DELETE /api/v1/auth/account
```

### Headers

| Header | Value | Required |
|--------|-------|----------|
| `Authorization` | `Bearer <jwt_token>` | Yes |

### Response

**Success (200):**
```json
{
  "message": "Account and all associated data deleted successfully"
}
```

**Unauthorized (401):**
```json
{
  "error": "Invalid or missing authentication token"
}
```

**Server Error (500):**
```json
{
  "error": "Account deletion failed"
}
```

---

## Flutter Implementation

### 1. API Service Method

```dart
// In your auth_service.dart or api_service.dart

Future<bool> deleteAccount() async {
  final token = await getStoredToken(); // Get JWT from secure storage
  
  final response = await http.delete(
    Uri.parse('$baseUrl/api/v1/auth/account'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception('Failed to delete account: ${response.body}');
  }
}
```

### 2. Delete Account Flow (Recommended UX)

```dart
// In your settings or profile screen

Future<void> handleDeleteAccount() async {
  // Step 1: Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'Are you sure you want to delete your account? '
        'This action cannot be undone and all your data will be permanently deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  // Step 2: Optional - Ask for password re-entry for extra security
  final password = await showPasswordConfirmDialog(context);
  if (password == null) return;
  
  // Step 3: Show loading
  showLoadingDialog(context);
  
  try {
    // Step 4: Call delete API
    await authService.deleteAccount();
    
    // Step 5: Clear local data
    await clearAllLocalData();
    
    // Step 6: Navigate to login/onboarding
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    
    // Step 7: Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deleted successfully')),
    );
  } catch (e) {
    Navigator.pop(context); // Dismiss loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete account: $e')),
    );
  }
}
```

### 3. Clear Local Data Helper

```dart
Future<void> clearAllLocalData() async {
  // Clear secure storage (JWT, refresh tokens)
  final secureStorage = FlutterSecureStorage();
  await secureStorage.deleteAll();
  
  // Clear shared preferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  
  // Clear any cached data (Hive, SQLite, etc.)
  // await Hive.deleteFromDisk();
  
  // Clear any in-memory state (Provider, Riverpod, Bloc, etc.)
  // ref.invalidate(userProvider);
}
```

### 4. Settings Screen UI Example

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ... other settings ...
          
          const Divider(),
          
          // Danger Zone
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Danger Zone',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account and all data'),
            onTap: () => handleDeleteAccount(),
          ),
        ],
      ),
    );
  }
}
```

---

## Best Practices

### Security
- ✅ Require re-authentication before deletion (password or biometric)
- ✅ Use HTTPS for all API calls
- ✅ Clear all local tokens/data after deletion

### UX
- ✅ Show clear warning about permanent data loss
- ✅ Use a 2-step confirmation (dialog + password)
- ✅ Show loading indicator during deletion
- ✅ Provide feedback on success/failure
- ✅ Redirect to login screen after successful deletion

### Data
- ✅ Clear secure storage (tokens)
- ✅ Clear shared preferences
- ✅ Clear any local database (Hive, SQLite, etc.)
- ✅ Invalidate any cached state

---

## Testing

### Manual Test Flow
1. Login to an account
2. Navigate to Settings → Delete Account
3. Confirm deletion in dialog
4. Enter password (if implemented)
5. Verify redirect to login screen
6. Try logging in with deleted credentials → Should fail
7. Verify local storage is cleared

### Test Credentials (Dev Only)
```
Email: kiishidart@gmail.com
Password: Test202@
```

---

## Error Handling

| Error | Cause | User Action |
|-------|-------|-------------|
| 401 Unauthorized | Token expired or invalid | Re-login and try again |
| 500 Server Error | Backend issue | Retry later or contact support |
| Network Error | No connection | Check internet and retry |

# Best Practices


<br>


## 1. Initialize Early
Call `init()` before `runApp()` to catch startup crashes.


<br>


## 2. Use Appropriate Log Levels
- **Info**: Successful operations
- **Warning**: Potential issues (slow queries, retries)
- **Error**: Operation failures
- **Fatal**: App crashes


<br>


## 3. Add Context
Always add `metadata` or `properties` to make logs useful.
```dart
// Good
Telling.instance.event('purchase', properties: {'id': 'p1', 'price': 10});

// Bad
Telling.instance.event('purchase');
```


<br>


## 4. Handle Sensitive Data
Never log passwords, credit card numbers, or PII. Hash emails if needed.


<br>


## Common Errors
- **"Telling SDK not initialized"**: You forgot to await `init()`.
- **"Invalid API Key"**: Check your dashboard settings.

import 'dart:math';
import 'package:http/http.dart' as http;

/// Formats errors into user-friendly messages for display in the UI
class ErrorFormatter {
  // List of creative, professional error messages with a military/tactical theme
  static final List<String> _errorMessages = [
    'Mission aborted',
    'Signal lost',
    'Operation failed',
    'System malfunction detected',
    'Communication breakdown',
    'Unable to establish connection',
    'Request timed out',
    'Access denied',
    'Data stream interrupted',
    'Network anomaly detected',
    'Protocol error encountered',
    'Unable to process request',
    'Transmission failed',
    'Connection terminated',
    'Service unavailable',
  ];

  static final _random = Random();

  /// Converts an error object into a user-friendly message
  /// 
  /// For HTTP errors with status codes, returns a random message with "(XXX)"
  /// For all other errors, returns a random message
  static String format(dynamic error) {
    if (error == null) {
      return _getRandomMessage();
    }

    // Check if it's an HTTP response
    if (error is http.Response) {
      return '${_getRandomMessage()} (${error.statusCode})';
    }

    // Try to extract status code from error message
    final errorString = error.toString();
    
    // Pattern to match status codes in error messages like "Failed (404)" or "status code 500"
    final statusCodePattern = RegExp(r'\b([45]\d{2})\b');
    final match = statusCodePattern.firstMatch(errorString);
    
    if (match != null) {
      return '${_getRandomMessage()} (${match.group(1)})';
    }

    // Default: random user-friendly message
    return _getRandomMessage();
  }

  /// Returns a random error message from the list
  static String _getRandomMessage() {
    return _errorMessages[_random.nextInt(_errorMessages.length)];
  }
}

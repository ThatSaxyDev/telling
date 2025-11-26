import 'package:http/http.dart' as http;

/// Formats errors into user-friendly messages for display in the UI
class ErrorFormatter {
  /// Converts an error object into a user-friendly message
  /// 
  /// For HTTP errors with status codes, returns "An error occurred (XXX)"
  /// For all other errors, returns "An error occurred"
  static String format(dynamic error) {
    if (error == null) {
      return 'An error occurred';
    }

    // Check if it's an HTTP response
    if (error is http.Response) {
      return 'An error occurred (${error.statusCode})';
    }

    // Try to extract status code from error message
    final errorString = error.toString();
    
    // Pattern to match status codes in error messages like "Failed (404)" or "status code 500"
    final statusCodePattern = RegExp(r'\b([45]\d{2})\b');
    final match = statusCodePattern.firstMatch(errorString);
    
    if (match != null) {
      return 'An error occurred (${match.group(1)})';
    }

    // Default user-friendly message
    return 'An error occurred';
  }
}

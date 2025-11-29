import 'package:flutter/services.dart';

/// Text input formatter that converts all input to uppercase
/// Useful for OTP codes and other case-insensitive alphanumeric inputs
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

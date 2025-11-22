class NumberFormatter {
  /// Formats a number with thousand separators (e.g., 1,234,567)
  static String format(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      buffer.write(str[i]);
      final remainingDigits = length - i - 1;
      if (remainingDigits > 0 && remainingDigits % 3 == 0) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  /// Formats a number string with thousand separators
  static String formatString(String numberString) {
    final number = int.tryParse(numberString);
    if (number == null) return numberString;
    return format(number);
  }
}

import 'package:flutter/services.dart';

/// Centralized phone number formatter for consistent formatting across the app.
///
/// Formats numeric input into the pattern: (XXX)XXXXXXX
/// - Accepts only digits, truncates to 10 digits
/// - Automatically inserts parentheses around the first 3 digits
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) {
      return const TextEditingValue(text: '');
    }

    if (text.length <= 3) {
      return newValue.copyWith(
        text: '($text',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    } else if (text.length <= 10) {
      final formatted = '(${text.substring(0, 3)})${text.substring(3)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      final truncated = text.substring(0, 10);
      final formatted = '(${truncated.substring(0, 3)})${truncated.substring(3)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaadly/core/utils/phone_number_formatter.dart';

void main() {
  group('PhoneNumberFormatter', () {
    final formatter = PhoneNumberFormatter();

    TextEditingValue fmt(String input) => formatter.formatEditUpdate(
          const TextEditingValue(text: ''),
          TextEditingValue(text: input),
        );

    test('empty input yields empty', () {
      final out = fmt('');
      expect(out.text, '');
    });

    test('formats up to 3 digits with opening paren', () {
      expect(fmt('1').text, '(1');
      expect(fmt('12').text, '(12');
      expect(fmt('123').text, '(123');
    });

    test('inserts parentheses after first 3 digits up to 10 digits', () {
      expect(fmt('1234').text, '(123)4');
      expect(fmt('1234567890').text, '(123)4567890');
    });

    test('ignores non-digits and truncates beyond 10 digits', () {
      final out = fmt('12a3-4567 890xyz');
      expect(out.text, '(123)4567890');

      final out2 = fmt('123456789012345');
      expect(out2.text, '(123)4567890');
    });
  });
}

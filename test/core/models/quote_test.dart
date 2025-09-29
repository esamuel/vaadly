import 'package:flutter_test/flutter_test.dart';
import 'package:vaadly/core/models/maintenance/quote.dart';

void main() {
  group('Quote VAT calculations', () {
    test('total includes VAT at 17%', () {
      final q = Quote(
        vendorId: 'v1',
        subtotalIls: 100.0,
        vatRate: 0.17,
        slaHours: 24,
        validUntil: DateTime.now().add(const Duration(days: 7)),
      );
      expect(q.vatAmountIls, closeTo(17.0, 1e-9));
      expect(q.totalIls, closeTo(117.0, 1e-9));
    });
  });
}

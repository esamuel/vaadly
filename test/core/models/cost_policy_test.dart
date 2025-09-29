import 'package:flutter_test/flutter_test.dart';
import 'package:vaadly/core/models/maintenance/cost_policy.dart';

void main() {
  group('CostPolicy defaults', () {
    test('default values match spec', () {
      const policy = CostPolicy();
      expect(policy.autoCompareThresholdIls, 500);
      expect(policy.minQuotes, 2);
      expect(policy.weightPrice, closeTo(0.6, 1e-9));
      expect(policy.weightRating, closeTo(0.25, 1e-9));
      expect(policy.weightSla, closeTo(0.15, 1e-9));
    });
  });
}

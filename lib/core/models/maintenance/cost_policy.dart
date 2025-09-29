import 'package:json_annotation/json_annotation.dart';

part 'cost_policy.g.dart';

@JsonSerializable(explicitToJson: true)
class CostPolicy {
  final int autoCompareThresholdIls; // e.g., 500
  final int minQuotes; // e.g., 2
  final double weightPrice; // e.g., 0.6
  final double weightRating; // e.g., 0.25
  final double weightSla; // e.g., 0.15

  const CostPolicy({
    this.autoCompareThresholdIls = 500,
    this.minQuotes = 2,
    this.weightPrice = 0.6,
    this.weightRating = 0.25,
    this.weightSla = 0.15,
  });

  factory CostPolicy.fromJson(Map<String, dynamic> json) => _$CostPolicyFromJson(json);
  Map<String, dynamic> toJson() => _$CostPolicyToJson(this);
}
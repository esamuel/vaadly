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

  factory CostPolicy.fromJson(Map<String, dynamic> json) {
    return CostPolicy(
      autoCompareThresholdIls: (json['autoCompareThresholdIls'] as num?)?.toInt() ?? 500,
      minQuotes: (json['minQuotes'] as num?)?.toInt() ?? 2,
      weightPrice: (json['weightPrice'] as num?)?.toDouble() ?? 0.6,
      weightRating: (json['weightRating'] as num?)?.toDouble() ?? 0.25,
      weightSla: (json['weightSla'] as num?)?.toDouble() ?? 0.15,
    );
  }

  Map<String, dynamic> toJson() => {
        'autoCompareThresholdIls': autoCompareThresholdIls,
        'minQuotes': minQuotes,
        'weightPrice': weightPrice,
        'weightRating': weightRating,
        'weightSla': weightSla,
      };
  }
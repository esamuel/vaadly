class Quote {
  final String vendorId;
  final double subtotalIls; // before VAT
  final double vatRate; // e.g., 0.17 for 17%
  final double slaHours;
  final DateTime validUntil;

  const Quote({
    required this.vendorId,
    required this.subtotalIls,
    required this.vatRate,
    required this.slaHours,
    required this.validUntil,
  });

  double get vatAmountIls => subtotalIls * vatRate;
  double get totalIls => subtotalIls + vatAmountIls;

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      vendorId: json['vendorId'] as String,
      subtotalIls: (json['subtotalIls'] as num).toDouble(),
      vatRate: (json['vatRate'] as num).toDouble(),
      slaHours: (json['slaHours'] as num).toDouble(),
      validUntil: DateTime.parse(json['validUntil'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'subtotalIls': subtotalIls,
      'vatRate': vatRate,
      'slaHours': slaHours,
      'validUntil': validUntil.toIso8601String(),
    };
  }
}
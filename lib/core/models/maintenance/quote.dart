import 'package:json_annotation/json_annotation.dart';

part 'quote.g.dart';

@JsonSerializable()
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

  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);
  Map<String, dynamic> toJson() => _$QuoteToJson(this);
}
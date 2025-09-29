import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';

part 'vendor_profile.g.dart';

@JsonSerializable(explicitToJson: true)
class VendorProfile {
  final String vendorId;
  final String name;
  final String contactEmail;
  final String contactPhone;
  final List<ServiceCategory> serviceCategories;
  final List<String> coverageRegions; // e.g., city codes or regions
  final double ratingAvg; // 0..5
  final int jobsDone;
  final double slaAvgHours;

  // Pricing in ILS (VAT excluded unless indicated in a quote)
  final double? calloutFeeIls;
  final double? hourlyRateIls;
  final double? minHours;

  const VendorProfile({
    required this.vendorId,
    required this.name,
    required this.contactEmail,
    required this.contactPhone,
    required this.serviceCategories,
    required this.coverageRegions,
    this.ratingAvg = 0.0,
    this.jobsDone = 0,
    this.slaAvgHours = 24.0,
    this.calloutFeeIls,
    this.hourlyRateIls,
    this.minHours,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) => _$VendorProfileFromJson(json);
  Map<String, dynamic> toJson() => _$VendorProfileToJson(this);
}
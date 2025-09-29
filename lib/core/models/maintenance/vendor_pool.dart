import 'package:json_annotation/json_annotation.dart';
import 'vendor_profile.dart';
import 'enums.dart';

part 'vendor_pool.g.dart';

@JsonSerializable(explicitToJson: true)
class VendorPool {
  final String poolId;
  final String name;
  final bool active;
  final String scope; // 'app_owner' or 'committee'
  final List<String> vendorIds;
  final List<ServiceCategory> services;

  const VendorPool({
    required this.poolId,
    required this.name,
    required this.scope,
    required this.vendorIds,
    required this.services,
    this.active = true,
  });

  factory VendorPool.fromJson(Map<String, dynamic> json) => _$VendorPoolFromJson(json);
  Map<String, dynamic> toJson() => _$VendorPoolToJson(this);
}
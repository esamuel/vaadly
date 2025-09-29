// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_pool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorPool _$VendorPoolFromJson(Map<String, dynamic> json) => VendorPool(
      poolId: json['poolId'] as String,
      name: json['name'] as String,
      scope: json['scope'] as String,
      vendorIds:
          (json['vendorIds'] as List<dynamic>).map((e) => e as String).toList(),
      services: (json['services'] as List<dynamic>)
          .map((e) => $enumDecode(_$ServiceCategoryEnumMap, e))
          .toList(),
      active: json['active'] as bool? ?? true,
    );

Map<String, dynamic> _$VendorPoolToJson(VendorPool instance) =>
    <String, dynamic>{
      'poolId': instance.poolId,
      'name': instance.name,
      'active': instance.active,
      'scope': instance.scope,
      'vendorIds': instance.vendorIds,
      'services':
          instance.services.map((e) => _$ServiceCategoryEnumMap[e]!).toList(),
    };

const _$ServiceCategoryEnumMap = {
  ServiceCategory.plumbing: 'plumbing',
  ServiceCategory.electrical: 'electrical',
  ServiceCategory.elevator: 'elevator',
  ServiceCategory.general: 'general',
  ServiceCategory.gardening: 'gardening',
  ServiceCategory.sanitation: 'sanitation',
};

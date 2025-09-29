// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorProfile _$VendorProfileFromJson(Map<String, dynamic> json) =>
    VendorProfile(
      vendorId: json['vendorId'] as String,
      name: json['name'] as String,
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String,
      serviceCategories: (json['serviceCategories'] as List<dynamic>)
          .map((e) => $enumDecode(_$ServiceCategoryEnumMap, e))
          .toList(),
      coverageRegions: (json['coverageRegions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      jobsDone: (json['jobsDone'] as num?)?.toInt() ?? 0,
      slaAvgHours: (json['slaAvgHours'] as num?)?.toDouble() ?? 24.0,
      calloutFeeIls: (json['calloutFeeIls'] as num?)?.toDouble(),
      hourlyRateIls: (json['hourlyRateIls'] as num?)?.toDouble(),
      minHours: (json['minHours'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$VendorProfileToJson(VendorProfile instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'name': instance.name,
      'contactEmail': instance.contactEmail,
      'contactPhone': instance.contactPhone,
      'serviceCategories': instance.serviceCategories
          .map((e) => _$ServiceCategoryEnumMap[e]!)
          .toList(),
      'coverageRegions': instance.coverageRegions,
      'ratingAvg': instance.ratingAvg,
      'jobsDone': instance.jobsDone,
      'slaAvgHours': instance.slaAvgHours,
      'calloutFeeIls': instance.calloutFeeIls,
      'hourlyRateIls': instance.hourlyRateIls,
      'minHours': instance.minHours,
    };

const _$ServiceCategoryEnumMap = {
  ServiceCategory.plumbing: 'plumbing',
  ServiceCategory.electrical: 'electrical',
  ServiceCategory.elevator: 'elevator',
  ServiceCategory.general: 'general',
  ServiceCategory.gardening: 'gardening',
  ServiceCategory.sanitation: 'sanitation',
};

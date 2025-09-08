// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricing_calculator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PricingRequestImpl _$$PricingRequestImplFromJson(Map<String, dynamic> json) =>
    _$PricingRequestImpl(
      buildingId: json['buildingId'] as String,
      buildingProfile: BuildingProfile.fromJson(
          json['buildingProfile'] as Map<String, dynamic>),
      serviceTier: $enumDecode(_$ServiceTierEnumMap, json['serviceTier']),
      contractDuration:
          $enumDecode(_$ContractDurationEnumMap, json['contractDuration']),
      additionalServices: (json['additionalServices'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PricingRequestImplToJson(
        _$PricingRequestImpl instance) =>
    <String, dynamic>{
      'buildingId': instance.buildingId,
      'buildingProfile': instance.buildingProfile,
      'serviceTier': _$ServiceTierEnumMap[instance.serviceTier]!,
      'contractDuration': _$ContractDurationEnumMap[instance.contractDuration]!,
      'additionalServices': instance.additionalServices,
    };

const _$ServiceTierEnumMap = {
  ServiceTier.basic: 'basic',
  ServiceTier.standard: 'standard',
  ServiceTier.premium: 'premium',
  ServiceTier.enterprise: 'enterprise',
};

const _$ContractDurationEnumMap = {
  ContractDuration.monthly: 'monthly',
  ContractDuration.quarterly: 'quarterly',
  ContractDuration.semiAnnual: 'semi_annual',
  ContractDuration.annual: 'annual',
  ContractDuration.multiYear: 'multi_year',
};

_$BuildingProfileImpl _$$BuildingProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$BuildingProfileImpl(
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String,
      neighborhood: json['neighborhood'] as String,
      totalFloors: (json['totalFloors'] as num).toInt(),
      totalApartments: (json['totalApartments'] as num).toInt(),
      apartmentsPerFloor: (json['apartmentsPerFloor'] as num).toInt(),
      buildingAge: (json['buildingAge'] as num).toInt(),
      buildingType: $enumDecode(_$BuildingTypeEnumMap, json['buildingType']),
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$BuildingAmenityEnumMap, e))
              .toList() ??
          const [],
      parkingSpaces: (json['parkingSpaces'] as num?)?.toDouble(),
      gardenArea: (json['gardenArea'] as num?)?.toDouble(),
      hasElevator: json['hasElevator'] as bool?,
      hasStorage: json['hasStorage'] as bool?,
      hasBalconies: json['hasBalconies'] as bool?,
    );

Map<String, dynamic> _$$BuildingProfileImplToJson(
        _$BuildingProfileImpl instance) =>
    <String, dynamic>{
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'city': instance.city,
      'neighborhood': instance.neighborhood,
      'totalFloors': instance.totalFloors,
      'totalApartments': instance.totalApartments,
      'apartmentsPerFloor': instance.apartmentsPerFloor,
      'buildingAge': instance.buildingAge,
      'buildingType': _$BuildingTypeEnumMap[instance.buildingType]!,
      'amenities':
          instance.amenities.map((e) => _$BuildingAmenityEnumMap[e]!).toList(),
      'parkingSpaces': instance.parkingSpaces,
      'gardenArea': instance.gardenArea,
      'hasElevator': instance.hasElevator,
      'hasStorage': instance.hasStorage,
      'hasBalconies': instance.hasBalconies,
    };

const _$BuildingTypeEnumMap = {
  BuildingType.residential: 'residential',
  BuildingType.commercial: 'commercial',
  BuildingType.mixedUse: 'mixed_use',
  BuildingType.luxury: 'luxury',
  BuildingType.studentHousing: 'student_housing',
};

const _$BuildingAmenityEnumMap = {
  BuildingAmenity.elevator: 'elevator',
  BuildingAmenity.parkingGarage: 'parking_garage',
  BuildingAmenity.swimmingPool: 'swimming_pool',
  BuildingAmenity.gym: 'gym',
  BuildingAmenity.garden: 'garden',
  BuildingAmenity.securitySystem: 'security_system',
  BuildingAmenity.intercom: 'intercom',
  BuildingAmenity.storageRooms: 'storage_rooms',
  BuildingAmenity.balconies: 'balconies',
  BuildingAmenity.airConditioning: 'air_conditioning',
  BuildingAmenity.solarPanels: 'solar_panels',
  BuildingAmenity.wheelchairAccess: 'wheelchair_access',
};

_$PricingResultImpl _$$PricingResultImplFromJson(Map<String, dynamic> json) =>
    _$PricingResultImpl(
      basePrice: (json['basePrice'] as num).toDouble(),
      locationMultiplier: (json['locationMultiplier'] as num).toDouble(),
      complexityMultiplier: (json['complexityMultiplier'] as num).toDouble(),
      serviceTierMultiplier: (json['serviceTierMultiplier'] as num).toDouble(),
      contractMultiplier: (json['contractMultiplier'] as num).toDouble(),
      additionalServicesPrice:
          (json['additionalServicesPrice'] as num).toDouble(),
      finalPrice: (json['finalPrice'] as num).toDouble(),
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      breakdown:
          PricingBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$$PricingResultImplToJson(_$PricingResultImpl instance) =>
    <String, dynamic>{
      'basePrice': instance.basePrice,
      'locationMultiplier': instance.locationMultiplier,
      'complexityMultiplier': instance.complexityMultiplier,
      'serviceTierMultiplier': instance.serviceTierMultiplier,
      'contractMultiplier': instance.contractMultiplier,
      'additionalServicesPrice': instance.additionalServicesPrice,
      'finalPrice': instance.finalPrice,
      'monthlyPrice': instance.monthlyPrice,
      'breakdown': instance.breakdown,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
      'currency': instance.currency,
    };

_$PricingBreakdownImpl _$$PricingBreakdownImplFromJson(
        Map<String, dynamic> json) =>
    _$PricingBreakdownImpl(
      locationPricing: LocationPricing.fromJson(
          json['locationPricing'] as Map<String, dynamic>),
      complexityScoring: ComplexityScoring.fromJson(
          json['complexityScoring'] as Map<String, dynamic>),
      servicePricing: ServicePricing.fromJson(
          json['servicePricing'] as Map<String, dynamic>),
      additionalServicesPricing:
          (json['additionalServicesPricing'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$$PricingBreakdownImplToJson(
        _$PricingBreakdownImpl instance) =>
    <String, dynamic>{
      'locationPricing': instance.locationPricing,
      'complexityScoring': instance.complexityScoring,
      'servicePricing': instance.servicePricing,
      'additionalServicesPricing': instance.additionalServicesPricing,
    };

_$LocationPricingImpl _$$LocationPricingImplFromJson(
        Map<String, dynamic> json) =>
    _$LocationPricingImpl(
      city: json['city'] as String,
      neighborhood: json['neighborhood'] as String,
      cityMultiplier: (json['cityMultiplier'] as num).toDouble(),
      neighborhoodMultiplier:
          (json['neighborhoodMultiplier'] as num).toDouble(),
      priceZone: json['priceZone'] as String,
      explanation: json['explanation'] as String,
    );

Map<String, dynamic> _$$LocationPricingImplToJson(
        _$LocationPricingImpl instance) =>
    <String, dynamic>{
      'city': instance.city,
      'neighborhood': instance.neighborhood,
      'cityMultiplier': instance.cityMultiplier,
      'neighborhoodMultiplier': instance.neighborhoodMultiplier,
      'priceZone': instance.priceZone,
      'explanation': instance.explanation,
    };

_$ComplexityScoringImpl _$$ComplexityScoringImplFromJson(
        Map<String, dynamic> json) =>
    _$ComplexityScoringImpl(
      floorScore: (json['floorScore'] as num).toDouble(),
      apartmentScore: (json['apartmentScore'] as num).toDouble(),
      ageScore: (json['ageScore'] as num).toDouble(),
      amenityScore: (json['amenityScore'] as num).toDouble(),
      totalComplexityScore: (json['totalComplexityScore'] as num).toDouble(),
      explanation: json['explanation'] as String,
    );

Map<String, dynamic> _$$ComplexityScoringImplToJson(
        _$ComplexityScoringImpl instance) =>
    <String, dynamic>{
      'floorScore': instance.floorScore,
      'apartmentScore': instance.apartmentScore,
      'ageScore': instance.ageScore,
      'amenityScore': instance.amenityScore,
      'totalComplexityScore': instance.totalComplexityScore,
      'explanation': instance.explanation,
    };

_$ServicePricingImpl _$$ServicePricingImplFromJson(Map<String, dynamic> json) =>
    _$ServicePricingImpl(
      tier: $enumDecode(_$ServiceTierEnumMap, json['tier']),
      multiplier: (json['multiplier'] as num).toDouble(),
      includedServices: (json['includedServices'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$$ServicePricingImplToJson(
        _$ServicePricingImpl instance) =>
    <String, dynamic>{
      'tier': _$ServiceTierEnumMap[instance.tier]!,
      'multiplier': instance.multiplier,
      'includedServices': instance.includedServices,
      'description': instance.description,
    };

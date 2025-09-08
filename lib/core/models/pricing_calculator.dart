import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricing_calculator.freezed.dart';
part 'pricing_calculator.g.dart';

@freezed
class PricingRequest with _$PricingRequest {
  const factory PricingRequest({
    required String buildingId,
    required BuildingProfile buildingProfile,
    required ServiceTier serviceTier,
    required ContractDuration contractDuration,
    @Default([]) List<String> additionalServices,
  }) = _PricingRequest;

  factory PricingRequest.fromJson(Map<String, dynamic> json) =>
      _$PricingRequestFromJson(json);
}

@freezed
class BuildingProfile with _$BuildingProfile {
  const factory BuildingProfile({
    required String address,
    required double latitude,
    required double longitude,
    required String city,
    required String neighborhood,
    required int totalFloors,
    required int totalApartments,
    required int apartmentsPerFloor,
    required int buildingAge,
    required BuildingType buildingType,
    @Default([]) List<BuildingAmenity> amenities,
    double? parkingSpaces,
    double? gardenArea,
    bool? hasElevator,
    bool? hasStorage,
    bool? hasBalconies,
  }) = _BuildingProfile;

  factory BuildingProfile.fromJson(Map<String, dynamic> json) =>
      _$BuildingProfileFromJson(json);
}

@freezed
class PricingResult with _$PricingResult {
  const factory PricingResult({
    required double basePrice,
    required double locationMultiplier,
    required double complexityMultiplier,
    required double serviceTierMultiplier,
    required double contractMultiplier,
    required double additionalServicesPrice,
    required double finalPrice,
    required double monthlyPrice,
    required PricingBreakdown breakdown,
    required DateTime calculatedAt,
    required String currency,
  }) = _PricingResult;

  factory PricingResult.fromJson(Map<String, dynamic> json) =>
      _$PricingResultFromJson(json);
}

@freezed
class PricingBreakdown with _$PricingBreakdown {
  const factory PricingBreakdown({
    required LocationPricing locationPricing,
    required ComplexityScoring complexityScoring,
    required ServicePricing servicePricing,
    required Map<String, double> additionalServicesPricing,
  }) = _PricingBreakdown;

  factory PricingBreakdown.fromJson(Map<String, dynamic> json) =>
      _$PricingBreakdownFromJson(json);
}

@freezed
class LocationPricing with _$LocationPricing {
  const factory LocationPricing({
    required String city,
    required String neighborhood,
    required double cityMultiplier,
    required double neighborhoodMultiplier,
    required String priceZone,
    required String explanation,
  }) = _LocationPricing;

  factory LocationPricing.fromJson(Map<String, dynamic> json) =>
      _$LocationPricingFromJson(json);
}

@freezed
class ComplexityScoring with _$ComplexityScoring {
  const factory ComplexityScoring({
    required double floorScore,
    required double apartmentScore,
    required double ageScore,
    required double amenityScore,
    required double totalComplexityScore,
    required String explanation,
  }) = _ComplexityScoring;

  factory ComplexityScoring.fromJson(Map<String, dynamic> json) =>
      _$ComplexityScoringFromJson(json);
}

@freezed
class ServicePricing with _$ServicePricing {
  const factory ServicePricing({
    required ServiceTier tier,
    required double multiplier,
    required List<String> includedServices,
    required String description,
  }) = _ServicePricing;

  factory ServicePricing.fromJson(Map<String, dynamic> json) =>
      _$ServicePricingFromJson(json);
}

enum ServiceTier {
  @JsonValue('basic')
  basic,
  @JsonValue('standard')
  standard,
  @JsonValue('premium')
  premium,
  @JsonValue('enterprise')
  enterprise,
}

enum ContractDuration {
  @JsonValue('monthly')
  monthly,
  @JsonValue('quarterly')
  quarterly,
  @JsonValue('semi_annual')
  semiAnnual,
  @JsonValue('annual')
  annual,
  @JsonValue('multi_year')
  multiYear,
}

enum BuildingType {
  @JsonValue('residential')
  residential,
  @JsonValue('commercial')
  commercial,
  @JsonValue('mixed_use')
  mixedUse,
  @JsonValue('luxury')
  luxury,
  @JsonValue('student_housing')
  studentHousing,
}

enum BuildingAmenity {
  @JsonValue('elevator')
  elevator,
  @JsonValue('parking_garage')
  parkingGarage,
  @JsonValue('swimming_pool')
  swimmingPool,
  @JsonValue('gym')
  gym,
  @JsonValue('garden')
  garden,
  @JsonValue('security_system')
  securitySystem,
  @JsonValue('intercom')
  intercom,
  @JsonValue('storage_rooms')
  storageRooms,
  @JsonValue('balconies')
  balconies,
  @JsonValue('air_conditioning')
  airConditioning,
  @JsonValue('solar_panels')
  solarPanels,
  @JsonValue('wheelchair_access')
  wheelchairAccess,
}

// Extension methods for Hebrew translations
extension ServiceTierExtension on ServiceTier {
  String get hebrewName {
    switch (this) {
      case ServiceTier.basic:
        return 'בסיסי';
      case ServiceTier.standard:
        return 'סטנדרטי';
      case ServiceTier.premium:
        return 'פרימיום';
      case ServiceTier.enterprise:
        return 'ארגוני';
    }
  }

  String get description {
    switch (this) {
      case ServiceTier.basic:
        return 'שירותי ניהול בסיסיים - תחזוקה שוטפת, ניהול תקציב, תיאום עם ספקים';
      case ServiceTier.standard:
        return 'חבילה מלאה - כל השירותים הבסיסיים + דוחות חודשיים, מעקב אחר חובות';
      case ServiceTier.premium:
        return 'שירות מקסימלי - כל השירותים + זמינות 24/7, ניהול פרויקטים מיוחדים';
      case ServiceTier.enterprise:
        return 'פתרון ארגוני - ניהול מתקדם למספר בניינים עם מנהל חשבון יעודי';
    }
  }
}

extension ContractDurationExtension on ContractDuration {
  String get hebrewName {
    switch (this) {
      case ContractDuration.monthly:
        return 'חודשי';
      case ContractDuration.quarterly:
        return 'רבעוני';
      case ContractDuration.semiAnnual:
        return 'חצי שנתי';
      case ContractDuration.annual:
        return 'שנתי';
      case ContractDuration.multiYear:
        return 'רב שנתי';
    }
  }

  double get discountMultiplier {
    switch (this) {
      case ContractDuration.monthly:
        return 1.0;
      case ContractDuration.quarterly:
        return 0.95;
      case ContractDuration.semiAnnual:
        return 0.90;
      case ContractDuration.annual:
        return 0.85;
      case ContractDuration.multiYear:
        return 0.80;
    }
  }
}

extension BuildingAmenityExtension on BuildingAmenity {
  String get hebrewName {
    switch (this) {
      case BuildingAmenity.elevator:
        return 'מעלית';
      case BuildingAmenity.parkingGarage:
        return 'חניון';
      case BuildingAmenity.swimmingPool:
        return 'בריכת שחייה';
      case BuildingAmenity.gym:
        return 'חדר כושר';
      case BuildingAmenity.garden:
        return 'גינה';
      case BuildingAmenity.securitySystem:
        return 'מערכת אבטחה';
      case BuildingAmenity.intercom:
        return 'אינטרקום';
      case BuildingAmenity.storageRooms:
        return 'מחסנים';
      case BuildingAmenity.balconies:
        return 'מרפסות';
      case BuildingAmenity.airConditioning:
        return 'מיזוג אוויר';
      case BuildingAmenity.solarPanels:
        return 'פאנלים סולאריים';
      case BuildingAmenity.wheelchairAccess:
        return 'נגישות לכיסאות גלגלים';
    }
  }

  double get complexityMultiplier {
    switch (this) {
      case BuildingAmenity.elevator:
        return 0.15;
      case BuildingAmenity.parkingGarage:
        return 0.10;
      case BuildingAmenity.swimmingPool:
        return 0.25;
      case BuildingAmenity.gym:
        return 0.20;
      case BuildingAmenity.garden:
        return 0.12;
      case BuildingAmenity.securitySystem:
        return 0.18;
      case BuildingAmenity.intercom:
        return 0.05;
      case BuildingAmenity.storageRooms:
        return 0.08;
      case BuildingAmenity.balconies:
        return 0.03;
      case BuildingAmenity.airConditioning:
        return 0.10;
      case BuildingAmenity.solarPanels:
        return 0.15;
      case BuildingAmenity.wheelchairAccess:
        return 0.10;
    }
  }
}
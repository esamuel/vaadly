// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pricing_calculator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PricingRequest _$PricingRequestFromJson(Map<String, dynamic> json) {
  return _PricingRequest.fromJson(json);
}

/// @nodoc
mixin _$PricingRequest {
  String get buildingId => throw _privateConstructorUsedError;
  BuildingProfile get buildingProfile => throw _privateConstructorUsedError;
  ServiceTier get serviceTier => throw _privateConstructorUsedError;
  ContractDuration get contractDuration => throw _privateConstructorUsedError;
  List<String> get additionalServices => throw _privateConstructorUsedError;

  /// Serializes this PricingRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PricingRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PricingRequestCopyWith<PricingRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PricingRequestCopyWith<$Res> {
  factory $PricingRequestCopyWith(
          PricingRequest value, $Res Function(PricingRequest) then) =
      _$PricingRequestCopyWithImpl<$Res, PricingRequest>;
  @useResult
  $Res call(
      {String buildingId,
      BuildingProfile buildingProfile,
      ServiceTier serviceTier,
      ContractDuration contractDuration,
      List<String> additionalServices});

  $BuildingProfileCopyWith<$Res> get buildingProfile;
}

/// @nodoc
class _$PricingRequestCopyWithImpl<$Res, $Val extends PricingRequest>
    implements $PricingRequestCopyWith<$Res> {
  _$PricingRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PricingRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? buildingId = null,
    Object? buildingProfile = null,
    Object? serviceTier = null,
    Object? contractDuration = null,
    Object? additionalServices = null,
  }) {
    return _then(_value.copyWith(
      buildingId: null == buildingId
          ? _value.buildingId
          : buildingId // ignore: cast_nullable_to_non_nullable
              as String,
      buildingProfile: null == buildingProfile
          ? _value.buildingProfile
          : buildingProfile // ignore: cast_nullable_to_non_nullable
              as BuildingProfile,
      serviceTier: null == serviceTier
          ? _value.serviceTier
          : serviceTier // ignore: cast_nullable_to_non_nullable
              as ServiceTier,
      contractDuration: null == contractDuration
          ? _value.contractDuration
          : contractDuration // ignore: cast_nullable_to_non_nullable
              as ContractDuration,
      additionalServices: null == additionalServices
          ? _value.additionalServices
          : additionalServices // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of PricingRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BuildingProfileCopyWith<$Res> get buildingProfile {
    return $BuildingProfileCopyWith<$Res>(_value.buildingProfile, (value) {
      return _then(_value.copyWith(buildingProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PricingRequestImplCopyWith<$Res>
    implements $PricingRequestCopyWith<$Res> {
  factory _$$PricingRequestImplCopyWith(_$PricingRequestImpl value,
          $Res Function(_$PricingRequestImpl) then) =
      __$$PricingRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String buildingId,
      BuildingProfile buildingProfile,
      ServiceTier serviceTier,
      ContractDuration contractDuration,
      List<String> additionalServices});

  @override
  $BuildingProfileCopyWith<$Res> get buildingProfile;
}

/// @nodoc
class __$$PricingRequestImplCopyWithImpl<$Res>
    extends _$PricingRequestCopyWithImpl<$Res, _$PricingRequestImpl>
    implements _$$PricingRequestImplCopyWith<$Res> {
  __$$PricingRequestImplCopyWithImpl(
      _$PricingRequestImpl _value, $Res Function(_$PricingRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of PricingRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? buildingId = null,
    Object? buildingProfile = null,
    Object? serviceTier = null,
    Object? contractDuration = null,
    Object? additionalServices = null,
  }) {
    return _then(_$PricingRequestImpl(
      buildingId: null == buildingId
          ? _value.buildingId
          : buildingId // ignore: cast_nullable_to_non_nullable
              as String,
      buildingProfile: null == buildingProfile
          ? _value.buildingProfile
          : buildingProfile // ignore: cast_nullable_to_non_nullable
              as BuildingProfile,
      serviceTier: null == serviceTier
          ? _value.serviceTier
          : serviceTier // ignore: cast_nullable_to_non_nullable
              as ServiceTier,
      contractDuration: null == contractDuration
          ? _value.contractDuration
          : contractDuration // ignore: cast_nullable_to_non_nullable
              as ContractDuration,
      additionalServices: null == additionalServices
          ? _value._additionalServices
          : additionalServices // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PricingRequestImpl implements _PricingRequest {
  const _$PricingRequestImpl(
      {required this.buildingId,
      required this.buildingProfile,
      required this.serviceTier,
      required this.contractDuration,
      final List<String> additionalServices = const []})
      : _additionalServices = additionalServices;

  factory _$PricingRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$PricingRequestImplFromJson(json);

  @override
  final String buildingId;
  @override
  final BuildingProfile buildingProfile;
  @override
  final ServiceTier serviceTier;
  @override
  final ContractDuration contractDuration;
  final List<String> _additionalServices;
  @override
  @JsonKey()
  List<String> get additionalServices {
    if (_additionalServices is EqualUnmodifiableListView)
      return _additionalServices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_additionalServices);
  }

  @override
  String toString() {
    return 'PricingRequest(buildingId: $buildingId, buildingProfile: $buildingProfile, serviceTier: $serviceTier, contractDuration: $contractDuration, additionalServices: $additionalServices)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PricingRequestImpl &&
            (identical(other.buildingId, buildingId) ||
                other.buildingId == buildingId) &&
            (identical(other.buildingProfile, buildingProfile) ||
                other.buildingProfile == buildingProfile) &&
            (identical(other.serviceTier, serviceTier) ||
                other.serviceTier == serviceTier) &&
            (identical(other.contractDuration, contractDuration) ||
                other.contractDuration == contractDuration) &&
            const DeepCollectionEquality()
                .equals(other._additionalServices, _additionalServices));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      buildingId,
      buildingProfile,
      serviceTier,
      contractDuration,
      const DeepCollectionEquality().hash(_additionalServices));

  /// Create a copy of PricingRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PricingRequestImplCopyWith<_$PricingRequestImpl> get copyWith =>
      __$$PricingRequestImplCopyWithImpl<_$PricingRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PricingRequestImplToJson(
      this,
    );
  }
}

abstract class _PricingRequest implements PricingRequest {
  const factory _PricingRequest(
      {required final String buildingId,
      required final BuildingProfile buildingProfile,
      required final ServiceTier serviceTier,
      required final ContractDuration contractDuration,
      final List<String> additionalServices}) = _$PricingRequestImpl;

  factory _PricingRequest.fromJson(Map<String, dynamic> json) =
      _$PricingRequestImpl.fromJson;

  @override
  String get buildingId;
  @override
  BuildingProfile get buildingProfile;
  @override
  ServiceTier get serviceTier;
  @override
  ContractDuration get contractDuration;
  @override
  List<String> get additionalServices;

  /// Create a copy of PricingRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PricingRequestImplCopyWith<_$PricingRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BuildingProfile _$BuildingProfileFromJson(Map<String, dynamic> json) {
  return _BuildingProfile.fromJson(json);
}

/// @nodoc
mixin _$BuildingProfile {
  String get address => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get neighborhood => throw _privateConstructorUsedError;
  int get totalFloors => throw _privateConstructorUsedError;
  int get totalApartments => throw _privateConstructorUsedError;
  int get apartmentsPerFloor => throw _privateConstructorUsedError;
  int get buildingAge => throw _privateConstructorUsedError;
  BuildingType get buildingType => throw _privateConstructorUsedError;
  List<BuildingAmenity> get amenities => throw _privateConstructorUsedError;
  double? get parkingSpaces => throw _privateConstructorUsedError;
  double? get gardenArea => throw _privateConstructorUsedError;
  bool? get hasElevator => throw _privateConstructorUsedError;
  bool? get hasStorage => throw _privateConstructorUsedError;
  bool? get hasBalconies => throw _privateConstructorUsedError;

  /// Serializes this BuildingProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BuildingProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BuildingProfileCopyWith<BuildingProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BuildingProfileCopyWith<$Res> {
  factory $BuildingProfileCopyWith(
          BuildingProfile value, $Res Function(BuildingProfile) then) =
      _$BuildingProfileCopyWithImpl<$Res, BuildingProfile>;
  @useResult
  $Res call(
      {String address,
      double latitude,
      double longitude,
      String city,
      String neighborhood,
      int totalFloors,
      int totalApartments,
      int apartmentsPerFloor,
      int buildingAge,
      BuildingType buildingType,
      List<BuildingAmenity> amenities,
      double? parkingSpaces,
      double? gardenArea,
      bool? hasElevator,
      bool? hasStorage,
      bool? hasBalconies});
}

/// @nodoc
class _$BuildingProfileCopyWithImpl<$Res, $Val extends BuildingProfile>
    implements $BuildingProfileCopyWith<$Res> {
  _$BuildingProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BuildingProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? city = null,
    Object? neighborhood = null,
    Object? totalFloors = null,
    Object? totalApartments = null,
    Object? apartmentsPerFloor = null,
    Object? buildingAge = null,
    Object? buildingType = null,
    Object? amenities = null,
    Object? parkingSpaces = freezed,
    Object? gardenArea = freezed,
    Object? hasElevator = freezed,
    Object? hasStorage = freezed,
    Object? hasBalconies = freezed,
  }) {
    return _then(_value.copyWith(
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      neighborhood: null == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String,
      totalFloors: null == totalFloors
          ? _value.totalFloors
          : totalFloors // ignore: cast_nullable_to_non_nullable
              as int,
      totalApartments: null == totalApartments
          ? _value.totalApartments
          : totalApartments // ignore: cast_nullable_to_non_nullable
              as int,
      apartmentsPerFloor: null == apartmentsPerFloor
          ? _value.apartmentsPerFloor
          : apartmentsPerFloor // ignore: cast_nullable_to_non_nullable
              as int,
      buildingAge: null == buildingAge
          ? _value.buildingAge
          : buildingAge // ignore: cast_nullable_to_non_nullable
              as int,
      buildingType: null == buildingType
          ? _value.buildingType
          : buildingType // ignore: cast_nullable_to_non_nullable
              as BuildingType,
      amenities: null == amenities
          ? _value.amenities
          : amenities // ignore: cast_nullable_to_non_nullable
              as List<BuildingAmenity>,
      parkingSpaces: freezed == parkingSpaces
          ? _value.parkingSpaces
          : parkingSpaces // ignore: cast_nullable_to_non_nullable
              as double?,
      gardenArea: freezed == gardenArea
          ? _value.gardenArea
          : gardenArea // ignore: cast_nullable_to_non_nullable
              as double?,
      hasElevator: freezed == hasElevator
          ? _value.hasElevator
          : hasElevator // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasStorage: freezed == hasStorage
          ? _value.hasStorage
          : hasStorage // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasBalconies: freezed == hasBalconies
          ? _value.hasBalconies
          : hasBalconies // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BuildingProfileImplCopyWith<$Res>
    implements $BuildingProfileCopyWith<$Res> {
  factory _$$BuildingProfileImplCopyWith(_$BuildingProfileImpl value,
          $Res Function(_$BuildingProfileImpl) then) =
      __$$BuildingProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String address,
      double latitude,
      double longitude,
      String city,
      String neighborhood,
      int totalFloors,
      int totalApartments,
      int apartmentsPerFloor,
      int buildingAge,
      BuildingType buildingType,
      List<BuildingAmenity> amenities,
      double? parkingSpaces,
      double? gardenArea,
      bool? hasElevator,
      bool? hasStorage,
      bool? hasBalconies});
}

/// @nodoc
class __$$BuildingProfileImplCopyWithImpl<$Res>
    extends _$BuildingProfileCopyWithImpl<$Res, _$BuildingProfileImpl>
    implements _$$BuildingProfileImplCopyWith<$Res> {
  __$$BuildingProfileImplCopyWithImpl(
      _$BuildingProfileImpl _value, $Res Function(_$BuildingProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of BuildingProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? city = null,
    Object? neighborhood = null,
    Object? totalFloors = null,
    Object? totalApartments = null,
    Object? apartmentsPerFloor = null,
    Object? buildingAge = null,
    Object? buildingType = null,
    Object? amenities = null,
    Object? parkingSpaces = freezed,
    Object? gardenArea = freezed,
    Object? hasElevator = freezed,
    Object? hasStorage = freezed,
    Object? hasBalconies = freezed,
  }) {
    return _then(_$BuildingProfileImpl(
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      neighborhood: null == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String,
      totalFloors: null == totalFloors
          ? _value.totalFloors
          : totalFloors // ignore: cast_nullable_to_non_nullable
              as int,
      totalApartments: null == totalApartments
          ? _value.totalApartments
          : totalApartments // ignore: cast_nullable_to_non_nullable
              as int,
      apartmentsPerFloor: null == apartmentsPerFloor
          ? _value.apartmentsPerFloor
          : apartmentsPerFloor // ignore: cast_nullable_to_non_nullable
              as int,
      buildingAge: null == buildingAge
          ? _value.buildingAge
          : buildingAge // ignore: cast_nullable_to_non_nullable
              as int,
      buildingType: null == buildingType
          ? _value.buildingType
          : buildingType // ignore: cast_nullable_to_non_nullable
              as BuildingType,
      amenities: null == amenities
          ? _value._amenities
          : amenities // ignore: cast_nullable_to_non_nullable
              as List<BuildingAmenity>,
      parkingSpaces: freezed == parkingSpaces
          ? _value.parkingSpaces
          : parkingSpaces // ignore: cast_nullable_to_non_nullable
              as double?,
      gardenArea: freezed == gardenArea
          ? _value.gardenArea
          : gardenArea // ignore: cast_nullable_to_non_nullable
              as double?,
      hasElevator: freezed == hasElevator
          ? _value.hasElevator
          : hasElevator // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasStorage: freezed == hasStorage
          ? _value.hasStorage
          : hasStorage // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasBalconies: freezed == hasBalconies
          ? _value.hasBalconies
          : hasBalconies // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BuildingProfileImpl implements _BuildingProfile {
  const _$BuildingProfileImpl(
      {required this.address,
      required this.latitude,
      required this.longitude,
      required this.city,
      required this.neighborhood,
      required this.totalFloors,
      required this.totalApartments,
      required this.apartmentsPerFloor,
      required this.buildingAge,
      required this.buildingType,
      final List<BuildingAmenity> amenities = const [],
      this.parkingSpaces,
      this.gardenArea,
      this.hasElevator,
      this.hasStorage,
      this.hasBalconies})
      : _amenities = amenities;

  factory _$BuildingProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$BuildingProfileImplFromJson(json);

  @override
  final String address;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String city;
  @override
  final String neighborhood;
  @override
  final int totalFloors;
  @override
  final int totalApartments;
  @override
  final int apartmentsPerFloor;
  @override
  final int buildingAge;
  @override
  final BuildingType buildingType;
  final List<BuildingAmenity> _amenities;
  @override
  @JsonKey()
  List<BuildingAmenity> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

  @override
  final double? parkingSpaces;
  @override
  final double? gardenArea;
  @override
  final bool? hasElevator;
  @override
  final bool? hasStorage;
  @override
  final bool? hasBalconies;

  @override
  String toString() {
    return 'BuildingProfile(address: $address, latitude: $latitude, longitude: $longitude, city: $city, neighborhood: $neighborhood, totalFloors: $totalFloors, totalApartments: $totalApartments, apartmentsPerFloor: $apartmentsPerFloor, buildingAge: $buildingAge, buildingType: $buildingType, amenities: $amenities, parkingSpaces: $parkingSpaces, gardenArea: $gardenArea, hasElevator: $hasElevator, hasStorage: $hasStorage, hasBalconies: $hasBalconies)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BuildingProfileImpl &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.neighborhood, neighborhood) ||
                other.neighborhood == neighborhood) &&
            (identical(other.totalFloors, totalFloors) ||
                other.totalFloors == totalFloors) &&
            (identical(other.totalApartments, totalApartments) ||
                other.totalApartments == totalApartments) &&
            (identical(other.apartmentsPerFloor, apartmentsPerFloor) ||
                other.apartmentsPerFloor == apartmentsPerFloor) &&
            (identical(other.buildingAge, buildingAge) ||
                other.buildingAge == buildingAge) &&
            (identical(other.buildingType, buildingType) ||
                other.buildingType == buildingType) &&
            const DeepCollectionEquality()
                .equals(other._amenities, _amenities) &&
            (identical(other.parkingSpaces, parkingSpaces) ||
                other.parkingSpaces == parkingSpaces) &&
            (identical(other.gardenArea, gardenArea) ||
                other.gardenArea == gardenArea) &&
            (identical(other.hasElevator, hasElevator) ||
                other.hasElevator == hasElevator) &&
            (identical(other.hasStorage, hasStorage) ||
                other.hasStorage == hasStorage) &&
            (identical(other.hasBalconies, hasBalconies) ||
                other.hasBalconies == hasBalconies));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      address,
      latitude,
      longitude,
      city,
      neighborhood,
      totalFloors,
      totalApartments,
      apartmentsPerFloor,
      buildingAge,
      buildingType,
      const DeepCollectionEquality().hash(_amenities),
      parkingSpaces,
      gardenArea,
      hasElevator,
      hasStorage,
      hasBalconies);

  /// Create a copy of BuildingProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BuildingProfileImplCopyWith<_$BuildingProfileImpl> get copyWith =>
      __$$BuildingProfileImplCopyWithImpl<_$BuildingProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BuildingProfileImplToJson(
      this,
    );
  }
}

abstract class _BuildingProfile implements BuildingProfile {
  const factory _BuildingProfile(
      {required final String address,
      required final double latitude,
      required final double longitude,
      required final String city,
      required final String neighborhood,
      required final int totalFloors,
      required final int totalApartments,
      required final int apartmentsPerFloor,
      required final int buildingAge,
      required final BuildingType buildingType,
      final List<BuildingAmenity> amenities,
      final double? parkingSpaces,
      final double? gardenArea,
      final bool? hasElevator,
      final bool? hasStorage,
      final bool? hasBalconies}) = _$BuildingProfileImpl;

  factory _BuildingProfile.fromJson(Map<String, dynamic> json) =
      _$BuildingProfileImpl.fromJson;

  @override
  String get address;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get city;
  @override
  String get neighborhood;
  @override
  int get totalFloors;
  @override
  int get totalApartments;
  @override
  int get apartmentsPerFloor;
  @override
  int get buildingAge;
  @override
  BuildingType get buildingType;
  @override
  List<BuildingAmenity> get amenities;
  @override
  double? get parkingSpaces;
  @override
  double? get gardenArea;
  @override
  bool? get hasElevator;
  @override
  bool? get hasStorage;
  @override
  bool? get hasBalconies;

  /// Create a copy of BuildingProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BuildingProfileImplCopyWith<_$BuildingProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PricingResult _$PricingResultFromJson(Map<String, dynamic> json) {
  return _PricingResult.fromJson(json);
}

/// @nodoc
mixin _$PricingResult {
  double get basePrice => throw _privateConstructorUsedError;
  double get locationMultiplier => throw _privateConstructorUsedError;
  double get complexityMultiplier => throw _privateConstructorUsedError;
  double get serviceTierMultiplier => throw _privateConstructorUsedError;
  double get contractMultiplier => throw _privateConstructorUsedError;
  double get additionalServicesPrice => throw _privateConstructorUsedError;
  double get finalPrice => throw _privateConstructorUsedError;
  double get monthlyPrice => throw _privateConstructorUsedError;
  PricingBreakdown get breakdown => throw _privateConstructorUsedError;
  DateTime get calculatedAt => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;

  /// Serializes this PricingResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PricingResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PricingResultCopyWith<PricingResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PricingResultCopyWith<$Res> {
  factory $PricingResultCopyWith(
          PricingResult value, $Res Function(PricingResult) then) =
      _$PricingResultCopyWithImpl<$Res, PricingResult>;
  @useResult
  $Res call(
      {double basePrice,
      double locationMultiplier,
      double complexityMultiplier,
      double serviceTierMultiplier,
      double contractMultiplier,
      double additionalServicesPrice,
      double finalPrice,
      double monthlyPrice,
      PricingBreakdown breakdown,
      DateTime calculatedAt,
      String currency});

  $PricingBreakdownCopyWith<$Res> get breakdown;
}

/// @nodoc
class _$PricingResultCopyWithImpl<$Res, $Val extends PricingResult>
    implements $PricingResultCopyWith<$Res> {
  _$PricingResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PricingResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? basePrice = null,
    Object? locationMultiplier = null,
    Object? complexityMultiplier = null,
    Object? serviceTierMultiplier = null,
    Object? contractMultiplier = null,
    Object? additionalServicesPrice = null,
    Object? finalPrice = null,
    Object? monthlyPrice = null,
    Object? breakdown = null,
    Object? calculatedAt = null,
    Object? currency = null,
  }) {
    return _then(_value.copyWith(
      basePrice: null == basePrice
          ? _value.basePrice
          : basePrice // ignore: cast_nullable_to_non_nullable
              as double,
      locationMultiplier: null == locationMultiplier
          ? _value.locationMultiplier
          : locationMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      complexityMultiplier: null == complexityMultiplier
          ? _value.complexityMultiplier
          : complexityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      serviceTierMultiplier: null == serviceTierMultiplier
          ? _value.serviceTierMultiplier
          : serviceTierMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      contractMultiplier: null == contractMultiplier
          ? _value.contractMultiplier
          : contractMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      additionalServicesPrice: null == additionalServicesPrice
          ? _value.additionalServicesPrice
          : additionalServicesPrice // ignore: cast_nullable_to_non_nullable
              as double,
      finalPrice: null == finalPrice
          ? _value.finalPrice
          : finalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyPrice: null == monthlyPrice
          ? _value.monthlyPrice
          : monthlyPrice // ignore: cast_nullable_to_non_nullable
              as double,
      breakdown: null == breakdown
          ? _value.breakdown
          : breakdown // ignore: cast_nullable_to_non_nullable
              as PricingBreakdown,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of PricingResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PricingBreakdownCopyWith<$Res> get breakdown {
    return $PricingBreakdownCopyWith<$Res>(_value.breakdown, (value) {
      return _then(_value.copyWith(breakdown: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PricingResultImplCopyWith<$Res>
    implements $PricingResultCopyWith<$Res> {
  factory _$$PricingResultImplCopyWith(
          _$PricingResultImpl value, $Res Function(_$PricingResultImpl) then) =
      __$$PricingResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double basePrice,
      double locationMultiplier,
      double complexityMultiplier,
      double serviceTierMultiplier,
      double contractMultiplier,
      double additionalServicesPrice,
      double finalPrice,
      double monthlyPrice,
      PricingBreakdown breakdown,
      DateTime calculatedAt,
      String currency});

  @override
  $PricingBreakdownCopyWith<$Res> get breakdown;
}

/// @nodoc
class __$$PricingResultImplCopyWithImpl<$Res>
    extends _$PricingResultCopyWithImpl<$Res, _$PricingResultImpl>
    implements _$$PricingResultImplCopyWith<$Res> {
  __$$PricingResultImplCopyWithImpl(
      _$PricingResultImpl _value, $Res Function(_$PricingResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of PricingResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? basePrice = null,
    Object? locationMultiplier = null,
    Object? complexityMultiplier = null,
    Object? serviceTierMultiplier = null,
    Object? contractMultiplier = null,
    Object? additionalServicesPrice = null,
    Object? finalPrice = null,
    Object? monthlyPrice = null,
    Object? breakdown = null,
    Object? calculatedAt = null,
    Object? currency = null,
  }) {
    return _then(_$PricingResultImpl(
      basePrice: null == basePrice
          ? _value.basePrice
          : basePrice // ignore: cast_nullable_to_non_nullable
              as double,
      locationMultiplier: null == locationMultiplier
          ? _value.locationMultiplier
          : locationMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      complexityMultiplier: null == complexityMultiplier
          ? _value.complexityMultiplier
          : complexityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      serviceTierMultiplier: null == serviceTierMultiplier
          ? _value.serviceTierMultiplier
          : serviceTierMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      contractMultiplier: null == contractMultiplier
          ? _value.contractMultiplier
          : contractMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      additionalServicesPrice: null == additionalServicesPrice
          ? _value.additionalServicesPrice
          : additionalServicesPrice // ignore: cast_nullable_to_non_nullable
              as double,
      finalPrice: null == finalPrice
          ? _value.finalPrice
          : finalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyPrice: null == monthlyPrice
          ? _value.monthlyPrice
          : monthlyPrice // ignore: cast_nullable_to_non_nullable
              as double,
      breakdown: null == breakdown
          ? _value.breakdown
          : breakdown // ignore: cast_nullable_to_non_nullable
              as PricingBreakdown,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PricingResultImpl implements _PricingResult {
  const _$PricingResultImpl(
      {required this.basePrice,
      required this.locationMultiplier,
      required this.complexityMultiplier,
      required this.serviceTierMultiplier,
      required this.contractMultiplier,
      required this.additionalServicesPrice,
      required this.finalPrice,
      required this.monthlyPrice,
      required this.breakdown,
      required this.calculatedAt,
      required this.currency});

  factory _$PricingResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$PricingResultImplFromJson(json);

  @override
  final double basePrice;
  @override
  final double locationMultiplier;
  @override
  final double complexityMultiplier;
  @override
  final double serviceTierMultiplier;
  @override
  final double contractMultiplier;
  @override
  final double additionalServicesPrice;
  @override
  final double finalPrice;
  @override
  final double monthlyPrice;
  @override
  final PricingBreakdown breakdown;
  @override
  final DateTime calculatedAt;
  @override
  final String currency;

  @override
  String toString() {
    return 'PricingResult(basePrice: $basePrice, locationMultiplier: $locationMultiplier, complexityMultiplier: $complexityMultiplier, serviceTierMultiplier: $serviceTierMultiplier, contractMultiplier: $contractMultiplier, additionalServicesPrice: $additionalServicesPrice, finalPrice: $finalPrice, monthlyPrice: $monthlyPrice, breakdown: $breakdown, calculatedAt: $calculatedAt, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PricingResultImpl &&
            (identical(other.basePrice, basePrice) ||
                other.basePrice == basePrice) &&
            (identical(other.locationMultiplier, locationMultiplier) ||
                other.locationMultiplier == locationMultiplier) &&
            (identical(other.complexityMultiplier, complexityMultiplier) ||
                other.complexityMultiplier == complexityMultiplier) &&
            (identical(other.serviceTierMultiplier, serviceTierMultiplier) ||
                other.serviceTierMultiplier == serviceTierMultiplier) &&
            (identical(other.contractMultiplier, contractMultiplier) ||
                other.contractMultiplier == contractMultiplier) &&
            (identical(
                    other.additionalServicesPrice, additionalServicesPrice) ||
                other.additionalServicesPrice == additionalServicesPrice) &&
            (identical(other.finalPrice, finalPrice) ||
                other.finalPrice == finalPrice) &&
            (identical(other.monthlyPrice, monthlyPrice) ||
                other.monthlyPrice == monthlyPrice) &&
            (identical(other.breakdown, breakdown) ||
                other.breakdown == breakdown) &&
            (identical(other.calculatedAt, calculatedAt) ||
                other.calculatedAt == calculatedAt) &&
            (identical(other.currency, currency) ||
                other.currency == currency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      basePrice,
      locationMultiplier,
      complexityMultiplier,
      serviceTierMultiplier,
      contractMultiplier,
      additionalServicesPrice,
      finalPrice,
      monthlyPrice,
      breakdown,
      calculatedAt,
      currency);

  /// Create a copy of PricingResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PricingResultImplCopyWith<_$PricingResultImpl> get copyWith =>
      __$$PricingResultImplCopyWithImpl<_$PricingResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PricingResultImplToJson(
      this,
    );
  }
}

abstract class _PricingResult implements PricingResult {
  const factory _PricingResult(
      {required final double basePrice,
      required final double locationMultiplier,
      required final double complexityMultiplier,
      required final double serviceTierMultiplier,
      required final double contractMultiplier,
      required final double additionalServicesPrice,
      required final double finalPrice,
      required final double monthlyPrice,
      required final PricingBreakdown breakdown,
      required final DateTime calculatedAt,
      required final String currency}) = _$PricingResultImpl;

  factory _PricingResult.fromJson(Map<String, dynamic> json) =
      _$PricingResultImpl.fromJson;

  @override
  double get basePrice;
  @override
  double get locationMultiplier;
  @override
  double get complexityMultiplier;
  @override
  double get serviceTierMultiplier;
  @override
  double get contractMultiplier;
  @override
  double get additionalServicesPrice;
  @override
  double get finalPrice;
  @override
  double get monthlyPrice;
  @override
  PricingBreakdown get breakdown;
  @override
  DateTime get calculatedAt;
  @override
  String get currency;

  /// Create a copy of PricingResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PricingResultImplCopyWith<_$PricingResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PricingBreakdown _$PricingBreakdownFromJson(Map<String, dynamic> json) {
  return _PricingBreakdown.fromJson(json);
}

/// @nodoc
mixin _$PricingBreakdown {
  LocationPricing get locationPricing => throw _privateConstructorUsedError;
  ComplexityScoring get complexityScoring => throw _privateConstructorUsedError;
  ServicePricing get servicePricing => throw _privateConstructorUsedError;
  Map<String, double> get additionalServicesPricing =>
      throw _privateConstructorUsedError;

  /// Serializes this PricingBreakdown to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PricingBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PricingBreakdownCopyWith<PricingBreakdown> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PricingBreakdownCopyWith<$Res> {
  factory $PricingBreakdownCopyWith(
          PricingBreakdown value, $Res Function(PricingBreakdown) then) =
      _$PricingBreakdownCopyWithImpl<$Res, PricingBreakdown>;
  @useResult
  $Res call(
      {LocationPricing locationPricing,
      ComplexityScoring complexityScoring,
      ServicePricing servicePricing,
      Map<String, double> additionalServicesPricing});

  $LocationPricingCopyWith<$Res> get locationPricing;
  $ComplexityScoringCopyWith<$Res> get complexityScoring;
  $ServicePricingCopyWith<$Res> get servicePricing;
}

/// @nodoc
class _$PricingBreakdownCopyWithImpl<$Res, $Val extends PricingBreakdown>
    implements $PricingBreakdownCopyWith<$Res> {
  _$PricingBreakdownCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PricingBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? locationPricing = null,
    Object? complexityScoring = null,
    Object? servicePricing = null,
    Object? additionalServicesPricing = null,
  }) {
    return _then(_value.copyWith(
      locationPricing: null == locationPricing
          ? _value.locationPricing
          : locationPricing // ignore: cast_nullable_to_non_nullable
              as LocationPricing,
      complexityScoring: null == complexityScoring
          ? _value.complexityScoring
          : complexityScoring // ignore: cast_nullable_to_non_nullable
              as ComplexityScoring,
      servicePricing: null == servicePricing
          ? _value.servicePricing
          : servicePricing // ignore: cast_nullable_to_non_nullable
              as ServicePricing,
      additionalServicesPricing: null == additionalServicesPricing
          ? _value.additionalServicesPricing
          : additionalServicesPricing // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
    ) as $Val);
  }

  /// Create a copy of PricingBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationPricingCopyWith<$Res> get locationPricing {
    return $LocationPricingCopyWith<$Res>(_value.locationPricing, (value) {
      return _then(_value.copyWith(locationPricing: value) as $Val);
    });
  }

  /// Create a copy of PricingBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ComplexityScoringCopyWith<$Res> get complexityScoring {
    return $ComplexityScoringCopyWith<$Res>(_value.complexityScoring, (value) {
      return _then(_value.copyWith(complexityScoring: value) as $Val);
    });
  }

  /// Create a copy of PricingBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ServicePricingCopyWith<$Res> get servicePricing {
    return $ServicePricingCopyWith<$Res>(_value.servicePricing, (value) {
      return _then(_value.copyWith(servicePricing: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PricingBreakdownImplCopyWith<$Res>
    implements $PricingBreakdownCopyWith<$Res> {
  factory _$$PricingBreakdownImplCopyWith(_$PricingBreakdownImpl value,
          $Res Function(_$PricingBreakdownImpl) then) =
      __$$PricingBreakdownImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {LocationPricing locationPricing,
      ComplexityScoring complexityScoring,
      ServicePricing servicePricing,
      Map<String, double> additionalServicesPricing});

  @override
  $LocationPricingCopyWith<$Res> get locationPricing;
  @override
  $ComplexityScoringCopyWith<$Res> get complexityScoring;
  @override
  $ServicePricingCopyWith<$Res> get servicePricing;
}

/// @nodoc
class __$$PricingBreakdownImplCopyWithImpl<$Res>
    extends _$PricingBreakdownCopyWithImpl<$Res, _$PricingBreakdownImpl>
    implements _$$PricingBreakdownImplCopyWith<$Res> {
  __$$PricingBreakdownImplCopyWithImpl(_$PricingBreakdownImpl _value,
      $Res Function(_$PricingBreakdownImpl) _then)
      : super(_value, _then);

  /// Create a copy of PricingBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? locationPricing = null,
    Object? complexityScoring = null,
    Object? servicePricing = null,
    Object? additionalServicesPricing = null,
  }) {
    return _then(_$PricingBreakdownImpl(
      locationPricing: null == locationPricing
          ? _value.locationPricing
          : locationPricing // ignore: cast_nullable_to_non_nullable
              as LocationPricing,
      complexityScoring: null == complexityScoring
          ? _value.complexityScoring
          : complexityScoring // ignore: cast_nullable_to_non_nullable
              as ComplexityScoring,
      servicePricing: null == servicePricing
          ? _value.servicePricing
          : servicePricing // ignore: cast_nullable_to_non_nullable
              as ServicePricing,
      additionalServicesPricing: null == additionalServicesPricing
          ? _value._additionalServicesPricing
          : additionalServicesPricing // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PricingBreakdownImpl implements _PricingBreakdown {
  const _$PricingBreakdownImpl(
      {required this.locationPricing,
      required this.complexityScoring,
      required this.servicePricing,
      required final Map<String, double> additionalServicesPricing})
      : _additionalServicesPricing = additionalServicesPricing;

  factory _$PricingBreakdownImpl.fromJson(Map<String, dynamic> json) =>
      _$$PricingBreakdownImplFromJson(json);

  @override
  final LocationPricing locationPricing;
  @override
  final ComplexityScoring complexityScoring;
  @override
  final ServicePricing servicePricing;
  final Map<String, double> _additionalServicesPricing;
  @override
  Map<String, double> get additionalServicesPricing {
    if (_additionalServicesPricing is EqualUnmodifiableMapView)
      return _additionalServicesPricing;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_additionalServicesPricing);
  }

  @override
  String toString() {
    return 'PricingBreakdown(locationPricing: $locationPricing, complexityScoring: $complexityScoring, servicePricing: $servicePricing, additionalServicesPricing: $additionalServicesPricing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PricingBreakdownImpl &&
            (identical(other.locationPricing, locationPricing) ||
                other.locationPricing == locationPricing) &&
            (identical(other.complexityScoring, complexityScoring) ||
                other.complexityScoring == complexityScoring) &&
            (identical(other.servicePricing, servicePricing) ||
                other.servicePricing == servicePricing) &&
            const DeepCollectionEquality().equals(
                other._additionalServicesPricing, _additionalServicesPricing));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      locationPricing,
      complexityScoring,
      servicePricing,
      const DeepCollectionEquality().hash(_additionalServicesPricing));

  /// Create a copy of PricingBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PricingBreakdownImplCopyWith<_$PricingBreakdownImpl> get copyWith =>
      __$$PricingBreakdownImplCopyWithImpl<_$PricingBreakdownImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PricingBreakdownImplToJson(
      this,
    );
  }
}

abstract class _PricingBreakdown implements PricingBreakdown {
  const factory _PricingBreakdown(
          {required final LocationPricing locationPricing,
          required final ComplexityScoring complexityScoring,
          required final ServicePricing servicePricing,
          required final Map<String, double> additionalServicesPricing}) =
      _$PricingBreakdownImpl;

  factory _PricingBreakdown.fromJson(Map<String, dynamic> json) =
      _$PricingBreakdownImpl.fromJson;

  @override
  LocationPricing get locationPricing;
  @override
  ComplexityScoring get complexityScoring;
  @override
  ServicePricing get servicePricing;
  @override
  Map<String, double> get additionalServicesPricing;

  /// Create a copy of PricingBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PricingBreakdownImplCopyWith<_$PricingBreakdownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LocationPricing _$LocationPricingFromJson(Map<String, dynamic> json) {
  return _LocationPricing.fromJson(json);
}

/// @nodoc
mixin _$LocationPricing {
  String get city => throw _privateConstructorUsedError;
  String get neighborhood => throw _privateConstructorUsedError;
  double get cityMultiplier => throw _privateConstructorUsedError;
  double get neighborhoodMultiplier => throw _privateConstructorUsedError;
  String get priceZone => throw _privateConstructorUsedError;
  String get explanation => throw _privateConstructorUsedError;

  /// Serializes this LocationPricing to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LocationPricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocationPricingCopyWith<LocationPricing> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationPricingCopyWith<$Res> {
  factory $LocationPricingCopyWith(
          LocationPricing value, $Res Function(LocationPricing) then) =
      _$LocationPricingCopyWithImpl<$Res, LocationPricing>;
  @useResult
  $Res call(
      {String city,
      String neighborhood,
      double cityMultiplier,
      double neighborhoodMultiplier,
      String priceZone,
      String explanation});
}

/// @nodoc
class _$LocationPricingCopyWithImpl<$Res, $Val extends LocationPricing>
    implements $LocationPricingCopyWith<$Res> {
  _$LocationPricingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocationPricing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = null,
    Object? neighborhood = null,
    Object? cityMultiplier = null,
    Object? neighborhoodMultiplier = null,
    Object? priceZone = null,
    Object? explanation = null,
  }) {
    return _then(_value.copyWith(
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      neighborhood: null == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String,
      cityMultiplier: null == cityMultiplier
          ? _value.cityMultiplier
          : cityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      neighborhoodMultiplier: null == neighborhoodMultiplier
          ? _value.neighborhoodMultiplier
          : neighborhoodMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      priceZone: null == priceZone
          ? _value.priceZone
          : priceZone // ignore: cast_nullable_to_non_nullable
              as String,
      explanation: null == explanation
          ? _value.explanation
          : explanation // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LocationPricingImplCopyWith<$Res>
    implements $LocationPricingCopyWith<$Res> {
  factory _$$LocationPricingImplCopyWith(_$LocationPricingImpl value,
          $Res Function(_$LocationPricingImpl) then) =
      __$$LocationPricingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String city,
      String neighborhood,
      double cityMultiplier,
      double neighborhoodMultiplier,
      String priceZone,
      String explanation});
}

/// @nodoc
class __$$LocationPricingImplCopyWithImpl<$Res>
    extends _$LocationPricingCopyWithImpl<$Res, _$LocationPricingImpl>
    implements _$$LocationPricingImplCopyWith<$Res> {
  __$$LocationPricingImplCopyWithImpl(
      _$LocationPricingImpl _value, $Res Function(_$LocationPricingImpl) _then)
      : super(_value, _then);

  /// Create a copy of LocationPricing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = null,
    Object? neighborhood = null,
    Object? cityMultiplier = null,
    Object? neighborhoodMultiplier = null,
    Object? priceZone = null,
    Object? explanation = null,
  }) {
    return _then(_$LocationPricingImpl(
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      neighborhood: null == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String,
      cityMultiplier: null == cityMultiplier
          ? _value.cityMultiplier
          : cityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      neighborhoodMultiplier: null == neighborhoodMultiplier
          ? _value.neighborhoodMultiplier
          : neighborhoodMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      priceZone: null == priceZone
          ? _value.priceZone
          : priceZone // ignore: cast_nullable_to_non_nullable
              as String,
      explanation: null == explanation
          ? _value.explanation
          : explanation // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocationPricingImpl implements _LocationPricing {
  const _$LocationPricingImpl(
      {required this.city,
      required this.neighborhood,
      required this.cityMultiplier,
      required this.neighborhoodMultiplier,
      required this.priceZone,
      required this.explanation});

  factory _$LocationPricingImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocationPricingImplFromJson(json);

  @override
  final String city;
  @override
  final String neighborhood;
  @override
  final double cityMultiplier;
  @override
  final double neighborhoodMultiplier;
  @override
  final String priceZone;
  @override
  final String explanation;

  @override
  String toString() {
    return 'LocationPricing(city: $city, neighborhood: $neighborhood, cityMultiplier: $cityMultiplier, neighborhoodMultiplier: $neighborhoodMultiplier, priceZone: $priceZone, explanation: $explanation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationPricingImpl &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.neighborhood, neighborhood) ||
                other.neighborhood == neighborhood) &&
            (identical(other.cityMultiplier, cityMultiplier) ||
                other.cityMultiplier == cityMultiplier) &&
            (identical(other.neighborhoodMultiplier, neighborhoodMultiplier) ||
                other.neighborhoodMultiplier == neighborhoodMultiplier) &&
            (identical(other.priceZone, priceZone) ||
                other.priceZone == priceZone) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, city, neighborhood,
      cityMultiplier, neighborhoodMultiplier, priceZone, explanation);

  /// Create a copy of LocationPricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationPricingImplCopyWith<_$LocationPricingImpl> get copyWith =>
      __$$LocationPricingImplCopyWithImpl<_$LocationPricingImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocationPricingImplToJson(
      this,
    );
  }
}

abstract class _LocationPricing implements LocationPricing {
  const factory _LocationPricing(
      {required final String city,
      required final String neighborhood,
      required final double cityMultiplier,
      required final double neighborhoodMultiplier,
      required final String priceZone,
      required final String explanation}) = _$LocationPricingImpl;

  factory _LocationPricing.fromJson(Map<String, dynamic> json) =
      _$LocationPricingImpl.fromJson;

  @override
  String get city;
  @override
  String get neighborhood;
  @override
  double get cityMultiplier;
  @override
  double get neighborhoodMultiplier;
  @override
  String get priceZone;
  @override
  String get explanation;

  /// Create a copy of LocationPricing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationPricingImplCopyWith<_$LocationPricingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ComplexityScoring _$ComplexityScoringFromJson(Map<String, dynamic> json) {
  return _ComplexityScoring.fromJson(json);
}

/// @nodoc
mixin _$ComplexityScoring {
  double get floorScore => throw _privateConstructorUsedError;
  double get apartmentScore => throw _privateConstructorUsedError;
  double get ageScore => throw _privateConstructorUsedError;
  double get amenityScore => throw _privateConstructorUsedError;
  double get totalComplexityScore => throw _privateConstructorUsedError;
  String get explanation => throw _privateConstructorUsedError;

  /// Serializes this ComplexityScoring to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ComplexityScoring
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ComplexityScoringCopyWith<ComplexityScoring> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ComplexityScoringCopyWith<$Res> {
  factory $ComplexityScoringCopyWith(
          ComplexityScoring value, $Res Function(ComplexityScoring) then) =
      _$ComplexityScoringCopyWithImpl<$Res, ComplexityScoring>;
  @useResult
  $Res call(
      {double floorScore,
      double apartmentScore,
      double ageScore,
      double amenityScore,
      double totalComplexityScore,
      String explanation});
}

/// @nodoc
class _$ComplexityScoringCopyWithImpl<$Res, $Val extends ComplexityScoring>
    implements $ComplexityScoringCopyWith<$Res> {
  _$ComplexityScoringCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ComplexityScoring
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? floorScore = null,
    Object? apartmentScore = null,
    Object? ageScore = null,
    Object? amenityScore = null,
    Object? totalComplexityScore = null,
    Object? explanation = null,
  }) {
    return _then(_value.copyWith(
      floorScore: null == floorScore
          ? _value.floorScore
          : floorScore // ignore: cast_nullable_to_non_nullable
              as double,
      apartmentScore: null == apartmentScore
          ? _value.apartmentScore
          : apartmentScore // ignore: cast_nullable_to_non_nullable
              as double,
      ageScore: null == ageScore
          ? _value.ageScore
          : ageScore // ignore: cast_nullable_to_non_nullable
              as double,
      amenityScore: null == amenityScore
          ? _value.amenityScore
          : amenityScore // ignore: cast_nullable_to_non_nullable
              as double,
      totalComplexityScore: null == totalComplexityScore
          ? _value.totalComplexityScore
          : totalComplexityScore // ignore: cast_nullable_to_non_nullable
              as double,
      explanation: null == explanation
          ? _value.explanation
          : explanation // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ComplexityScoringImplCopyWith<$Res>
    implements $ComplexityScoringCopyWith<$Res> {
  factory _$$ComplexityScoringImplCopyWith(_$ComplexityScoringImpl value,
          $Res Function(_$ComplexityScoringImpl) then) =
      __$$ComplexityScoringImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double floorScore,
      double apartmentScore,
      double ageScore,
      double amenityScore,
      double totalComplexityScore,
      String explanation});
}

/// @nodoc
class __$$ComplexityScoringImplCopyWithImpl<$Res>
    extends _$ComplexityScoringCopyWithImpl<$Res, _$ComplexityScoringImpl>
    implements _$$ComplexityScoringImplCopyWith<$Res> {
  __$$ComplexityScoringImplCopyWithImpl(_$ComplexityScoringImpl _value,
      $Res Function(_$ComplexityScoringImpl) _then)
      : super(_value, _then);

  /// Create a copy of ComplexityScoring
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? floorScore = null,
    Object? apartmentScore = null,
    Object? ageScore = null,
    Object? amenityScore = null,
    Object? totalComplexityScore = null,
    Object? explanation = null,
  }) {
    return _then(_$ComplexityScoringImpl(
      floorScore: null == floorScore
          ? _value.floorScore
          : floorScore // ignore: cast_nullable_to_non_nullable
              as double,
      apartmentScore: null == apartmentScore
          ? _value.apartmentScore
          : apartmentScore // ignore: cast_nullable_to_non_nullable
              as double,
      ageScore: null == ageScore
          ? _value.ageScore
          : ageScore // ignore: cast_nullable_to_non_nullable
              as double,
      amenityScore: null == amenityScore
          ? _value.amenityScore
          : amenityScore // ignore: cast_nullable_to_non_nullable
              as double,
      totalComplexityScore: null == totalComplexityScore
          ? _value.totalComplexityScore
          : totalComplexityScore // ignore: cast_nullable_to_non_nullable
              as double,
      explanation: null == explanation
          ? _value.explanation
          : explanation // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ComplexityScoringImpl implements _ComplexityScoring {
  const _$ComplexityScoringImpl(
      {required this.floorScore,
      required this.apartmentScore,
      required this.ageScore,
      required this.amenityScore,
      required this.totalComplexityScore,
      required this.explanation});

  factory _$ComplexityScoringImpl.fromJson(Map<String, dynamic> json) =>
      _$$ComplexityScoringImplFromJson(json);

  @override
  final double floorScore;
  @override
  final double apartmentScore;
  @override
  final double ageScore;
  @override
  final double amenityScore;
  @override
  final double totalComplexityScore;
  @override
  final String explanation;

  @override
  String toString() {
    return 'ComplexityScoring(floorScore: $floorScore, apartmentScore: $apartmentScore, ageScore: $ageScore, amenityScore: $amenityScore, totalComplexityScore: $totalComplexityScore, explanation: $explanation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ComplexityScoringImpl &&
            (identical(other.floorScore, floorScore) ||
                other.floorScore == floorScore) &&
            (identical(other.apartmentScore, apartmentScore) ||
                other.apartmentScore == apartmentScore) &&
            (identical(other.ageScore, ageScore) ||
                other.ageScore == ageScore) &&
            (identical(other.amenityScore, amenityScore) ||
                other.amenityScore == amenityScore) &&
            (identical(other.totalComplexityScore, totalComplexityScore) ||
                other.totalComplexityScore == totalComplexityScore) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, floorScore, apartmentScore,
      ageScore, amenityScore, totalComplexityScore, explanation);

  /// Create a copy of ComplexityScoring
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ComplexityScoringImplCopyWith<_$ComplexityScoringImpl> get copyWith =>
      __$$ComplexityScoringImplCopyWithImpl<_$ComplexityScoringImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ComplexityScoringImplToJson(
      this,
    );
  }
}

abstract class _ComplexityScoring implements ComplexityScoring {
  const factory _ComplexityScoring(
      {required final double floorScore,
      required final double apartmentScore,
      required final double ageScore,
      required final double amenityScore,
      required final double totalComplexityScore,
      required final String explanation}) = _$ComplexityScoringImpl;

  factory _ComplexityScoring.fromJson(Map<String, dynamic> json) =
      _$ComplexityScoringImpl.fromJson;

  @override
  double get floorScore;
  @override
  double get apartmentScore;
  @override
  double get ageScore;
  @override
  double get amenityScore;
  @override
  double get totalComplexityScore;
  @override
  String get explanation;

  /// Create a copy of ComplexityScoring
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ComplexityScoringImplCopyWith<_$ComplexityScoringImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ServicePricing _$ServicePricingFromJson(Map<String, dynamic> json) {
  return _ServicePricing.fromJson(json);
}

/// @nodoc
mixin _$ServicePricing {
  ServiceTier get tier => throw _privateConstructorUsedError;
  double get multiplier => throw _privateConstructorUsedError;
  List<String> get includedServices => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Serializes this ServicePricing to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServicePricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServicePricingCopyWith<ServicePricing> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServicePricingCopyWith<$Res> {
  factory $ServicePricingCopyWith(
          ServicePricing value, $Res Function(ServicePricing) then) =
      _$ServicePricingCopyWithImpl<$Res, ServicePricing>;
  @useResult
  $Res call(
      {ServiceTier tier,
      double multiplier,
      List<String> includedServices,
      String description});
}

/// @nodoc
class _$ServicePricingCopyWithImpl<$Res, $Val extends ServicePricing>
    implements $ServicePricingCopyWith<$Res> {
  _$ServicePricingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServicePricing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tier = null,
    Object? multiplier = null,
    Object? includedServices = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as ServiceTier,
      multiplier: null == multiplier
          ? _value.multiplier
          : multiplier // ignore: cast_nullable_to_non_nullable
              as double,
      includedServices: null == includedServices
          ? _value.includedServices
          : includedServices // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServicePricingImplCopyWith<$Res>
    implements $ServicePricingCopyWith<$Res> {
  factory _$$ServicePricingImplCopyWith(_$ServicePricingImpl value,
          $Res Function(_$ServicePricingImpl) then) =
      __$$ServicePricingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ServiceTier tier,
      double multiplier,
      List<String> includedServices,
      String description});
}

/// @nodoc
class __$$ServicePricingImplCopyWithImpl<$Res>
    extends _$ServicePricingCopyWithImpl<$Res, _$ServicePricingImpl>
    implements _$$ServicePricingImplCopyWith<$Res> {
  __$$ServicePricingImplCopyWithImpl(
      _$ServicePricingImpl _value, $Res Function(_$ServicePricingImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServicePricing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tier = null,
    Object? multiplier = null,
    Object? includedServices = null,
    Object? description = null,
  }) {
    return _then(_$ServicePricingImpl(
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as ServiceTier,
      multiplier: null == multiplier
          ? _value.multiplier
          : multiplier // ignore: cast_nullable_to_non_nullable
              as double,
      includedServices: null == includedServices
          ? _value._includedServices
          : includedServices // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServicePricingImpl implements _ServicePricing {
  const _$ServicePricingImpl(
      {required this.tier,
      required this.multiplier,
      required final List<String> includedServices,
      required this.description})
      : _includedServices = includedServices;

  factory _$ServicePricingImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServicePricingImplFromJson(json);

  @override
  final ServiceTier tier;
  @override
  final double multiplier;
  final List<String> _includedServices;
  @override
  List<String> get includedServices {
    if (_includedServices is EqualUnmodifiableListView)
      return _includedServices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_includedServices);
  }

  @override
  final String description;

  @override
  String toString() {
    return 'ServicePricing(tier: $tier, multiplier: $multiplier, includedServices: $includedServices, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServicePricingImpl &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.multiplier, multiplier) ||
                other.multiplier == multiplier) &&
            const DeepCollectionEquality()
                .equals(other._includedServices, _includedServices) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tier, multiplier,
      const DeepCollectionEquality().hash(_includedServices), description);

  /// Create a copy of ServicePricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServicePricingImplCopyWith<_$ServicePricingImpl> get copyWith =>
      __$$ServicePricingImplCopyWithImpl<_$ServicePricingImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServicePricingImplToJson(
      this,
    );
  }
}

abstract class _ServicePricing implements ServicePricing {
  const factory _ServicePricing(
      {required final ServiceTier tier,
      required final double multiplier,
      required final List<String> includedServices,
      required final String description}) = _$ServicePricingImpl;

  factory _ServicePricing.fromJson(Map<String, dynamic> json) =
      _$ServicePricingImpl.fromJson;

  @override
  ServiceTier get tier;
  @override
  double get multiplier;
  @override
  List<String> get includedServices;
  @override
  String get description;

  /// Create a copy of ServicePricing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServicePricingImplCopyWith<_$ServicePricingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

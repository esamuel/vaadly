class Building {
  final String id;
  final String buildingCode; // URL-friendly code like "magdal-shalom"
  final String name;
  final String address;
  final String city;
  final String postalCode;
  final String country;
  final int totalFloors;
  final int totalUnits;
  final int parkingSpaces;
  final int storageUnits;
  final double buildingArea; // in square meters
  final int yearBuilt;
  final String buildingType; // residential, commercial, mixed
  final List<String> amenities; // pool, gym, garden, etc.
  final String? buildingManager;
  final String? managerPhone;
  final String? managerEmail;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Building({
    required this.id,
    required this.buildingCode,
    required this.name,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.totalFloors,
    required this.totalUnits,
    required this.parkingSpaces,
    required this.storageUnits,
    required this.buildingArea,
    required this.yearBuilt,
    required this.buildingType,
    this.amenities = const [],
    this.buildingManager,
    this.managerPhone,
    this.managerEmail,
    this.emergencyContact,
    this.emergencyPhone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  // Getter for full address
  String get fullAddress => '$address, $city, $postalCode, $country';

  // Getter for building display name
  String get displayName => '$name - $city';

  // Getter for occupancy rate (will be calculated from units)
  double get occupancyRate => 0.0; // TODO: Calculate from actual unit data

  // Helper method to parse DateTime from Firestore data
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value.runtimeType.toString().contains('Timestamp')) {
      // Handle Firestore Timestamp
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }

  // Factory constructor from Map
  factory Building.fromMap(Map<String, dynamic> data, String id) {
    return Building(
      id: id,
      buildingCode: data['buildingCode'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? '',
      totalFloors: data['totalFloors'] ?? 1,
      totalUnits: data['totalUnits'] ?? 1,
      parkingSpaces: data['parkingSpaces'] ?? 0,
      storageUnits: data['storageUnits'] ?? 0,
      buildingArea: (data['buildingArea'] ?? 0.0).toDouble(),
      yearBuilt: data['yearBuilt'] ?? DateTime.now().year,
      buildingType: data['buildingType'] ?? 'residential',
      amenities: List<String>.from(data['amenities'] ?? []),
      buildingManager: data['buildingManager'],
      managerPhone: data['managerPhone'],
      managerEmail: data['managerEmail'],
      emergencyContact: data['emergencyContact'],
      emergencyPhone: data['emergencyPhone'],
      notes: data['notes'],
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'buildingCode': buildingCode,
      'name': name,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'totalFloors': totalFloors,
      'totalUnits': totalUnits,
      'parkingSpaces': parkingSpaces,
      'storageUnits': storageUnits,
      'buildingArea': buildingArea,
      'yearBuilt': yearBuilt,
      'buildingType': buildingType,
      'amenities': amenities,
      'buildingManager': buildingManager,
      'managerPhone': managerPhone,
      'managerEmail': managerEmail,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Copy with method
  Building copyWith({
    String? id,
    String? buildingCode,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    int? totalFloors,
    int? totalUnits,
    int? parkingSpaces,
    int? storageUnits,
    double? buildingArea,
    int? yearBuilt,
    String? buildingType,
    List<String>? amenities,
    String? buildingManager,
    String? managerPhone,
    String? managerEmail,
    String? emergencyContact,
    String? emergencyPhone,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Building(
      id: id ?? this.id,
      buildingCode: buildingCode ?? this.buildingCode,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      totalFloors: totalFloors ?? this.totalFloors,
      totalUnits: totalUnits ?? this.totalUnits,
      parkingSpaces: parkingSpaces ?? this.parkingSpaces,
      storageUnits: storageUnits ?? this.storageUnits,
      buildingArea: buildingArea ?? this.buildingArea,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      buildingType: buildingType ?? this.buildingType,
      amenities: amenities ?? this.amenities,
      buildingManager: buildingManager ?? this.buildingManager,
      managerPhone: managerPhone ?? this.managerPhone,
      managerEmail: managerEmail ?? this.managerEmail,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Building(id: $id, name: $name, city: $city, units: $totalUnits)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Building && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum BuildingType {
  residential,    // מגורים
  commercial,     // מסחרי
  mixed,          // מעורב
  office,         // משרדים
  industrial,     // תעשייתי
}

enum BuildingAmenity {
  pool,           // בריכה
  gym,            // חדר כושר
  garden,         // גינה
  playground,     // מגרש משחקים
  parking,        // חניה
  storage,        // מחסן
  elevator,       // מעלית
  security,       // אבטחה
  cctv,           // מצלמות אבטחה
  intercom,       // אינטרקום
  airConditioning, // מיזוג אוויר
  heating,        // חימום
  wifi,           // אינטרנט אלחוטי
  laundry,        // חדר כביסה
  bikeStorage,    // אחסון אופניים
  petFriendly,    // ידידותי לחיות מחמד
  accessibility,  // נגישות
}

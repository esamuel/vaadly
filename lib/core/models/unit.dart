class Unit {
  final String id;
  final String buildingId;
  final String unitNumber;
  final String? floor;
  final UnitType unitType;
  final UnitStatus status;
  final double area; // in square meters
  final int bedrooms;
  final int bathrooms;
  final String? description;
  final List<String> features; // balcony, parking, storage, etc.
  final String? currentResidentId; // ID of current resident
  final String? ownerId; // ID of unit owner
  final double? monthlyRent;
  final double? monthlyMaintenance;
  final DateTime? lastRenovation;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Unit({
    required this.id,
    required this.buildingId,
    required this.unitNumber,
    this.floor,
    required this.unitType,
    required this.status,
    required this.area,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.description,
    this.features = const [],
    this.currentResidentId,
    this.ownerId,
    this.monthlyRent,
    this.monthlyMaintenance,
    this.lastRenovation,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  // Getter for unit display name
  String get displayName {
    switch (unitType) {
      case UnitType.apartment:
        return 'דירה $unitNumber';
      case UnitType.parking:
        return 'חניה $unitNumber';
      case UnitType.storage:
        return 'מחסן $unitNumber';
      case UnitType.commercial:
        return 'מסחר $unitNumber';
      case UnitType.common:
        return 'שטח משותף $unitNumber';
      default:
        return 'יחידה $unitNumber';
    }
  }

  // Getter for full unit identifier
  String get fullIdentifier {
    if (floor != null && floor!.isNotEmpty) {
      return 'קומה $floor - $displayName';
    }
    return displayName;
  }

  // Getter for unit type display
  String get typeDisplay {
    switch (unitType) {
      case UnitType.apartment:
        return 'דירה';
      case UnitType.parking:
        return 'חניה';
      case UnitType.storage:
        return 'מחסן';
      case UnitType.commercial:
        return 'מסחר';
      case UnitType.common:
        return 'שטח משותף';
      default:
        return 'יחידה';
    }
  }

  // Getter for status display
  String get statusDisplay {
    switch (status) {
      case UnitStatus.occupied:
        return 'תפוס';
      case UnitStatus.vacant:
        return 'פנוי';
      case UnitStatus.maintenance:
        return 'בתחזוקה';
      case UnitStatus.reserved:
        return 'שמור';
      case UnitStatus.renovation:
        return 'בשיפוץ';
      default:
        return 'לא ידוע';
    }
  }

  // Factory constructor from Map
  factory Unit.fromMap(Map<String, dynamic> data, String id) {
    return Unit(
      id: id,
      buildingId: data['buildingId'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      floor: data['floor'],
      unitType: UnitType.values.firstWhere(
        (e) => e.toString() == data['unitType'],
        orElse: () => UnitType.apartment,
      ),
      status: UnitStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => UnitStatus.vacant,
      ),
      area: (data['area'] ?? 0.0).toDouble(),
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      description: data['description'],
      features: List<String>.from(data['features'] ?? []),
      currentResidentId: data['currentResidentId'],
      ownerId: data['ownerId'],
      monthlyRent: data['monthlyRent'] != null ? (data['monthlyRent'] as num).toDouble() : null,
      monthlyMaintenance: data['monthlyMaintenance'] != null ? (data['monthlyMaintenance'] as num).toDouble() : null,
      lastRenovation: data['lastRenovation'] != null ? DateTime.parse(data['lastRenovation']) : null,
      notes: data['notes'],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'unitNumber': unitNumber,
      'floor': floor,
      'unitType': unitType.toString(),
      'status': status.toString(),
      'area': area,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'description': description,
      'features': features,
      'currentResidentId': currentResidentId,
      'ownerId': ownerId,
      'monthlyRent': monthlyRent,
      'monthlyMaintenance': monthlyMaintenance,
      'lastRenovation': lastRenovation?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Copy with method
  Unit copyWith({
    String? id,
    String? buildingId,
    String? unitNumber,
    String? floor,
    UnitType? unitType,
    UnitStatus? status,
    double? area,
    int? bedrooms,
    int? bathrooms,
    String? description,
    List<String>? features,
    String? currentResidentId,
    String? ownerId,
    double? monthlyRent,
    double? monthlyMaintenance,
    DateTime? lastRenovation,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Unit(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      unitNumber: unitNumber ?? this.unitNumber,
      floor: floor ?? this.floor,
      unitType: unitType ?? this.unitType,
      status: status ?? this.status,
      area: area ?? this.area,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      description: description ?? this.description,
      features: features ?? this.features,
      currentResidentId: currentResidentId ?? this.currentResidentId,
      ownerId: ownerId ?? this.ownerId,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      monthlyMaintenance: monthlyMaintenance ?? this.monthlyMaintenance,
      lastRenovation: lastRenovation ?? this.lastRenovation,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Unit(id: $id, number: $unitNumber, type: $unitType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Unit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum UnitType {
  apartment,   // דירה
  parking,     // חניה
  storage,     // מחסן
  commercial,  // מסחר
  common,      // שטח משותף
}

enum UnitStatus {
  occupied,    // תפוס
  vacant,      // פנוי
  maintenance, // בתחזוקה
  reserved,    // שמור
  renovation,  // בשיפוץ
}

enum UnitFeature {
  balcony,     // מרפסת
  parking,     // חניה
  storage,     // מחסן
  elevator,    // מעלית
  airConditioning, // מיזוג אוויר
  heating,     // חימום
  internet,    // אינטרנט
  cable,       // כבלים
  security,    // אבטחה
  garden,      // גינה
  pool,        // בריכה
  gym,         // חדר כושר
  laundry,     // חדר כביסה
  bikeStorage, // אחסון אופניים
  petFriendly, // ידידותי לחיות מחמד
  accessibility, // נגישות
}

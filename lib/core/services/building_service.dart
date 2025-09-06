import '../models/building.dart';
import '../models/unit.dart';

class BuildingService {
  // In-memory storage for now (will be replaced with Firebase later)
  static final List<Building> _buildings = [];
  static final List<Unit> _units = [];
  static int _nextBuildingId = 1;
  static int _nextUnitId = 1;

  // Building operations
  static List<Building> getAllBuildings() {
    return List.from(_buildings);
  }

  static Building? getBuildingById(String id) {
    try {
      return _buildings.firstWhere((building) => building.id == id);
    } catch (e) {
      return null;
    }
  }

  static Building addBuilding(Building building) {
    final newBuilding = building.copyWith(
      id: _nextBuildingId.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _buildings.add(newBuilding);
    _nextBuildingId++;

    return newBuilding;
  }

  static Building? updateBuilding(Building building) {
    final index = _buildings.indexWhere((b) => b.id == building.id);
    if (index != -1) {
      final updatedBuilding = building.copyWith(
        updatedAt: DateTime.now(),
      );
      _buildings[index] = updatedBuilding;
      return updatedBuilding;
    }
    return null;
  }

  static bool deleteBuilding(String id) {
    final index = _buildings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _buildings.removeAt(index);
      // Also delete all units associated with this building
      _units.removeWhere((unit) => unit.buildingId == id);
      return true;
    }
    return false;
  }

  // Unit operations
  static List<Unit> getAllUnits() {
    return List.from(_units);
  }

  static List<Unit> getUnitsByBuilding(String buildingId) {
    return _units.where((unit) => unit.buildingId == buildingId).toList();
  }

  static List<Unit> getUnitsByType(UnitType type) {
    return _units.where((unit) => unit.unitType == type).toList();
  }

  static List<Unit> getUnitsByStatus(UnitStatus status) {
    return _units.where((unit) => unit.status == status).toList();
  }

  static Unit? getUnitById(String id) {
    try {
      return _units.firstWhere((unit) => unit.id == id);
    } catch (e) {
      return null;
    }
  }

  static Unit? getUnitByNumber(String buildingId, String unitNumber) {
    try {
      return _units.firstWhere((unit) =>
          unit.buildingId == buildingId && unit.unitNumber == unitNumber);
    } catch (e) {
      return null;
    }
  }

  static Unit addUnit(Unit unit) {
    final newUnit = unit.copyWith(
      id: _nextUnitId.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _units.add(newUnit);
    _nextUnitId++;

    return newUnit;
  }

  static Unit? updateUnit(Unit unit) {
    final index = _units.indexWhere((u) => u.id == unit.id);
    if (index != -1) {
      final updatedUnit = unit.copyWith(
        updatedAt: DateTime.now(),
      );
      _units[index] = updatedUnit;
      return updatedUnit;
    }
    return null;
  }

  static bool deleteUnit(String id) {
    final index = _units.indexWhere((u) => u.id == id);
    if (index != -1) {
      _units.removeAt(index);
      return true;
    }
    return false;
  }

  // Search and filtering
  static List<Building> searchBuildings(String query) {
    if (query.isEmpty) return getAllBuildings();

    final lowercaseQuery = query.toLowerCase();
    return _buildings.where((building) {
      return building.name.toLowerCase().contains(lowercaseQuery) ||
          building.address.toLowerCase().contains(lowercaseQuery) ||
          building.city.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  static List<Unit> searchUnits(String query) {
    if (query.isEmpty) return getAllUnits();

    final lowercaseQuery = query.toLowerCase();
    return _units.where((unit) {
      return unit.unitNumber.toLowerCase().contains(lowercaseQuery) ||
          (unit.floor != null &&
              unit.floor!.toLowerCase().contains(lowercaseQuery)) ||
          unit.description?.toLowerCase().contains(lowercaseQuery) == true;
    }).toList();
  }

  // Statistics
  static Map<String, dynamic> getBuildingStatistics(String buildingId) {
    final building = getBuildingById(buildingId);
    if (building == null) return {};

    final buildingUnits = getUnitsByBuilding(buildingId);
    final occupiedUnits =
        buildingUnits.where((u) => u.status == UnitStatus.occupied).length;
    final vacantUnits =
        buildingUnits.where((u) => u.status == UnitStatus.vacant).length;
    final maintenanceUnits =
        buildingUnits.where((u) => u.status == UnitStatus.maintenance).length;

    final apartments =
        buildingUnits.where((u) => u.unitType == UnitType.apartment).length;
    final parkingSpaces =
        buildingUnits.where((u) => u.unitType == UnitType.parking).length;
    final storageUnits =
        buildingUnits.where((u) => u.unitType == UnitType.storage).length;

    return {
      'totalUnits': buildingUnits.length,
      'occupiedUnits': occupiedUnits,
      'vacantUnits': vacantUnits,
      'maintenanceUnits': maintenanceUnits,
      'apartments': apartments,
      'parkingSpaces': parkingSpaces,
      'storageUnits': storageUnits,
      'occupancyRate': buildingUnits.isNotEmpty
          ? (occupiedUnits / buildingUnits.length * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  static Map<String, dynamic> getOverallStatistics() {
    final totalBuildings = _buildings.length;
    final totalUnits = _units.length;
    final occupiedUnits =
        _units.where((u) => u.status == UnitStatus.occupied).length;
    final vacantUnits =
        _units.where((u) => u.status == UnitStatus.vacant).length;

    return {
      'totalBuildings': totalBuildings,
      'totalUnits': totalUnits,
      'occupiedUnits': occupiedUnits,
      'vacantUnits': vacantUnits,
      'overallOccupancyRate': totalUnits > 0
          ? (occupiedUnits / totalUnits * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  // Initialize with sample data
  static void initializeSampleData() {
    if (_buildings.isNotEmpty) return; // Already initialized

    // Create sample building
    final building = Building(
      id: '1',
      buildingCode: 'vaadly-tlv',
      name: 'בניין וודלי',
      address: 'רחוב הרצל 123',
      city: 'תל אביב',
      postalCode: '6123456',
      country: 'ישראל',
      totalFloors: 15,
      totalUnits: 60,
      parkingSpaces: 45,
      storageUnits: 30,
      buildingArea: 8500.0,
      yearBuilt: 2015,
      buildingType: 'residential',
      amenities: ['pool', 'gym', 'garden', 'security', 'elevator', 'parking'],
      buildingManager: 'יוסי כהן',
      managerPhone: '050-1234567',
      managerEmail: 'yossi@vaadly.co.il',
      emergencyContact: 'אבטחה',
      emergencyPhone: '050-9999999',
      notes: 'בניין יוקרתי במרכז תל אביב - ניהול דיגיטלי מתקדם',
      createdAt: DateTime(2015, 1, 1),
      updatedAt: DateTime(2015, 1, 1),
      isActive: true,
    );

    _buildings.add(building);
    _nextBuildingId = 2;

    // Create sample units
    final sampleUnits = [
      // Apartments
      Unit(
        id: '1',
        buildingId: '1',
        unitNumber: '1',
        floor: '1',
        unitType: UnitType.apartment,
        status: UnitStatus.occupied,
        area: 85.0,
        bedrooms: 3,
        bathrooms: 2,
        description: 'דירה מרווחת עם מרפסת',
        features: ['balcony', 'elevator', 'airConditioning'],
        currentResidentId: '1', // יוסי כהן
        ownerId: '1',
        monthlyRent: 4500.0,
        monthlyMaintenance: 800.0,
        createdAt: DateTime(2015, 1, 1),
        updatedAt: DateTime(2015, 1, 1),
        isActive: true,
      ),
      Unit(
        id: '2',
        buildingId: '1',
        unitNumber: '3',
        floor: '1',
        unitType: UnitType.apartment,
        status: UnitStatus.occupied,
        area: 65.0,
        bedrooms: 2,
        bathrooms: 1,
        description: 'דירה קומפקטית',
        features: ['elevator', 'airConditioning'],
        currentResidentId: '2', // שרה לוי
        ownerId: '3',
        monthlyRent: 3800.0,
        monthlyMaintenance: 650.0,
        createdAt: DateTime(2015, 1, 1),
        updatedAt: DateTime(2015, 1, 1),
        isActive: true,
      ),
      Unit(
        id: '3',
        buildingId: '1',
        unitNumber: '5',
        floor: '2',
        unitType: UnitType.apartment,
        status: UnitStatus.occupied,
        area: 95.0,
        bedrooms: 4,
        bathrooms: 2,
        description: 'דירה גדולה עם נוף',
        features: ['balcony', 'elevator', 'airConditioning', 'garden'],
        currentResidentId: '3', // דוד ישראלי
        ownerId: '3',
        monthlyRent: 5200.0,
        monthlyMaintenance: 900.0,
        createdAt: DateTime(2015, 1, 1),
        updatedAt: DateTime(2015, 1, 1),
        isActive: true,
      ),
      Unit(
        id: '4',
        buildingId: '1',
        unitNumber: '7',
        floor: '2',
        unitType: UnitType.apartment,
        status: UnitStatus.occupied,
        area: 75.0,
        bedrooms: 3,
        bathrooms: 1,
        description: 'דירה משפחתית',
        features: ['elevator', 'airConditioning', 'parking'],
        currentResidentId: '4', // מיכל רוזן
        ownerId: '5',
        monthlyRent: 4200.0,
        monthlyMaintenance: 750.0,
        createdAt: DateTime(2015, 1, 1),
        updatedAt: DateTime(2015, 1, 1),
        isActive: true,
      ),
      Unit(
        id: '5',
        buildingId: '1',
        unitNumber: '9',
        floor: '3',
        unitType: UnitType.apartment,
        status: UnitStatus.occupied,
        area: 110.0,
        bedrooms: 4,
        bathrooms: 3,
        description: 'דירת פנטהאוס',
        features: [
          'balcony',
          'elevator',
          'airConditioning',
          'garden',
          'parking'
        ],
        currentResidentId: '5', // אברהם גולדברג
        ownerId: '5',
        monthlyRent: 6500.0,
        monthlyMaintenance: 1200.0,
        createdAt: DateTime(2015, 1, 1),
        updatedAt: DateTime(2015, 1, 1),
        isActive: true,
      ),

      // Parking spaces
      Unit(
        id: '6',
        buildingId: '1',
        unitNumber: 'P1',
        unitType: UnitType.parking,
        status: UnitStatus.occupied,
        area: 12.0,
        description: 'חניה מקורה',
        features: ['security', 'cctv'],
        currentResidentId: '1',
        monthlyRent: 300.0,
        createdAt: DateTime(2015, 1, 1),
        updatedAt: DateTime(2015, 1, 1),
        isActive: true,
      ),
      Unit(
        id: '7',
        buildingId: '1',
        unitNumber: 'P3',
        unitType: UnitType.parking,
        status: UnitStatus.occupied,
        area: 12.0,
        description: 'חניה מקורה',
        features: ['security', 'cctv'],
        currentResidentId: '2',
        monthlyRent: 300.0,
        createdAt: DateTime(2015, 1, 1),
        updatedAt: DateTime(2015, 1, 1),
        isActive: true,
      ),

      // Storage units
      Unit(
        id: '8',
        buildingId: '1',
        unitNumber: 'S1',
        unitType: UnitType.storage,
        status: UnitStatus.occupied,
        area: 8.0,
        description: 'מחסן אישי',
        features: ['security'],
        currentResidentId: '1',
        monthlyRent: 150.0,
        createdAt: DateTime(2015, 1, 1),
        updatedAt: DateTime(2015, 1, 1),
        isActive: true,
      ),
    ];

    for (final unit in sampleUnits) {
      _units.add(unit);
    }
    _nextUnitId = sampleUnits.length + 1;
  }

  // Clear all data (for testing)
  static void clearAllData() {
    _buildings.clear();
    _units.clear();
    _nextBuildingId = 1;
    _nextUnitId = 1;
  }
}

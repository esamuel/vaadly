import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/building_context.dart';
import '../../services/firebase_building_service.dart';

class BuildingContextService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static BuildingContext? _currentBuildingContext;

  // Current building context
  static BuildingContext? get currentBuilding => _currentBuildingContext;
  static bool get hasBuilding => _currentBuildingContext != null;
  static String? get buildingId => _currentBuildingContext?.buildingId;

  // Extract building code from URL or set manually
  static Future<void> setBuildingContext(String buildingCodeOrId) async {
    try {
      print('🏢 Setting building context: $buildingCodeOrId');
      
      // Try to find building by code first, then by ID
      QuerySnapshot buildingQuery = await _firestore
          .collection('buildings')
          .where('buildingCode', isEqualTo: buildingCodeOrId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      // If not found by code, try by ID
      if (buildingQuery.docs.isEmpty) {
        final buildingDoc = await _firestore
            .collection('buildings')
            .doc(buildingCodeOrId)
            .get();
        
        if (buildingDoc.exists) {
          _currentBuildingContext = BuildingContext.fromFirestore(buildingDoc);
        } else {
          throw Exception('Building not found: $buildingCodeOrId');
        }
      } else {
        _currentBuildingContext = BuildingContext.fromFirestore(buildingQuery.docs.first);
      }

      print('✅ Building context set: ${_currentBuildingContext!.buildingName}');
    } catch (e) {
      print('❌ Failed to set building context: $e');
      _currentBuildingContext = null;
      rethrow;
    }
  }

  // Clear building context
  static void clearBuildingContext() {
    _currentBuildingContext = null;
    print('🗑️ Building context cleared');
  }

  // Set building context from building code using FirebaseBuildingService
  static Future<void> setBuildingContextByCode(String buildingCode) async {
    try {
      print('🏢 Setting building context by code: $buildingCode');
      
      final building = await FirebaseBuildingService.getBuildingByCode(buildingCode);
      
      if (building != null) {
        // Create building context from Building model
        _currentBuildingContext = BuildingContext.create(
          buildingId: building.id,
          buildingCode: building.buildingCode,
          buildingName: building.name,
          address: '${building.address}, ${building.city}',
          managerName: building.buildingManager ?? 'Unknown',
          managerEmail: building.managerEmail ?? '',
          managerPhone: building.managerPhone ?? '',
          isActive: building.isActive,
          createdAt: building.createdAt,
        );
        
        print('✅ Building context set: ${building.name}');
      } else {
        throw Exception('Building not found with code: $buildingCode');
      }
    } catch (e) {
      print('❌ Failed to set building context by code: $e');
      _currentBuildingContext = null;
      rethrow;
    }
  }

  // Get building by code
  static Future<BuildingContext?> getBuildingByCode(String buildingCode) async {
    try {
      final buildingQuery = await _firestore
          .collection('buildings')
          .where('buildingCode', isEqualTo: buildingCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (buildingQuery.docs.isEmpty) return null;
      
      return BuildingContext.fromFirestore(buildingQuery.docs.first);
    } catch (e) {
      print('❌ Failed to get building by code: $e');
      return null;
    }
  }

  // Generate unique building code
  static String generateBuildingCode(String buildingName) {
    // Create a code from building name + random suffix
    final cleanName = buildingName
        .replaceAll(RegExp(r'[^a-zA-Z0-9א-ת]'), '')
        .toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = timestamp.toString().substring(timestamp.toString().length - 4);
    
    return '${cleanName.length > 8 ? cleanName.substring(0, 8) : cleanName}$suffix';
  }

  // Create building context with unique code
  static Future<String> createBuildingWithCode({
    required String name,
    required String address,
    required String city,
    required String managerName,
    required String managerPhone,
    required String managerEmail,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      final buildingCode = generateBuildingCode(name);
      
      // Ensure the code is unique
      var codeExists = true;
      var attemptedCode = buildingCode;
      var attempt = 0;
      
      while (codeExists && attempt < 10) {
        final existing = await getBuildingByCode(attemptedCode);
        if (existing == null) {
          codeExists = false;
        } else {
          attempt++;
          attemptedCode = '${buildingCode.substring(0, buildingCode.length - 1)}$attempt';
        }
      }
      
      if (codeExists) {
        throw Exception('Could not generate unique building code');
      }

      // Create building with code
      final buildingData = {
        'buildingCode': attemptedCode,
        'name': name,
        'address': address,
        'city': city,
        'fullAddress': '$address, $city',
        'buildingManager': managerName,
        'managerPhone': managerPhone,
        'managerEmail': managerEmail,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        ...additionalData,
      };

      final buildingDoc = await _firestore.collection('buildings').add(buildingData);
      
      print('✅ Building created with code: $attemptedCode');
      return attemptedCode;
    } catch (e) {
      print('❌ Failed to create building: $e');
      rethrow;
    }
  }

  // Initialize demo building context
  static Future<void> initializeDemoBuildingContext() async {
    try {
      // Check if demo building already exists with the expected ID
      final demoBuildingDoc = await _firestore
          .collection('buildings')
          .doc('demo_building_1')
          .get();
      
      if (demoBuildingDoc.exists) {
        print('✅ Demo building context already exists');
        return;
      }

      // Create demo building with specific ID to match user access
      final buildingData = {
        'buildingCode': 'shalom1234',
        'name': 'מגדל השלום',
        'address': 'רחוב הרצל 123',
        'city': 'תל אביב',
        'fullAddress': 'רחוב הרצל 123, תל אביב',
        'buildingManager': 'יוסי כהן',
        'managerPhone': '050-1234567',
        'managerEmail': 'committee@shalom-tower.co.il',
        'totalFloors': 8,
        'totalUnits': 24,
        'parkingSpaces': 30,
        'storageUnits': 24,
        'buildingArea': 2500.0,
        'yearBuilt': 2010,
        'buildingType': 'residential',
        'amenities': ['elevator', 'parking', 'garden'],
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('buildings')
          .doc('demo_building_1')
          .set(buildingData);

      print('✅ Demo building context initialized with ID: demo_building_1');
    } catch (e) {
      print('❌ Failed to initialize demo building context: $e');
    }
  }
}
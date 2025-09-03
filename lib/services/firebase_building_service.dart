import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';
import '../core/models/building.dart';

class FirebaseBuildingService {
  static const String _collection = 'buildings';

  /// Add a new building to Firestore
  static Future<Building> addBuilding(Building building) async {
    try {
      // Ensure Firebase is initialized
      await FirebaseService.initialize();
      // Convert building to Map for Firestore
      final buildingData = building.toMap();
      
      // Add timestamps
      buildingData['createdAt'] = FieldValue.serverTimestamp();
      buildingData['updatedAt'] = FieldValue.serverTimestamp();
      
      print('🏢 Adding building to Firestore: ${building.name}');
      
      // Add to Firestore
      final docRef = await FirebaseService.addDocument(_collection, buildingData);
      
      // Return the building with the generated ID
      final savedBuilding = building.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('✅ Building saved to Firestore with ID: ${docRef.id}');
      return savedBuilding;
    } catch (e) {
      print('❌ Error adding building to Firestore: $e');
      rethrow;
    }
  }

  /// Get all buildings from Firestore
  static Future<List<Building>> getAllBuildings() async {
    try {
      // Ensure Firebase is initialized
      await FirebaseService.initialize();
      print('📋 Loading buildings from Firestore...');
      
      final querySnapshot = await FirebaseService.getDocuments(_collection);
      
      final buildings = querySnapshot.docs.map((doc) {
        return Building.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      // Sort by creation date (newest first)
      buildings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ Loaded ${buildings.length} buildings from Firestore');
      return buildings;
    } catch (e) {
      print('❌ Error loading buildings from Firestore: $e');
      return [];
    }
  }

  /// Get a building by building code
  static Future<Building?> getBuildingByCode(String buildingCode) async {
    try {
      // Ensure Firebase is initialized
      await FirebaseService.initialize();
      
      print('🔍 Loading building with code: $buildingCode...');
      
      final querySnapshot = await FirebaseService.firestore
          .collection(_collection)
          .where('buildingCode', isEqualTo: buildingCode)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final building = Building.fromMap(doc.data(), doc.id);
        print('✅ Building found: ${building.name}');
        return building;
      } else {
        print('❌ No building found with code: $buildingCode');
        return null;
      }
    } catch (e) {
      print('❌ Error loading building by code $buildingCode: $e');
      return null;
    }
  }

  /// Get a specific building by ID
  static Future<Building?> getBuildingById(String id) async {
    try {
      // Ensure Firebase is initialized
      await FirebaseService.initialize();
      print('🔍 Loading building $id from Firestore...');
      
      final docSnapshot = await FirebaseService.getDocument(_collection, id);
      
      if (docSnapshot.exists) {
        final building = Building.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
        print('✅ Building loaded: ${building.name}');
        return building;
      } else {
        print('❌ Building $id not found');
        return null;
      }
    } catch (e) {
      print('❌ Error loading building $id: $e');
      return null;
    }
  }

  /// Update an existing building
  static Future<Building?> updateBuilding(Building building) async {
    try {
      print('📝 Updating building ${building.id} in Firestore...');
      
      final buildingData = building.toMap();
      buildingData['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseService.updateDocument(_collection, building.id, buildingData);
      
      final updatedBuilding = building.copyWith(updatedAt: DateTime.now());
      print('✅ Building ${building.id} updated successfully');
      return updatedBuilding;
    } catch (e) {
      print('❌ Error updating building ${building.id}: $e');
      return null;
    }
  }

  /// Delete a building
  static Future<bool> deleteBuilding(String id) async {
    try {
      print('🗑️ Deleting building $id from Firestore...');
      
      await FirebaseService.deleteDocument(_collection, id);
      
      print('✅ Building $id deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting building $id: $e');
      return false;
    }
  }

  /// Search buildings by name or address
  static Future<List<Building>> searchBuildings(String query) async {
    try {
      if (query.isEmpty) return getAllBuildings();
      
      print('🔍 Searching buildings for: $query');
      
      final buildings = await getAllBuildings();
      final lowercaseQuery = query.toLowerCase();
      
      final filteredBuildings = buildings.where((building) {
        return building.name.toLowerCase().contains(lowercaseQuery) ||
            building.address.toLowerCase().contains(lowercaseQuery) ||
            building.city.toLowerCase().contains(lowercaseQuery) ||
            (building.buildingManager?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
      
      print('✅ Found ${filteredBuildings.length} buildings matching "$query"');
      return filteredBuildings;
    } catch (e) {
      print('❌ Error searching buildings: $e');
      return [];
    }
  }

  /// Get buildings statistics
  static Future<Map<String, dynamic>> getBuildingsStats() async {
    try {
      print('📊 Calculating buildings statistics...');
      
      final buildings = await getAllBuildings();
      
      final stats = {
        'totalBuildings': buildings.length,
        'activeBuildings': buildings.where((b) => b.isActive).length,
        'inactiveBuildings': buildings.where((b) => !b.isActive).length,
        'totalUnits': buildings.fold(0, (sum, b) => sum + b.totalUnits),
        'totalFloors': buildings.fold(0, (sum, b) => sum + b.totalFloors),
        'averageUnitsPerBuilding': buildings.isNotEmpty 
            ? (buildings.fold(0, (sum, b) => sum + b.totalUnits) / buildings.length).toStringAsFixed(1)
            : '0.0',
        'newestBuilding': buildings.isNotEmpty 
            ? buildings.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b).name
            : 'אין',
        'oldestBuilding': buildings.isNotEmpty 
            ? buildings.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b).name
            : 'אין',
      };
      
      print('✅ Buildings statistics calculated');
      return stats;
    } catch (e) {
      print('❌ Error calculating buildings statistics: $e');
      return {};
    }
  }

  /// Stream buildings for real-time updates
  static Stream<List<Building>> streamBuildings() {
    try {
      print('🔄 Setting up real-time buildings stream...');
      
      return FirebaseService.firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final buildings = snapshot.docs.map((doc) {
          return Building.fromMap(doc.data(), doc.id);
        }).toList();
        
        print('🔄 Buildings stream updated: ${buildings.length} buildings');
        return buildings;
      });
    } catch (e) {
      print('❌ Error setting up buildings stream: $e');
      rethrow;
    }
  }
}
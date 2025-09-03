import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/app_owner.dart';
import '../core/models/building.dart';

/// Multi-tenant service that manages the app owner/tenant structure
/// New schema: /app_owners/{ownerId}/buildings/{buildingId}/...
class MultiTenantService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =================== APP OWNER METHODS ===================

  /// Get app owner by ID
  static Future<AppOwner?> getAppOwner(String ownerId) async {
    try {
      final doc = await _firestore.collection('app_owners').doc(ownerId).get();
      if (doc.exists) {
        return AppOwner.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting app owner: $e');
      return null;
    }
  }

  /// Create new app owner
  static Future<String?> createAppOwner(AppOwner owner) async {
    try {
      final docRef = await _firestore.collection('app_owners').add(owner.toMap());
      print('✅ App owner created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating app owner: $e');
      return null;
    }
  }

  /// Update app owner
  static Future<bool> updateAppOwner(String ownerId, AppOwner owner) async {
    try {
      await _firestore.collection('app_owners').doc(ownerId).update(owner.toMap());
      print('✅ App owner updated: $ownerId');
      return true;
    } catch (e) {
      print('❌ Error updating app owner: $e');
      return false;
    }
  }

  /// Get all app owners (for super admin)
  static Future<List<AppOwner>> getAllAppOwners() async {
    try {
      final snapshot = await _firestore.collection('app_owners').get();
      return snapshot.docs.map((doc) => AppOwner.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('❌ Error getting app owners: $e');
      return [];
    }
  }

  /// Initialize default app owner (run this once to set up the platform)
  static Future<String?> initializeDefaultAppOwner() async {
    try {
      const email = 'samuel.eskenasy@gmail.com';
      
      // Check if app owner already exists
      final existingQuery = await _firestore
          .collection('app_owners')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (existingQuery.docs.isNotEmpty) {
        print('✅ App Owner already exists: ${existingQuery.docs.first.id}');
        return existingQuery.docs.first.id;
      }

      // Create default app owner
      final appOwner = AppOwner(
        id: '', // Will be set by Firestore
        name: 'Samuel Eskenasy',
        email: email,
        company: 'Valadly',
        subscriptionTier: 'enterprise',
        buildingIds: [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final ownerId = await createAppOwner(appOwner);
      if (ownerId != null) {
        print('✅ Default App Owner initialized: $ownerId');
        print('   Email: $email');
        print('   Password: vaadly123');
      }
      
      return ownerId;
    } catch (e) {
      print('❌ Error initializing default app owner: $e');
      return null;
    }
  }

  // =================== BUILDING METHODS (MULTI-TENANT) ===================

  /// Get building path for multi-tenant structure
  static String _getBuildingPath(String ownerId, String buildingId) {
    return 'app_owners/$ownerId/buildings/$buildingId';
  }

  /// Get collection path for building sub-collections
  static String _getBuildingCollectionPath(String ownerId, String buildingId, String collection) {
    return 'app_owners/$ownerId/buildings/$buildingId/$collection';
  }

  /// Get buildings for a specific app owner
  static Future<List<Building>> getOwnerBuildings(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .get();
      
      return snapshot.docs.map((doc) => Building.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('❌ Error getting owner buildings: $e');
      return [];
    }
  }

  /// Get specific building for an app owner
  static Future<Building?> getOwnerBuilding(String ownerId, String buildingId) async {
    try {
      final doc = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .get();
      
      if (doc.exists) {
        return Building.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting owner building: $e');
      return null;
    }
  }

  /// Add building to app owner
  static Future<String?> addBuildingToOwner(String ownerId, Building building) async {
    try {
      final docRef = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .add(building.toMap());
      
      // Update app owner's building list
      await _firestore.collection('app_owners').doc(ownerId).update({
        'buildingIds': FieldValue.arrayUnion([docRef.id]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Building added to owner $ownerId with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding building to owner: $e');
      return null;
    }
  }

  /// Update building for app owner
  static Future<bool> updateOwnerBuilding(String ownerId, String buildingId, Building building) async {
    try {
      await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .update(building.toMap());
      
      print('✅ Building updated for owner $ownerId');
      return true;
    } catch (e) {
      print('❌ Error updating owner building: $e');
      return false;
    }
  }

  /// Delete building from app owner
  static Future<bool> deleteBuildingFromOwner(String ownerId, String buildingId) async {
    try {
      // Delete building document
      await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .delete();
      
      // Update app owner's building list
      await _firestore.collection('app_owners').doc(ownerId).update({
        'buildingIds': FieldValue.arrayRemove([buildingId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Building deleted from owner $ownerId');
      return true;
    } catch (e) {
      print('❌ Error deleting building from owner: $e');
      return false;
    }
  }

  // =================== TENANT CONTEXT METHODS ===================

  /// Get current tenant context (ownerId, buildingId)
  /// This would typically come from authentication or session
  static Future<Map<String, String>?> getCurrentTenantContext(String userId) async {
    try {
      // This would be implemented based on your auth system
      // For now, return a placeholder
      // In real implementation, you'd look up user permissions
      
      // Example: Query user's access permissions
      // final userDoc = await _firestore.collection('users').doc(userId).get();
      // final userData = userDoc.data();
      // return {
      //   'ownerId': userData['ownerId'],
      //   'buildingId': userData['buildingId'],
      // };
      
      return null; // Placeholder
    } catch (e) {
      print('❌ Error getting tenant context: $e');
      return null;
    }
  }

  // =================== MIGRATION HELPERS ===================

  /// Migrate existing building data to multi-tenant structure
  static Future<bool> migrateBuildingToMultiTenant(String buildingId, String targetOwnerId) async {
    try {
      print('🔄 Migrating building $buildingId to owner $targetOwnerId');
      
      // Get existing building data
      final oldBuildingDoc = await _firestore.collection('buildings').doc(buildingId).get();
      if (!oldBuildingDoc.exists) {
        print('❌ Building $buildingId not found');
        return false;
      }
      
      final buildingData = oldBuildingDoc.data()!;
      
      // Create building in new multi-tenant structure
      final newBuildingRef = await _firestore
          .collection('app_owners')
          .doc(targetOwnerId)
          .collection('buildings')
          .add(buildingData);
      
      // Migrate sub-collections
      await _migrateSubCollections(buildingId, targetOwnerId, newBuildingRef.id);
      
      print('✅ Building $buildingId migrated successfully to ${newBuildingRef.id}');
      return true;
      
    } catch (e) {
      print('❌ Error migrating building: $e');
      return false;
    }
  }

  /// Migrate sub-collections (residents, maintenance, etc.)
  static Future<void> _migrateSubCollections(String oldBuildingId, String ownerId, String newBuildingId) async {
    final subCollections = ['residents', 'maintenance', 'financial', 'vendors', 'announcements'];
    
    for (final collection in subCollections) {
      try {
        print('🔄 Migrating $collection for building $oldBuildingId');
        
        final oldSnapshot = await _firestore
            .collection('buildings')
            .doc(oldBuildingId)
            .collection(collection)
            .get();
        
        if (oldSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          
          for (final doc in oldSnapshot.docs) {
            final newDocRef = _firestore
                .collection('app_owners')
                .doc(ownerId)
                .collection('buildings')
                .doc(newBuildingId)
                .collection(collection)
                .doc(doc.id);
            
            batch.set(newDocRef, doc.data());
          }
          
          await batch.commit();
          print('✅ Migrated ${oldSnapshot.docs.length} documents in $collection');
        }
        
      } catch (e) {
        print('❌ Error migrating $collection: $e');
      }
    }
  }

  // =================== UTILITY METHODS ===================

  /// Validate tenant access to building
  static Future<bool> validateTenantAccess(String ownerId, String buildingId, String userId) async {
    try {
      // Check if building belongs to owner
      final building = await getOwnerBuilding(ownerId, buildingId);
      if (building == null) return false;
      
      // Additional access validation would go here
      // (e.g., check if user has permission to access this building)
      
      return true;
    } catch (e) {
      print('❌ Error validating tenant access: $e');
      return false;
    }
  }

  /// Get analytics for app owner
  static Future<Map<String, dynamic>> getOwnerAnalytics(String ownerId) async {
    try {
      final buildings = await getOwnerBuildings(ownerId);
      
      int totalResidents = 0;
      int totalUnits = 0;
      int activeBuildings = buildings.where((b) => b.isActive).length;
      
      for (final building in buildings) {
        // This would query residents and units for each building
        totalUnits += building.totalUnits;
        // totalResidents += await getResidentCount(ownerId, building.id);
      }
      
      return {
        'totalBuildings': buildings.length,
        'activeBuildings': activeBuildings,
        'totalUnits': totalUnits,
        'totalResidents': totalResidents,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting owner analytics: $e');
      return {};
    }
  }
}
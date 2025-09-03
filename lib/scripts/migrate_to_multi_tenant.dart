import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../core/models/app_owner.dart';
import '../core/models/building.dart';

/// Migration script to convert existing single-tenant structure to multi-tenant
/// 
/// Before: /buildings/{buildingId}/residents/{residentId}
/// After:  /app_owners/{ownerId}/buildings/{buildingId}/residents/{residentId}
class MultiTenantMigrationScript {
  static late FirebaseFirestore _firestore;

  /// Initialize Firebase for migration
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _firestore = FirebaseFirestore.instance;
      print('✅ Firebase initialized for migration');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Main migration function
  static Future<void> migrateToMultiTenant({
    required String appOwnerEmail,
    required String appOwnerName,
    required String appOwnerCompany,
  }) async {
    try {
      print('🚀 Starting multi-tenant migration...');
      print('📧 App Owner: $appOwnerEmail');
      print('🏢 Company: $appOwnerCompany');

      // Step 1: Create the app owner
      final ownerId = await _createAppOwner(appOwnerEmail, appOwnerName, appOwnerCompany);
      if (ownerId == null) {
        throw Exception('Failed to create app owner');
      }

      // Step 2: Get all existing buildings
      final buildings = await _getExistingBuildings();
      print('🏢 Found ${buildings.length} buildings to migrate');

      // Step 3: Migrate each building
      final migratedBuildings = <String>[];
      for (final building in buildings) {
        final success = await _migrateBuildingToMultiTenant(building, ownerId);
        if (success) {
          migratedBuildings.add(building.id);
        }
      }

      // Step 4: Update app owner with building references
      await _updateAppOwnerWithBuildings(ownerId, migratedBuildings);

      // Step 5: Verification
      await _verifyMigration(ownerId, migratedBuildings);

      print('✅ Migration completed successfully!');
      print('📊 Migrated ${migratedBuildings.length} buildings');
      print('🆔 App Owner ID: $ownerId');

    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Create app owner record
  static Future<String?> _createAppOwner(String email, String name, String company) async {
    try {
      print('👤 Creating app owner: $name');

      final appOwner = AppOwner(
        id: '',
        name: name,
        email: email.toLowerCase().trim(),
        company: company,
        phone: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        subscriptionTier: 'professional', // Start with professional tier
        settings: {
          'theme': 'light',
          'language': 'he',
          'notifications': true,
        },
        buildingIds: [], // Will be populated later
      );

      final docRef = await _firestore.collection('app_owners').add(appOwner.toMap());
      print('✅ App owner created with ID: ${docRef.id}');
      
      return docRef.id;
    } catch (e) {
      print('❌ Error creating app owner: $e');
      return null;
    }
  }

  /// Get all existing buildings from old structure
  static Future<List<Building>> _getExistingBuildings() async {
    try {
      print('📋 Fetching existing buildings...');
      
      final snapshot = await _firestore.collection('buildings').get();
      final buildings = <Building>[];

      for (final doc in snapshot.docs) {
        try {
          final building = Building.fromMap(doc.data(), doc.id);
          buildings.add(building);
          print('📍 Found building: ${building.name} (${building.id})');
        } catch (e) {
          print('⚠️ Error parsing building ${doc.id}: $e');
        }
      }

      return buildings;
    } catch (e) {
      print('❌ Error fetching buildings: $e');
      return [];
    }
  }

  /// Migrate a single building to multi-tenant structure
  static Future<bool> _migrateBuildingToMultiTenant(Building building, String ownerId) async {
    try {
      print('🔄 Migrating building: ${building.name} (${building.id})');

      // Create building in new multi-tenant structure
      final newBuildingRef = _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(building.id); // Keep same building ID

      await newBuildingRef.set(building.toMap());
      print('✅ Building document migrated');

      // Migrate all sub-collections
      final subCollections = ['residents', 'maintenance', 'financial', 'vendors', 'announcements', 'units'];
      
      for (final collection in subCollections) {
        final count = await _migrateSubCollection(building.id, ownerId, building.id, collection);
        if (count > 0) {
          print('  📂 Migrated $count documents in $collection');
        }
      }

      return true;
    } catch (e) {
      print('❌ Error migrating building ${building.id}: $e');
      return false;
    }
  }

  /// Migrate a sub-collection from old to new structure
  static Future<int> _migrateSubCollection(
    String oldBuildingId,
    String ownerId,
    String newBuildingId,
    String collection,
  ) async {
    try {
      // Get documents from old structure
      final oldSnapshot = await _firestore
          .collection('buildings')
          .doc(oldBuildingId)
          .collection(collection)
          .get();

      if (oldSnapshot.docs.isEmpty) {
        return 0;
      }

      // Migrate in batches to avoid timeout
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (final doc in oldSnapshot.docs) {
        final newDocRef = _firestore
            .collection('app_owners')
            .doc(ownerId)
            .collection('buildings')
            .doc(newBuildingId)
            .collection(collection)
            .doc(doc.id);

        batch.set(newDocRef, doc.data());
        batchCount++;

        // Commit batch every 450 documents (Firestore limit is 500)
        if (batchCount >= 450) {
          await batch.commit();
          print('    📦 Committed batch of $batchCount documents');
          batchCount = 0;
        }
      }

      // Commit remaining documents
      if (batchCount > 0) {
        await batch.commit();
      }

      return oldSnapshot.docs.length;
    } catch (e) {
      print('❌ Error migrating $collection: $e');
      return 0;
    }
  }

  /// Update app owner with migrated building IDs
  static Future<void> _updateAppOwnerWithBuildings(String ownerId, List<String> buildingIds) async {
    try {
      await _firestore.collection('app_owners').doc(ownerId).update({
        'buildingIds': buildingIds,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ App owner updated with ${buildingIds.length} buildings');
    } catch (e) {
      print('❌ Error updating app owner: $e');
    }
  }

  /// Verify migration was successful
  static Future<void> _verifyMigration(String ownerId, List<String> buildingIds) async {
    try {
      print('🔍 Verifying migration...');

      // Check app owner exists
      final ownerDoc = await _firestore.collection('app_owners').doc(ownerId).get();
      if (!ownerDoc.exists) {
        throw Exception('App owner not found after migration');
      }

      // Check each building exists in new structure
      int verifiedBuildings = 0;
      int totalResidents = 0;

      for (final buildingId in buildingIds) {
        final buildingDoc = await _firestore
            .collection('app_owners')
            .doc(ownerId)
            .collection('buildings')
            .doc(buildingId)
            .get();

        if (buildingDoc.exists) {
          verifiedBuildings++;
          
          // Count residents in this building
          final residentsSnapshot = await _firestore
              .collection('app_owners')
              .doc(ownerId)
              .collection('buildings')
              .doc(buildingId)
              .collection('residents')
              .get();
          
          totalResidents += residentsSnapshot.docs.length;
        }
      }

      print('✅ Verification results:');
      print('  🏢 Buildings verified: $verifiedBuildings/${buildingIds.length}');
      print('  👥 Total residents: $totalResidents');

      if (verifiedBuildings != buildingIds.length) {
        throw Exception('Migration verification failed: missing buildings');
      }

    } catch (e) {
      print('❌ Verification failed: $e');
      rethrow;
    }
  }

  /// Rollback migration (use with caution!)
  static Future<void> rollbackMigration(String ownerId) async {
    try {
      print('⚠️ ROLLING BACK MIGRATION for owner: $ownerId');
      print('🔄 This will DELETE the multi-tenant structure');

      // Delete app owner and all sub-collections
      await _deleteAppOwnerCompletely(ownerId);
      
      print('✅ Migration rollback completed');
      print('⚠️ Original single-tenant data should still be intact');

    } catch (e) {
      print('❌ Rollback failed: $e');
      rethrow;
    }
  }

  /// Delete app owner and all nested data
  static Future<void> _deleteAppOwnerCompletely(String ownerId) async {
    try {
      // Get all buildings for this owner
      final buildingsSnapshot = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .get();

      // Delete each building and its sub-collections
      for (final buildingDoc in buildingsSnapshot.docs) {
        await _deleteBuildingCompletely(ownerId, buildingDoc.id);
      }

      // Delete app owner document
      await _firestore.collection('app_owners').doc(ownerId).delete();
      
      print('✅ App owner $ownerId deleted completely');
    } catch (e) {
      print('❌ Error deleting app owner: $e');
      rethrow;
    }
  }

  /// Delete building and all sub-collections
  static Future<void> _deleteBuildingCompletely(String ownerId, String buildingId) async {
    final subCollections = ['residents', 'maintenance', 'financial', 'vendors', 'announcements', 'units'];
    
    for (final collection in subCollections) {
      await _deleteCollection(_firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .collection(collection));
    }

    // Delete building document
    await _firestore
        .collection('app_owners')
        .doc(ownerId)
        .collection('buildings')
        .doc(buildingId)
        .delete();
  }

  /// Delete all documents in a collection
  static Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}

/// Usage example
/// 
/// To run this migration:
/// 
/// ```dart
/// void main() async {
///   await MultiTenantMigrationScript.initialize();
///   
///   await MultiTenantMigrationScript.migrateToMultiTenant(
///     appOwnerEmail: 'your-email@example.com',
///     appOwnerName: 'Your Name',
///     appOwnerCompany: 'Your Company Ltd',
///   );
/// }
/// ```
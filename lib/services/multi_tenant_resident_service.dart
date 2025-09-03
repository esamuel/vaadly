import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/resident.dart';

/// Multi-tenant resident service
/// New schema: /app_owners/{ownerId}/buildings/{buildingId}/residents/{residentId}
class MultiTenantResidentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =================== RESIDENT CRUD OPERATIONS ===================

  /// Get all residents for a building (multi-tenant)
  static Future<List<Resident>> getResidents(String ownerId, String buildingId) async {
    try {
      print('📋 Getting residents for owner $ownerId, building $buildingId');
      
      final snapshot = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .get();
      
      final residents = snapshot.docs.map((doc) {
        final data = doc.data();
        return Resident.fromMap(data, doc.id);
      }).toList();
      
      print('✅ Retrieved ${residents.length} residents');
      return residents;
    } catch (e) {
      print('❌ Error getting residents: $e');
      return [];
    }
  }

  /// Get specific resident (multi-tenant)
  static Future<Resident?> getResident(String ownerId, String buildingId, String residentId) async {
    try {
      final doc = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .doc(residentId)
          .get();
      
      if (doc.exists) {
        return Resident.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting resident: $e');
      return null;
    }
  }

  /// Add a resident to a building (multi-tenant)
  static Future<String?> addResident(String ownerId, String buildingId, Resident resident) async {
    try {
      print('👤 Adding resident to owner $ownerId, building $buildingId');
      
      final docRef = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .add(resident.toMap());
      
      print('✅ Resident added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding resident: $e');
      return null;
    }
  }

  /// Update a resident (multi-tenant)
  static Future<bool> updateResident(String ownerId, String buildingId, String residentId, Resident resident) async {
    try {
      await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .doc(residentId)
          .update(resident.toMap());
      
      print('✅ Resident updated: $residentId');
      return true;
    } catch (e) {
      print('❌ Error updating resident: $e');
      return false;
    }
  }

  /// Delete a resident (multi-tenant)
  static Future<bool> deleteResident(String ownerId, String buildingId, String residentId) async {
    try {
      await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .doc(residentId)
          .delete();
      
      print('✅ Resident deleted: $residentId');
      return true;
    } catch (e) {
      print('❌ Error deleting resident: $e');
      return false;
    }
  }

  // =================== STATISTICS & ANALYTICS ===================

  /// Get resident statistics for a building (multi-tenant)
  static Future<Map<String, int>> getResidentStatistics(String ownerId, String buildingId) async {
    try {
      final residents = await getResidents(ownerId, buildingId);
      
      int total = residents.length;
      int active = residents.where((r) => r.status == ResidentStatus.active).length;
      int owners = residents.where((r) => r.residentType == ResidentType.owner).length;
      int tenants = residents.where((r) => r.residentType == ResidentType.tenant).length;
      int familyMembers = residents.where((r) => r.residentType == ResidentType.familyMember).length;
      int guests = residents.where((r) => r.residentType == ResidentType.guest).length;
      
      return {
        'total': total,
        'active': active,
        'inactive': total - active,
        'owners': owners,
        'tenants': tenants,
        'familyMembers': familyMembers,
        'guests': guests,
        'occupancyRate': total > 0 ? ((active * 100) / total).round() : 0,
      };
    } catch (e) {
      print('❌ Error getting resident statistics: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'owners': 0,
        'tenants': 0,
        'familyMembers': 0,
        'guests': 0,
        'occupancyRate': 0,
      };
    }
  }

  /// Get resident statistics across all buildings for an app owner
  static Future<Map<String, dynamic>> getOwnerResidentAnalytics(String ownerId) async {
    try {
      print('📊 Getting resident analytics for owner $ownerId');
      
      // Get all buildings for this owner
      final buildingsSnapshot = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .get();
      
      int totalResidents = 0;
      int totalActiveResidents = 0;
      int totalOwners = 0;
      int totalTenants = 0;
      Map<String, int> buildingStats = {};
      
      for (final buildingDoc in buildingsSnapshot.docs) {
        final buildingId = buildingDoc.id;
        final stats = await getResidentStatistics(ownerId, buildingId);
        
        totalResidents += stats['total']!;
        totalActiveResidents += stats['active']!;
        totalOwners += stats['owners']!;
        totalTenants += stats['tenants']!;
        
        buildingStats[buildingId] = stats['total']!;
      }
      
      return {
        'totalBuildings': buildingsSnapshot.docs.length,
        'totalResidents': totalResidents,
        'totalActiveResidents': totalActiveResidents,
        'totalOwners': totalOwners,
        'totalTenants': totalTenants,
        'averageResidentsPerBuilding': buildingsSnapshot.docs.isNotEmpty 
            ? (totalResidents / buildingsSnapshot.docs.length).round() 
            : 0,
        'buildingStats': buildingStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting owner resident analytics: $e');
      return {};
    }
  }

  // =================== QUERY & SEARCH ===================

  /// Search residents by name across all buildings for an owner
  static Future<List<Map<String, dynamic>>> searchResidents(String ownerId, String query) async {
    try {
      print('🔍 Searching residents for owner $ownerId with query: $query');
      
      final buildingsSnapshot = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .get();
      
      List<Map<String, dynamic>> results = [];
      
      for (final buildingDoc in buildingsSnapshot.docs) {
        final buildingId = buildingDoc.id;
        final residents = await getResidents(ownerId, buildingId);
        
        final matchingResidents = residents.where((resident) {
          final lowerQuery = query.toLowerCase();
          return resident.firstName.toLowerCase().contains(lowerQuery) ||
                 resident.lastName.toLowerCase().contains(lowerQuery) ||
                 resident.fullName.toLowerCase().contains(lowerQuery) ||
                 resident.apartmentNumber.contains(query);
        });
        
        for (final resident in matchingResidents) {
          results.add({
            'resident': resident,
            'buildingId': buildingId,
            'buildingName': buildingDoc.data()['name'] ?? 'Unknown Building',
          });
        }
      }
      
      print('✅ Found ${results.length} matching residents');
      return results;
    } catch (e) {
      print('❌ Error searching residents: $e');
      return [];
    }
  }

  /// Get residents by apartment number (multi-tenant)
  static Future<List<Resident>> getResidentsByApartment(String ownerId, String buildingId, String apartmentNumber) async {
    try {
      final snapshot = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .where('apartmentNumber', isEqualTo: apartmentNumber)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Resident.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error getting residents by apartment: $e');
      return [];
    }
  }

  // =================== INITIALIZATION & MIGRATION ===================

  /// Initialize sample residents for a building (multi-tenant)
  static Future<void> initializeSampleResidents(String ownerId, String buildingId) async {
    try {
      print('🔄 Initializing sample residents for owner $ownerId, building $buildingId');
      
      // Check if residents already exist
      final existingResidents = await getResidents(ownerId, buildingId);
      if (existingResidents.isNotEmpty) {
        print('✅ Sample residents already exist');
        return;
      }

      final sampleResidents = _generateSampleResidents();
      
      for (final resident in sampleResidents) {
        await addResident(ownerId, buildingId, resident);
      }
      
      print('✅ Sample residents initialized');
    } catch (e) {
      print('❌ Error initializing sample residents: $e');
    }
  }

  /// Migrate residents from old schema to multi-tenant schema
  static Future<bool> migrateResidentsToMultiTenant(String oldBuildingId, String ownerId, String newBuildingId) async {
    try {
      print('🔄 Migrating residents from $oldBuildingId to owner $ownerId, building $newBuildingId');
      
      // Get residents from old schema
      final oldSnapshot = await _firestore
          .collection('buildings')
          .doc(oldBuildingId)
          .collection('residents')
          .get();
      
      if (oldSnapshot.docs.isEmpty) {
        print('✅ No residents to migrate');
        return true;
      }
      
      // Migrate residents in batch
      final batch = _firestore.batch();
      
      for (final doc in oldSnapshot.docs) {
        final newDocRef = _firestore
            .collection('app_owners')
            .doc(ownerId)
            .collection('buildings')
            .doc(newBuildingId)
            .collection('residents')
            .doc(doc.id);
        
        batch.set(newDocRef, doc.data());
      }
      
      await batch.commit();
      print('✅ Migrated ${oldSnapshot.docs.length} residents');
      
      return true;
    } catch (e) {
      print('❌ Error migrating residents: $e');
      return false;
    }
  }

  // =================== PRIVATE HELPERS ===================

  /// Generate sample resident data
  static List<Resident> _generateSampleResidents() {
    final now = DateTime.now();
    
    return [
      Resident(
        id: '',
        firstName: 'יוסי',
        lastName: 'כהן',
        apartmentNumber: '1',
        floor: '1',
        residentId: '123456789',
        phoneNumber: '050-1234567',
        email: 'yossi.cohen@gmail.com',
        residentType: ResidentType.owner,
        status: ResidentStatus.active,
        moveInDate: DateTime(2020, 3, 15),
        emergencyContact: 'רחל כהן',
        emergencyPhone: '050-1234568',
        notes: 'יושב ועד, אחראי על הגינה',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        tags: ['ועד', 'גינן'],
        customFields: {
          'parkingSpot': 'A1',
          'hasBalcony': true,
          'petOwner': false,
        },
      ),
      Resident(
        id: '',
        firstName: 'מירי',
        lastName: 'לוי',
        apartmentNumber: '3',
        floor: '1',
        residentId: '987654321',
        phoneNumber: '052-9876543',
        email: 'miri.levy@hotmail.com',
        residentType: ResidentType.tenant,
        status: ResidentStatus.active,
        moveInDate: DateTime(2022, 8, 1),
        emergencyContact: 'דוד לוי',
        emergencyPhone: '052-9876544',
        notes: 'שוכרת לטווח ארוך, 3 ילדים',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        tags: ['משפחה', 'ילדים'],
        customFields: {
          'parkingSpot': 'B3',
          'hasBalcony': false,
          'petOwner': true,
          'numberOfChildren': 3,
        },
      ),
    ];
  }
}
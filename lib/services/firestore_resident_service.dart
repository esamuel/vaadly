import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/resident.dart';

class FirestoreResidentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'residents';

  // Add a new resident
  static Future<Resident> addResident(Resident resident) async {
    try {
      print('👤 Adding resident to Firestore: ${resident.fullName}');
      
      // Add to Firestore
      final docRef = await _firestore.collection(_collection).add(resident.toMap());
      
      // Return resident with the new ID
      final newResident = resident.copyWith(id: docRef.id);
      
      print('✅ Resident added successfully with ID: ${docRef.id}');
      return newResident;
    } catch (e) {
      print('❌ Error adding resident: $e');
      rethrow;
    }
  }

  // Get all residents for a specific building
  static Future<List<Resident>> getResidentsByBuilding(String buildingId) async {
    try {
      print('👥 Loading residents for building: $buildingId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('customFields.buildingId', isEqualTo: buildingId)
          .get();
      
      // Sort by firstName after fetching
      final sortedDocs = querySnapshot.docs.toList()
        ..sort((a, b) => (a.data()['firstName'] ?? '').compareTo(b.data()['firstName'] ?? ''));

      final residents = sortedDocs
          .map((doc) => Resident.fromMap(doc.data(), doc.id))
          .toList();

      print('✅ Loaded ${residents.length} residents from Firestore');
      return residents;
    } catch (e) {
      print('❌ Error loading residents: $e');
      return [];
    }
  }

  // Update a resident
  static Future<void> updateResident(Resident resident) async {
    try {
      print('✏️ Updating resident: ${resident.fullName}');
      
      await _firestore
          .collection(_collection)
          .doc(resident.id)
          .update(resident.toMap());
      
      print('✅ Resident updated successfully');
    } catch (e) {
      print('❌ Error updating resident: $e');
      rethrow;
    }
  }

  // Delete a resident
  static Future<void> deleteResident(String residentId) async {
    try {
      print('🗑️ Deleting resident: $residentId');
      
      await _firestore
          .collection(_collection)
          .doc(residentId)
          .delete();
      
      print('✅ Resident deleted successfully');
    } catch (e) {
      print('❌ Error deleting resident: $e');
      rethrow;
    }
  }

  // Get residents statistics for a building
  static Future<Map<String, dynamic>> getResidentsStats(String buildingId) async {
    try {
      final residents = await getResidentsByBuilding(buildingId);
      
      final stats = {
        'total': residents.length,
        'owners': residents.where((r) => r.residentType == ResidentType.owner).length,
        'tenants': residents.where((r) => r.residentType == ResidentType.tenant).length,
        'active': residents.where((r) => r.status == ResidentStatus.active).length,
        'inactive': residents.where((r) => r.status == ResidentStatus.inactive).length,
      };
      
      print('📊 Building $buildingId stats: $stats');
      return stats;
    } catch (e) {
      print('❌ Error calculating stats: $e');
      return {};
    }
  }

  // Search residents
  static Future<List<Resident>> searchResidents(String buildingId, String query) async {
    try {
      final allResidents = await getResidentsByBuilding(buildingId);
      
      final filteredResidents = allResidents.where((resident) {
        final searchQuery = query.toLowerCase();
        return resident.fullName.toLowerCase().contains(searchQuery) ||
            resident.email.toLowerCase().contains(searchQuery) ||
            resident.phoneNumber.toLowerCase().contains(searchQuery) ||
            resident.apartmentNumber.toString().contains(searchQuery);
      }).toList();
      
      print('🔍 Search "$query" found ${filteredResidents.length} residents');
      return filteredResidents;
    } catch (e) {
      print('❌ Error searching residents: $e');
      return [];
    }
  }

  // Initialize sample data for a building (for demo purposes)
  static Future<void> initializeSampleData(String buildingId) async {
    try {
      // Check if residents already exist for this building
      final existing = await getResidentsByBuilding(buildingId);
      if (existing.isNotEmpty) {
        print('✅ Sample residents already exist for building $buildingId');
        return;
      }

      print('🎭 Creating sample residents for building $buildingId...');
      
      final now = DateTime.now();
      final sampleResidents = [
        Resident(
          id: '',
          firstName: 'דוד',
          lastName: 'ישראלי',
          apartmentNumber: '1',
          floor: '1',
          phoneNumber: '050-1234567',
          email: 'david.israeli@email.com',
          residentType: ResidentType.owner,
          status: ResidentStatus.active,
          moveInDate: now.subtract(const Duration(days: 365)),
          isActive: true,
          notes: 'בעל דירה ותיק',
          emergencyContact: 'שרה ישראלי',
          emergencyPhone: '050-7654321',
          createdAt: now,
          updatedAt: now,
          customFields: {'buildingId': buildingId},
        ),
        Resident(
          id: '',
          firstName: 'יוסי',
          lastName: 'כהן',
          apartmentNumber: '5',
          floor: '2',
          phoneNumber: '052-9876543',
          email: 'yossi.cohen@email.com',
          residentType: ResidentType.tenant,
          status: ResidentStatus.active,
          moveInDate: now.subtract(const Duration(days: 180)),
          isActive: true,
          notes: 'דייר חדש',
          emergencyContact: 'רחל כהן',
          emergencyPhone: '052-1111111',
          createdAt: now,
          updatedAt: now,
          customFields: {'buildingId': buildingId},
        ),
        Resident(
          id: '',
          firstName: 'מיכל',
          lastName: 'רוזן',
          apartmentNumber: '7',
          floor: '3',
          phoneNumber: '054-5555555',
          email: 'michal.rosen@email.com',
          residentType: ResidentType.owner,
          status: ResidentStatus.active,
          moveInDate: now.subtract(const Duration(days: 90)),
          isActive: true,
          notes: 'משפחה עם ילדים',
          emergencyContact: 'אבי רוזן',
          emergencyPhone: '054-6666666',
          createdAt: now,
          updatedAt: now,
          customFields: {'buildingId': buildingId},
        ),
      ];

      for (final resident in sampleResidents) {
        await addResident(resident);
      }
      
      print('✅ Sample residents created successfully');
    } catch (e) {
      print('❌ Error creating sample residents: $e');
    }
  }
}
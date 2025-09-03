import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/resident.dart';

class FirestoreResidentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'residents';

  // Add a new resident
  static Future<Resident> addResident(Resident resident) async {
    try {
      print('👤 Adding resident to Firestore: ${resident.name}');
      
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
          .where('buildingId', isEqualTo: buildingId)
          .orderBy('name')
          .get();

      final residents = querySnapshot.docs
          .map((doc) => Resident.fromFirestore(doc))
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
      print('✏️ Updating resident: ${resident.name}');
      
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
        'owners': residents.where((r) => r.type == ResidentType.owner).length,
        'tenants': residents.where((r) => r.type == ResidentType.tenant).length,
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
        return resident.name.toLowerCase().contains(searchQuery) ||
            resident.email.toLowerCase().contains(searchQuery) ||
            resident.phone.toLowerCase().contains(searchQuery) ||
            resident.unit.toString().contains(searchQuery);
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
      
      final sampleResidents = [
        Resident(
          id: '',
          buildingId: buildingId,
          name: 'דוד ישראלי',
          email: 'david.israeli@email.com',
          phone: '050-1234567',
          unit: 1,
          floor: 1,
          type: ResidentType.owner,
          status: ResidentStatus.active,
          moveInDate: DateTime.now().subtract(const Duration(days: 365)),
          notes: 'בעל דירה ותיק',
          emergencyContact: 'שרה ישראלי - 050-7654321',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Resident(
          id: '',
          buildingId: buildingId,
          name: 'יוסי כהן',
          email: 'yossi.cohen@email.com',
          phone: '052-9876543',
          unit: 5,
          floor: 2,
          type: ResidentType.tenant,
          status: ResidentStatus.active,
          moveInDate: DateTime.now().subtract(const Duration(days: 180)),
          notes: 'דייר חדש',
          emergencyContact: 'רחל כהן - 052-1111111',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Resident(
          id: '',
          buildingId: buildingId,
          name: 'מיכל רוזן',
          email: 'michal.rosen@email.com',
          phone: '054-5555555',
          unit: 7,
          floor: 3,
          type: ResidentType.owner,
          status: ResidentStatus.active,
          moveInDate: DateTime.now().subtract(const Duration(days: 90)),
          notes: 'משפחה עם ילדים',
          emergencyContact: 'אבי רוזן - 054-6666666',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
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
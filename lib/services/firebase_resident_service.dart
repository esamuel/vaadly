import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/resident.dart';

class FirebaseResidentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all residents for a building
  static Future<List<Resident>> getResidents(String buildingId) async {
    try {
      final snapshot = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Resident.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error getting residents: $e');
      return [];
    }
  }

  // Add a resident to a building
  static Future<String?> addResident(String buildingId, Resident resident) async {
    try {
      final docRef = await _firestore
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

  // Update a resident
  static Future<bool> updateResident(String buildingId, String residentId, Resident resident) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .doc(residentId)
          .update(resident.toMap());
      
      print('✅ Resident updated');
      return true;
    } catch (e) {
      print('❌ Error updating resident: $e');
      return false;
    }
  }

  // Delete a resident
  static Future<bool> deleteResident(String buildingId, String residentId) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('residents')
          .doc(residentId)
          .delete();
      
      print('✅ Resident deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting resident: $e');
      return false;
    }
  }

  // Get resident statistics for a building
  static Future<Map<String, int>> getResidentStatistics(String buildingId) async {
    try {
      final residents = await getResidents(buildingId);
      
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
      };
    }
  }

  // Initialize sample residents for a building
  static Future<void> initializeSampleResidents(String buildingId) async {
    try {
      // Check if residents already exist
      final existingResidents = await getResidents(buildingId);
      if (existingResidents.isNotEmpty) {
        print('✅ Sample residents already exist for building $buildingId');
        return;
      }

      final sampleResidents = _generateSampleResidents();
      
      for (final resident in sampleResidents) {
        await addResident(buildingId, resident);
      }
      
      print('✅ Sample residents initialized for building $buildingId');
    } catch (e) {
      print('❌ Error initializing sample residents: $e');
    }
  }

  // Generate sample resident data
  static List<Resident> _generateSampleResidents() {
    final now = DateTime.now();
    
    return [
      // Resident 1 - Owner
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

      // Resident 2 - Tenant
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

      // Resident 3 - Family Member
      Resident(
        id: '',
        firstName: 'אבי',
        lastName: 'גרין',
        apartmentNumber: '5',
        floor: '2',
        residentId: '555666777',
        phoneNumber: '053-5556667',
        email: 'avi.green@walla.co.il',
        residentType: ResidentType.familyMember,
        status: ResidentStatus.active,
        moveInDate: DateTime(2023, 1, 10),
        emergencyContact: 'שרה גרין',
        emergencyPhone: '053-5556668',
        notes: 'בן של הבעלים, גר עם ההורים',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        tags: ['צעיר', 'סטודנט'],
        customFields: {
          'parkingSpot': '',
          'hasBalcony': true,
          'petOwner': false,
          'isStudent': true,
        },
      ),

      // Resident 4 - Owner
      Resident(
        id: '',
        firstName: 'רות',
        lastName: 'בן דוד',
        apartmentNumber: '7',
        floor: '3',
        residentId: '111222333',
        phoneNumber: '054-1112223',
        email: 'ruth.bendavid@gmail.com',
        residentType: ResidentType.owner,
        status: ResidentStatus.active,
        moveInDate: DateTime(2018, 12, 5),
        emergencyContact: 'משה בן דוד',
        emergencyPhone: '054-1112224',
        notes: 'פנסיונרית, בעיות ניידות',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        tags: ['מבוגר', 'נכות'],
        customFields: {
          'parkingSpot': 'C7',
          'hasBalcony': true,
          'petOwner': false,
          'accessibilityNeeds': true,
          'isPensioner': true,
        },
      ),

      // Resident 5 - Tenant
      Resident(
        id: '',
        firstName: 'תומר',
        lastName: 'אביב',
        apartmentNumber: '9',
        floor: '4',
        residentId: '888999000',
        phoneNumber: '055-8889990',
        email: 'tomer.aviv@tech.com',
        residentType: ResidentType.tenant,
        status: ResidentStatus.active,
        moveInDate: DateTime(2023, 6, 1),
        emergencyContact: 'נועה אביב',
        emergencyPhone: '055-8889991',
        notes: 'עובד בהיי-טק, נוסע הרבה',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        tags: ['מקצועי', 'טכנולוגיה'],
        customFields: {
          'parkingSpot': 'D9',
          'hasBalcony': false,
          'petOwner': false,
          'workFromHome': true,
          'travelFrequently': true,
        },
      ),
    ];
  }
}
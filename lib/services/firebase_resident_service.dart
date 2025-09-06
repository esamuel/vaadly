import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/resident.dart';

class FirebaseResidentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Real-time stream of residents for a building using flat structure
  static Stream<List<Resident>> streamResidents(String buildingId) {
    return _firestore
        .collection('residents')
        .where('buildingId', isEqualTo: buildingId)
        .orderBy('lastName')
        .orderBy('firstName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resident.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Real-time stream of total residents across all buildings
  static Stream<int> streamAllResidentsCount() {
    return _firestore
        .collection('residents')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
  
  // Get all residents for a building using flat structure
  static Future<List<Resident>> getResidents(String buildingId) async {
    try {
      print('📋 Loading residents for building: $buildingId from flat collection');
      
      // Try flat structure first: residents collection with buildingId field
      final snapshot = await _firestore
          .collection('residents')
          .where('buildingId', isEqualTo: buildingId)
          .get();
      
      print('🔍 Found ${snapshot.docs.length} residents in flat collection');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Resident.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error getting residents from flat collection: $e');
      
      // Create some sample residents for testing if none exist
      print('🔧 Creating sample residents for building $buildingId');
      await _createSampleResidents(buildingId);
      
      // Try again after creating sample data
      try {
        final snapshot = await _firestore
            .collection('residents')
            .where('buildingId', isEqualTo: buildingId)
            .get();
            
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Resident.fromMap(data, doc.id);
        }).toList();
      } catch (e2) {
        print('❌ Error getting residents after sample creation: $e2');
        return [];
      }
    }
  }
  
  // Create sample residents for testing
  static Future<void> _createSampleResidents(String buildingId) async {
    try {
      final sampleResidents = [
        {
          'buildingId': buildingId,
          'firstName': 'יוסי',
          'lastName': 'כהן',
          'email': 'yossi@example.com',
          'phoneNumber': '050-1234567',
          'apartmentNumber': '1',
          'residentType': 'ResidentType.owner',
          'status': 'ResidentStatus.active',
          'moveInDate': Timestamp.now(),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'isActive': true,
          'tags': [],
          'customFields': {},
        },
        {
          'buildingId': buildingId,
          'firstName': 'שרה',
          'lastName': 'לוי',
          'email': 'sarah@example.com',
          'phoneNumber': '050-9876543',
          'apartmentNumber': '3',
          'residentType': 'ResidentType.tenant',
          'status': 'ResidentStatus.active',
          'moveInDate': Timestamp.now(),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'isActive': true,
          'tags': [],
          'customFields': {},
        },
        {
          'buildingId': buildingId,
          'firstName': 'דוד',
          'lastName': 'ישראלי',
          'email': 'david@example.com',
          'phoneNumber': '050-5555555',
          'apartmentNumber': '5',
          'residentType': 'ResidentType.owner',
          'status': 'ResidentStatus.active',
          'moveInDate': Timestamp.now(),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'isActive': true,
          'tags': [],
          'customFields': {},
        },
      ];
      
      for (final residentData in sampleResidents) {
        await _firestore.collection('residents').add(residentData);
      }
      
      print('✅ Sample residents created for building $buildingId');
    } catch (e) {
      print('❌ Error creating sample residents: $e');
    }
  }

  // Add a resident to a building using flat structure
  static Future<String?> addResident(String buildingId, Resident resident) async {
    try {
      print('👤 Adding resident: ${resident.firstName} ${resident.lastName} to building $buildingId');
      
      final residentData = resident.toMap();
      residentData['buildingId'] = buildingId; // Ensure buildingId is set
      
      // Convert ISO8601 dates to Firestore Timestamps for better compatibility
      if (residentData['moveInDate'] is String) {
        residentData['moveInDate'] = Timestamp.fromDate(DateTime.parse(residentData['moveInDate']));
      }
      if (residentData['moveOutDate'] is String) {
        residentData['moveOutDate'] = Timestamp.fromDate(DateTime.parse(residentData['moveOutDate']));
      }
      if (residentData['createdAt'] is String) {
        residentData['createdAt'] = Timestamp.fromDate(DateTime.parse(residentData['createdAt']));
      }
      if (residentData['updatedAt'] is String) {
        residentData['updatedAt'] = Timestamp.fromDate(DateTime.parse(residentData['updatedAt']));
      }
      
      print('💾 Saving resident data: ${residentData.keys.toList()}');
      
      final docRef = await _firestore
          .collection('residents')
          .add(residentData);
      
      print('✅ Resident added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding resident: $e');
      return null;
    }
  }

  // Update a resident using flat structure
  static Future<bool> updateResident(String buildingId, String residentId, Resident resident) async {
    try {
      print('👤 Updating resident: ${resident.firstName} ${resident.lastName}');
      
      final residentData = resident.toMap();
      residentData['buildingId'] = buildingId; // Ensure buildingId is set
      residentData['updatedAt'] = Timestamp.now();
      
      // Convert ISO8601 dates to Firestore Timestamps for better compatibility
      if (residentData['moveInDate'] is String) {
        residentData['moveInDate'] = Timestamp.fromDate(DateTime.parse(residentData['moveInDate']));
      }
      if (residentData['moveOutDate'] is String) {
        residentData['moveOutDate'] = Timestamp.fromDate(DateTime.parse(residentData['moveOutDate']));
      }
      if (residentData['createdAt'] is String) {
        residentData['createdAt'] = Timestamp.fromDate(DateTime.parse(residentData['createdAt']));
      }
      
      await _firestore
          .collection('residents')
          .doc(residentId)
          .update(residentData);
      
      print('✅ Resident updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating resident: $e');
      return false;
    }
  }

  // Delete a resident using flat structure
  static Future<bool> deleteResident(String buildingId, String residentId) async {
    try {
      await _firestore
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
import '../models/resident.dart';

class ResidentService {
  // In-memory storage for now (will be replaced with Firebase later)
  static final List<Resident> _residents = [];
  static int _nextId = 1;

  // Get all residents
  static List<Resident> getAllResidents() {
    return List.from(_residents);
  }

  // Get active residents only
  static List<Resident> getActiveResidents() {
    return _residents.where((resident) => resident.isActive).toList();
  }

  // Get resident by ID
  static Resident? getResidentById(String id) {
    try {
      return _residents.firstWhere((resident) => resident.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get residents by apartment number
  static List<Resident> getResidentsByApartment(String apartmentNumber) {
    return _residents
        .where((resident) => resident.apartmentNumber == apartmentNumber)
        .toList();
  }

  // Get residents by type
  static List<Resident> getResidentsByType(ResidentType type) {
    return _residents
        .where((resident) => resident.residentType == type)
        .toList();
  }

  // Get residents by status
  static List<Resident> getResidentsByStatus(ResidentStatus status) {
    return _residents.where((resident) => resident.status == status).toList();
  }

  // Search residents by name or apartment
  static List<Resident> searchResidents(String query) {
    if (query.isEmpty) return getAllResidents();

    final lowercaseQuery = query.toLowerCase();
    return _residents.where((resident) {
      return resident.firstName.toLowerCase().contains(lowercaseQuery) ||
          resident.lastName.toLowerCase().contains(lowercaseQuery) ||
          resident.fullName.toLowerCase().contains(lowercaseQuery) ||
          resident.apartmentNumber.contains(query);
    }).toList();
  }

  // Add new resident
  static Resident addResident(Resident resident) {
    final newResident = resident.copyWith(
      id: _nextId.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _residents.add(newResident);
    _nextId++;

    return newResident;
  }

  // Update existing resident
  static Resident? updateResident(Resident resident) {
    final index = _residents.indexWhere((r) => r.id == resident.id);
    if (index != -1) {
      final updatedResident = resident.copyWith(
        updatedAt: DateTime.now(),
      );
      _residents[index] = updatedResident;
      return updatedResident;
    }
    return null;
  }

  // Delete resident
  static bool deleteResident(String id) {
    final index = _residents.indexWhere((r) => r.id == id);
    if (index != -1) {
      _residents.removeAt(index);
      return true;
    }
    return false;
  }

  // Soft delete - mark as inactive
  static bool deactivateResident(String id) {
    final resident = getResidentById(id);
    if (resident != null) {
      final updatedResident = resident.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      updateResident(updatedResident);
      return true;
    }
    return false;
  }

  // Get residents with specific tags
  static List<Resident> getResidentsByTags(List<String> tags) {
    return _residents.where((resident) {
      return tags.any((tag) => resident.tags.contains(tag));
    }).toList();
  }

  // Get residents who moved in within a date range
  static List<Resident> getResidentsByMoveInDateRange(
      DateTime start, DateTime end) {
    return _residents.where((resident) {
      return resident.moveInDate
              .isAfter(start.subtract(const Duration(days: 1))) &&
          resident.moveInDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get residents who moved out within a date range
  static List<Resident> getResidentsByMoveOutDateRange(
      DateTime start, DateTime end) {
    return _residents.where((resident) {
      return resident.moveOutDate != null &&
          resident.moveOutDate!
              .isAfter(start.subtract(const Duration(days: 1))) &&
          resident.moveOutDate!.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get statistics
  static Map<String, dynamic> getResidentStatistics() {
    final total = _residents.length;
    final active = _residents.where((r) => r.isActive).length;
    final owners =
        _residents.where((r) => r.residentType == ResidentType.owner).length;
    final tenants =
        _residents.where((r) => r.residentType == ResidentType.tenant).length;
    final familyMembers = _residents
        .where((r) => r.residentType == ResidentType.familyMember)
        .length;
    final guests =
        _residents.where((r) => r.residentType == ResidentType.guest).length;

    return {
      'total': total,
      'active': active,
      'inactive': total - active,
      'owners': owners,
      'tenants': tenants,
      'familyMembers': familyMembers,
      'guests': guests,
      'occupancyRate':
          total > 0 ? (active / total * 100).toStringAsFixed(1) : '0.0',
    };
  }

  // Initialize with sample data
  static void initializeSampleData() {
    if (_residents.isNotEmpty) return; // Already initialized

    final sampleResidents = [
      Resident(
        id: '1',
        firstName: 'יוסי',
        lastName: 'כהן',
        apartmentNumber: '1',
        floor: '1',
        residentId: '123456789',
        phoneNumber: '050-1234567',
        email: 'yossi@email.com',
        residentType: ResidentType.owner,
        status: ResidentStatus.active,
        moveInDate: DateTime(2020, 1, 1),
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2020, 1, 1),
        isActive: true,
        tags: ['VIP', 'Building Committee Member'],
      ),
      Resident(
        id: '2',
        firstName: 'שרה',
        lastName: 'לוי',
        apartmentNumber: '3',
        floor: '1',
        residentId: '987654321',
        phoneNumber: '052-9876543',
        email: 'sara@email.com',
        residentType: ResidentType.tenant,
        status: ResidentStatus.active,
        moveInDate: DateTime(2023, 6, 1),
        createdAt: DateTime(2023, 6, 1),
        updatedAt: DateTime(2023, 6, 1),
        isActive: true,
        tags: ['Student', 'Pet Owner'],
      ),
      Resident(
        id: '3',
        firstName: 'דוד',
        lastName: 'ישראלי',
        apartmentNumber: '5',
        floor: '2',
        residentId: '555555555',
        phoneNumber: '054-5555555',
        email: 'david@email.com',
        residentType: ResidentType.owner,
        status: ResidentStatus.active,
        moveInDate: DateTime(2018, 3, 15),
        createdAt: DateTime(2018, 3, 15),
        updatedAt: DateTime(2018, 3, 15),
        isActive: true,
        tags: ['Senior Citizen', 'Medical Professional'],
      ),
      Resident(
        id: '4',
        firstName: 'מיכל',
        lastName: 'רוזן',
        apartmentNumber: '7',
        floor: '2',
        residentId: '111111111',
        phoneNumber: '053-1111111',
        email: 'michal@email.com',
        residentType: ResidentType.tenant,
        status: ResidentStatus.active,
        moveInDate: DateTime(2022, 9, 1),
        createdAt: DateTime(2022, 9, 1),
        updatedAt: DateTime(2022, 9, 1),
        isActive: true,
        tags: ['Working Professional', 'Family with Children'],
      ),
      Resident(
        id: '5',
        firstName: 'אברהם',
        lastName: 'גולדברג',
        apartmentNumber: '9',
        floor: '3',
        residentId: '222222222',
        phoneNumber: '050-2222222',
        email: 'avi@email.com',
        residentType: ResidentType.owner,
        status: ResidentStatus.active,
        moveInDate: DateTime(2019, 11, 1),
        createdAt: DateTime(2019, 11, 1),
        updatedAt: DateTime(2019, 11, 1),
        isActive: true,
        tags: ['Retired', 'Emergency Contact'],
      ),
    ];

    for (final resident in sampleResidents) {
      _residents.add(resident);
    }
    _nextId = sampleResidents.length + 1;
  }

  // Clear all data (for testing)
  static void clearAllData() {
    _residents.clear();
    _nextId = 1;
  }
}

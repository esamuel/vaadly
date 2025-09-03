# Resident Management System - Vaadly

## Overview
The Resident Management System is a comprehensive solution for managing building residents, including owners, tenants, family members, and guests. It provides a complete CRUD interface with advanced filtering, search capabilities, and detailed resident information tracking.

## Features

### 🏠 Resident Types
- **Owner (בעל דירה)**: Building owners with full rights
- **Tenant (שוכר)**: Renters with temporary access
- **Family Member (בן משפחה)**: Family members living with owners/tenants
- **Guest (אורח)**: Temporary visitors

### 📊 Resident Status
- **Active (פעיל)**: Currently residing in the building
- **Inactive (לא פעיל)**: No longer residing
- **Pending (ממתין לאישור)**: Waiting for approval
- **Suspended (מושעה)**: Temporarily suspended

### 🔍 Advanced Features
- **Search & Filter**: Search by name, apartment number, type, and status
- **Statistics Dashboard**: Real-time resident statistics and occupancy rates
- **Tag System**: Categorize residents (VIP, Special Needs, Pet Owner, etc.)
- **Emergency Contacts**: Store emergency contact information
- **Move-in/out Tracking**: Track resident entry and exit dates
- **Notes System**: Add detailed notes for each resident

## Architecture

### File Structure
```
lib/
├── core/
│   ├── models/
│   │   └── resident.dart          # Resident data model
│   └── services/
│       └── resident_service.dart  # Business logic and data operations
└── features/
    └── residents/
        ├── pages/
        │   └── residents_page.dart # Main residents page
        ├── widgets/
        │   ├── add_resident_form.dart # Add/edit resident form
        │   └── resident_card.dart     # Resident display card
        └── residents.dart             # Export file
```

### Data Model

#### Resident Class
```dart
class Resident {
  final String id;
  final String firstName;
  final String lastName;
  final String apartmentNumber;
  final String phoneNumber;
  final String email;
  final ResidentType residentType;
  final ResidentStatus status;
  final DateTime moveInDate;
  final DateTime? moveOutDate;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? profileImageUrl;
  final List<String> tags;
  final Map<String, dynamic> customFields;
}
```

#### Enums
```dart
enum ResidentType { owner, tenant, familyMember, guest }
enum ResidentStatus { active, inactive, pending, suspended }
```

### Service Layer

#### ResidentService
- **CRUD Operations**: Create, Read, Update, Delete residents
- **Search & Filter**: Advanced filtering by multiple criteria
- **Statistics**: Generate comprehensive resident statistics
- **Data Management**: Handle in-memory storage (ready for Firebase integration)

#### Key Methods
```dart
// Core operations
static List<Resident> getAllResidents()
static Resident? getResidentById(String id)
static Resident addResident(Resident resident)
static Resident? updateResident(Resident resident)
static bool deleteResident(String id)

// Advanced queries
static List<Resident> searchResidents(String query)
static List<Resident> getResidentsByType(ResidentType type)
static List<Resident> getResidentsByStatus(ResidentStatus status)
static List<Resident> getResidentsByTags(List<String> tags)

// Statistics
static Map<String, dynamic> getResidentStatistics()
```

## User Interface

### Main Residents Page
- **Statistics Bar**: Quick overview of resident counts and types
- **Search & Filters**: Advanced filtering capabilities
- **Resident List**: Comprehensive resident cards with actions
- **Floating Action Button**: Add new residents

### Add/Edit Resident Form
- **Personal Information**: First name, last name, apartment number
- **Contact Details**: Phone, email, emergency contacts
- **Resident Details**: Type, status, move-in/out dates
- **Additional Info**: Tags, notes, active status
- **Validation**: Comprehensive form validation

### Resident Card
- **Visual Information**: Avatar, name, apartment, status chips
- **Contact Details**: Phone, email, emergency contacts
- **Dates**: Move-in/out dates, last updated
- **Tags**: Visual tag display
- **Notes**: Expandable notes section
- **Actions**: Edit, delete, call, email

## Usage Examples

### Adding a New Resident
```dart
// Navigate to add resident form
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => AddResidentForm(
      onResidentAdded: (resident) {
        // Handle new resident
        ResidentService.addResident(resident);
      },
    ),
  ),
);
```

### Searching Residents
```dart
// Search by name or apartment
List<Resident> results = ResidentService.searchResidents("יוסי");

// Filter by type
List<Resident> owners = ResidentService.getResidentsByType(ResidentType.owner);

// Filter by status
List<Resident> active = ResidentService.getResidentsByStatus(ResidentStatus.active);
```

### Getting Statistics
```dart
Map<String, dynamic> stats = ResidentService.getResidentStatistics();
print('Total residents: ${stats['total']}');
print('Active residents: ${stats['active']}');
print('Occupancy rate: ${stats['occupancyRate']}%');
```

## Data Persistence

### Current Implementation
- **In-Memory Storage**: Uses static lists for development
- **Sample Data**: Pre-populated with 5 sample residents
- **Ready for Firebase**: Architecture designed for easy Firebase integration

### Future Firebase Integration
```dart
// Example Firebase integration
class FirebaseResidentService {
  static Future<void> addResident(Resident resident) async {
    await FirebaseFirestore.instance
        .collection('residents')
        .add(resident.toFirestore());
  }
  
  static Stream<List<Resident>> getResidentsStream() {
    return FirebaseFirestore.instance
        .collection('residents')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resident.fromFirestore(doc))
            .toList());
  }
}
```

## Customization

### Adding New Resident Types
```dart
enum ResidentType {
  owner,
  tenant,
  familyMember,
  guest,
  contractor,    // New type
  serviceProvider // New type
}
```

### Adding Custom Fields
```dart
// Use the customFields map for building-specific requirements
final resident = Resident(
  // ... other fields
  customFields: {
    'parkingSpot': 'A-15',
    'storageUnit': 'B-3',
    'accessLevel': 'full',
  },
);
```

### Custom Tags
```dart
final List<String> _availableTags = [
  'VIP',
  'Special Needs',
  'Pet Owner',
  'Senior Citizen',
  'Student',
  'Family with Children',
  'Single',
  'Working Professional',
  'Retired',
  'Medical Professional',
  'Emergency Contact',
  'Building Committee Member',
  // Add custom tags here
  'Electric Vehicle Owner',
  'Garden Access',
  'Pool Access',
];
```

## Best Practices

### Data Validation
- All required fields are validated before submission
- Phone numbers must be at least 9 digits
- Email addresses are validated for proper format
- Dates are validated for logical consistency

### Error Handling
- Graceful handling of missing data
- User-friendly error messages in Hebrew
- Confirmation dialogs for destructive actions

### Performance
- Efficient filtering and search algorithms
- Lazy loading of resident details
- Optimized list rendering

## Future Enhancements

### Planned Features
- **Photo Management**: Resident profile photos
- **Document Storage**: Lease agreements, ID documents
- **Communication Tools**: In-app messaging system
- **Payment Integration**: Rent and maintenance fee tracking
- **Visitor Management**: Guest registration and tracking
- **Maintenance Requests**: Link residents to maintenance issues

### Technical Improvements
- **Offline Support**: Local data caching
- **Push Notifications**: Important resident updates
- **Multi-language Support**: English and Hebrew
- **Accessibility**: Screen reader support
- **Dark Mode**: Theme switching capability

## Troubleshooting

### Common Issues

#### Form Validation Errors
- Ensure all required fields are filled
- Check phone number format (minimum 9 digits)
- Verify email address format

#### Search Not Working
- Clear all filters and try again
- Check for extra spaces in search query
- Verify resident data exists

#### Performance Issues
- Limit the number of residents displayed
- Use filters to reduce result set
- Consider pagination for large datasets

## Support

For technical support or feature requests, please refer to the main project documentation or contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: December 2024  
**Compatibility**: Flutter 3.0+  
**Platforms**: iOS, Android, Web, Desktop

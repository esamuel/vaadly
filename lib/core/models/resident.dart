class Resident {
  final String id;
  final String firstName;
  final String lastName;
  final String apartmentNumber;
  final String? floor; // Floor number (optional)
  final String? residentId; // Government ID or passport (optional)
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
  final List<String>
      tags; // For categorization (e.g., "VIP", "Special Needs", "Pet Owner")
  final Map<String, dynamic> customFields; // For building-specific requirements

  Resident({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.apartmentNumber,
    this.floor,
    this.residentId,
    required this.phoneNumber,
    required this.email,
    required this.residentType,
    required this.status,
    required this.moveInDate,
    this.moveOutDate,
    this.emergencyContact,
    this.emergencyPhone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.profileImageUrl,
    this.tags = const [],
    this.customFields = const {},
  });

  // Getter for full name
  String get fullName => '$firstName $lastName';

  // Getter for display name (Hebrew format)
  String get displayName => '$lastName $firstName';

  // Getter for apartment display
  String get apartmentDisplay {
    if (floor != null && floor!.isNotEmpty) {
      return 'דירה $apartmentNumber (קומה $floor)';
    }
    return 'דירה $apartmentNumber';
  }

  // Getter for status display
  String get statusDisplay {
    switch (status) {
      case ResidentStatus.active:
        return 'פעיל';
      case ResidentStatus.inactive:
        return 'לא פעיל';
      case ResidentStatus.pending:
        return 'ממתין לאישור';
      case ResidentStatus.suspended:
        return 'מושעה';
      default:
        return 'לא ידוע';
    }
  }

  // Getter for type display
  String get typeDisplay {
    switch (residentType) {
      case ResidentType.owner:
        return 'בעל דירה';
      case ResidentType.tenant:
        return 'שוכר';
      case ResidentType.familyMember:
        return 'בן משפחה';
      case ResidentType.guest:
        return 'אורח';
      default:
        return 'לא ידוע';
    }
  }

  // Helper method to parse DateTime from Firestore data
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value.runtimeType.toString().contains('Timestamp')) {
      // Handle Firestore Timestamp
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }

  // Factory constructor from Map
  factory Resident.fromMap(Map<String, dynamic> data, String id) {
    return Resident(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      apartmentNumber: data['apartmentNumber'] ?? '',
      floor: data['floor'],
      residentId: data['residentId'],
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      residentType: ResidentType.values.firstWhere(
        (e) => e.toString() == data['residentType'],
        orElse: () => ResidentType.tenant,
      ),
      status: ResidentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ResidentStatus.active,
      ),
      moveInDate: _parseDateTime(data['moveInDate']),
      moveOutDate: data['moveOutDate'] != null
          ? _parseDateTime(data['moveOutDate'])
          : null,
      emergencyContact: data['emergencyContact'],
      emergencyPhone: data['emergencyPhone'],
      notes: data['notes'],
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isActive: data['isActive'] ?? true,
      profileImageUrl: data['profileImageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'apartmentNumber': apartmentNumber,
      'floor': floor,
      'residentId': residentId,
      'phoneNumber': phoneNumber,
      'email': email,
      'residentType': residentType.toString(),
      'status': status.toString(),
      'moveInDate': moveInDate.toIso8601String(),
      'moveOutDate': moveOutDate?.toIso8601String(),
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'tags': tags,
      'customFields': customFields,
    };
  }

  // Copy with method
  Resident copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? apartmentNumber,
    String? floor,
    String? residentId,
    String? phoneNumber,
    String? email,
    ResidentType? residentType,
    ResidentStatus? status,
    DateTime? moveInDate,
    DateTime? moveOutDate,
    String? emergencyContact,
    String? emergencyPhone,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profileImageUrl,
    List<String>? tags,
    Map<String, dynamic>? customFields,
  }) {
    return Resident(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      floor: floor ?? this.floor,
      residentId: residentId ?? this.residentId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      residentType: residentType ?? this.residentType,
      status: status ?? this.status,
      moveInDate: moveInDate ?? this.moveInDate,
      moveOutDate: moveOutDate ?? this.moveOutDate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
    );
  }

  @override
  String toString() {
    return 'Resident(id: $id, name: $fullName, apartment: $apartmentNumber, type: $residentType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Resident && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum ResidentType {
  owner, // בעל דירה
  tenant, // שוכר
  familyMember, // בן משפחה
  guest, // אורח
}

enum ResidentStatus {
  active, // פעיל
  inactive, // לא פעיל
  pending, // ממתין לאישור
  suspended, // מושעה
}

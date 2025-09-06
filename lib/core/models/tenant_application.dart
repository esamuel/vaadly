import 'package:flutter/material.dart';

enum ApplicationStatus {
  draft, // טיוטה
  submitted, // הוגש
  underReview, // בבדיקה
  approved, // מאושר
  rejected, // נדחה
  waitingList, // רשימת המתנה
}

enum EmploymentStatus {
  employed, // מועסק
  selfEmployed, // עצמאי
  unemployed, // מובטל
  retired, // פנסיונר
  student, // סטודנט
  other, // אחר
}

enum IncomeVerificationStatus {
  pending, // ממתין
  verified, // מאומת
  failed, // נכשל
  notRequired, // לא נדרש
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final String? email;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> data) {
    return EmergencyContact(
      name: data['name'] ?? '',
      relationship: data['relationship'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
    );
  }
}

class Reference {
  final String name;
  final String relationship;
  final String phone;
  final String? email;
  final String? company;
  final bool isVerified;
  final String? verificationNotes;

  Reference({
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
    this.company,
    this.isVerified = false,
    this.verificationNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
      'company': company,
      'isVerified': isVerified,
      'verificationNotes': verificationNotes,
    };
  }

  factory Reference.fromMap(Map<String, dynamic> data) {
    return Reference(
      name: data['name'] ?? '',
      relationship: data['relationship'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      company: data['company'],
      isVerified: data['isVerified'] ?? false,
      verificationNotes: data['verificationNotes'],
    );
  }
}

class TenantApplication {
  final String id;
  final String buildingId;
  final String? unitId;
  final ApplicationStatus status;
  
  // Personal Information
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final String? governmentId;
  final String? profileImageUrl;
  
  // Current Address
  final String currentAddress;
  final String currentCity;
  final String currentPostalCode;
  final DateTime? currentResidenceStartDate;
  final String? currentLandlordName;
  final String? currentLandlordPhone;
  final double? currentRent;
  final String? reasonForLeaving;
  
  // Employment Information
  final EmploymentStatus employmentStatus;
  final String? employerName;
  final String? employerAddress;
  final String? employerPhone;
  final String? jobTitle;
  final double? monthlyIncome;
  final DateTime? employmentStartDate;
  final String? previousEmployer;
  final IncomeVerificationStatus incomeVerificationStatus;
  
  // Financial Information
  final double? bankBalance;
  final int? creditScore;
  final bool hasBankruptcy;
  final bool hasEvictions;
  final String? additionalIncome;
  final double? additionalIncomeAmount;
  
  // Rental Preferences
  final DateTime? preferredMoveInDate;
  final int? leaseDurationMonths;
  final double? budgetMin;
  final double? budgetMax;
  final bool hasPets;
  final List<String> pets;
  final bool smokingPreference;
  final int? numberOfOccupants;
  
  // References
  final List<Reference> references;
  final List<EmergencyContact> emergencyContacts;
  
  // Documents
  final List<String> documentUrls;
  final Map<String, bool> requiredDocuments; // document_type -> uploaded
  
  // Application Details
  final String? additionalNotes;
  final String? specialRequests;
  final Map<String, dynamic> screeningResults;
  final String? rejectionReason;
  final String? adminNotes;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  TenantApplication({
    required this.id,
    required this.buildingId,
    this.unitId,
    required this.status,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    this.governmentId,
    this.profileImageUrl,
    required this.currentAddress,
    required this.currentCity,
    required this.currentPostalCode,
    this.currentResidenceStartDate,
    this.currentLandlordName,
    this.currentLandlordPhone,
    this.currentRent,
    this.reasonForLeaving,
    required this.employmentStatus,
    this.employerName,
    this.employerAddress,
    this.employerPhone,
    this.jobTitle,
    this.monthlyIncome,
    this.employmentStartDate,
    this.previousEmployer,
    this.incomeVerificationStatus = IncomeVerificationStatus.pending,
    this.bankBalance,
    this.creditScore,
    this.hasBankruptcy = false,
    this.hasEvictions = false,
    this.additionalIncome,
    this.additionalIncomeAmount,
    this.preferredMoveInDate,
    this.leaseDurationMonths,
    this.budgetMin,
    this.budgetMax,
    this.hasPets = false,
    this.pets = const [],
    this.smokingPreference = false,
    this.numberOfOccupants,
    this.references = const [],
    this.emergencyContacts = const [],
    this.documentUrls = const [],
    this.requiredDocuments = const {},
    this.additionalNotes,
    this.specialRequests,
    this.screeningResults = const {},
    this.rejectionReason,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  // Getters
  String get fullName => '$firstName $lastName';
  String get displayName => '$lastName $firstName';
  
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  String get statusDisplay {
    switch (status) {
      case ApplicationStatus.draft:
        return 'טיוטה';
      case ApplicationStatus.submitted:
        return 'הוגש';
      case ApplicationStatus.underReview:
        return 'בבדיקה';
      case ApplicationStatus.approved:
        return 'מאושר';
      case ApplicationStatus.rejected:
        return 'נדחה';
      case ApplicationStatus.waitingList:
        return 'רשימת המתנה';
    }
  }

  String get employmentStatusDisplay {
    switch (employmentStatus) {
      case EmploymentStatus.employed:
        return 'מועסק';
      case EmploymentStatus.selfEmployed:
        return 'עצמאי';
      case EmploymentStatus.unemployed:
        return 'מובטל';
      case EmploymentStatus.retired:
        return 'פנסיונר';
      case EmploymentStatus.student:
        return 'סטודנט';
      case EmploymentStatus.other:
        return 'אחר';
    }
  }

  String get incomeVerificationDisplay {
    switch (incomeVerificationStatus) {
      case IncomeVerificationStatus.pending:
        return 'ממתין לאימות';
      case IncomeVerificationStatus.verified:
        return 'מאומת';
      case IncomeVerificationStatus.failed:
        return 'נכשל באימות';
      case IncomeVerificationStatus.notRequired:
        return 'לא נדרש אימות';
    }
  }

  Color get statusColor {
    switch (status) {
      case ApplicationStatus.draft:
        return Colors.grey;
      case ApplicationStatus.submitted:
        return Colors.blue;
      case ApplicationStatus.underReview:
        return Colors.orange;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.waitingList:
        return Colors.purple;
    }
  }

  bool get isComplete {
    return firstName.isNotEmpty &&
           lastName.isNotEmpty &&
           email.isNotEmpty &&
           phone.isNotEmpty &&
           currentAddress.isNotEmpty &&
           monthlyIncome != null &&
           monthlyIncome! > 0;
  }

  double get incomeToRentRatio {
    if (monthlyIncome == null || currentRent == null || currentRent == 0) {
      return 0.0;
    }
    return monthlyIncome! / currentRent!;
  }

  bool get meetsIncomeRequirement {
    // Standard requirement: income should be at least 3x the rent
    return incomeToRentRatio >= 3.0;
  }

  double get completionPercentage {
    int totalFields = 20; // Approximate number of important fields
    int completedFields = 0;
    
    if (firstName.isNotEmpty) completedFields++;
    if (lastName.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (phone.isNotEmpty) completedFields++;
    if (governmentId != null && governmentId!.isNotEmpty) completedFields++;
    if (currentAddress.isNotEmpty) completedFields++;
    if (currentCity.isNotEmpty) completedFields++;
    if (currentPostalCode.isNotEmpty) completedFields++;
    if (employerName != null && employerName!.isNotEmpty) completedFields++;
    if (jobTitle != null && jobTitle!.isNotEmpty) completedFields++;
    if (monthlyIncome != null) completedFields++;
    if (employmentStartDate != null) completedFields++;
    if (currentLandlordName != null && currentLandlordName!.isNotEmpty) completedFields++;
    if (currentLandlordPhone != null && currentLandlordPhone!.isNotEmpty) completedFields++;
    if (currentRent != null) completedFields++;
    if (preferredMoveInDate != null) completedFields++;
    if (leaseDurationMonths != null) completedFields++;
    if (references.isNotEmpty) completedFields++;
    if (emergencyContacts.isNotEmpty) completedFields++;
    if (documentUrls.isNotEmpty) completedFields++;
    
    return (completedFields / totalFields * 100);
  }

  // Helper method to parse DateTime from Firestore data
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }

  // Factory constructor from Map
  factory TenantApplication.fromMap(Map<String, dynamic> data, String id) {
    return TenantApplication(
      id: id,
      buildingId: data['buildingId'] ?? '',
      unitId: data['unitId'],
      status: ApplicationStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ApplicationStatus.draft,
      ),
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      dateOfBirth: _parseDateTime(data['dateOfBirth']),
      governmentId: data['governmentId'],
      profileImageUrl: data['profileImageUrl'],
      currentAddress: data['currentAddress'] ?? '',
      currentCity: data['currentCity'] ?? '',
      currentPostalCode: data['currentPostalCode'] ?? '',
      currentResidenceStartDate: data['currentResidenceStartDate'] != null 
          ? _parseDateTime(data['currentResidenceStartDate']) : null,
      currentLandlordName: data['currentLandlordName'],
      currentLandlordPhone: data['currentLandlordPhone'],
      currentRent: data['currentRent']?.toDouble(),
      reasonForLeaving: data['reasonForLeaving'],
      employmentStatus: EmploymentStatus.values.firstWhere(
        (e) => e.toString() == data['employmentStatus'],
        orElse: () => EmploymentStatus.employed,
      ),
      employerName: data['employerName'],
      employerAddress: data['employerAddress'],
      employerPhone: data['employerPhone'],
      jobTitle: data['jobTitle'],
      monthlyIncome: data['monthlyIncome']?.toDouble(),
      employmentStartDate: data['employmentStartDate'] != null 
          ? _parseDateTime(data['employmentStartDate']) : null,
      previousEmployer: data['previousEmployer'],
      incomeVerificationStatus: IncomeVerificationStatus.values.firstWhere(
        (e) => e.toString() == data['incomeVerificationStatus'],
        orElse: () => IncomeVerificationStatus.pending,
      ),
      bankBalance: data['bankBalance']?.toDouble(),
      creditScore: data['creditScore'],
      hasBankruptcy: data['hasBankruptcy'] ?? false,
      hasEvictions: data['hasEvictions'] ?? false,
      additionalIncome: data['additionalIncome'],
      additionalIncomeAmount: data['additionalIncomeAmount']?.toDouble(),
      preferredMoveInDate: data['preferredMoveInDate'] != null 
          ? _parseDateTime(data['preferredMoveInDate']) : null,
      leaseDurationMonths: data['leaseDurationMonths'],
      budgetMin: data['budgetMin']?.toDouble(),
      budgetMax: data['budgetMax']?.toDouble(),
      hasPets: data['hasPets'] ?? false,
      pets: List<String>.from(data['pets'] ?? []),
      smokingPreference: data['smokingPreference'] ?? false,
      numberOfOccupants: data['numberOfOccupants'],
      references: (data['references'] as List<dynamic>? ?? [])
          .map((ref) => Reference.fromMap(ref))
          .toList(),
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>? ?? [])
          .map((contact) => EmergencyContact.fromMap(contact))
          .toList(),
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      requiredDocuments: Map<String, bool>.from(data['requiredDocuments'] ?? {}),
      additionalNotes: data['additionalNotes'],
      specialRequests: data['specialRequests'],
      screeningResults: Map<String, dynamic>.from(data['screeningResults'] ?? {}),
      rejectionReason: data['rejectionReason'],
      adminNotes: data['adminNotes'],
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      submittedAt: data['submittedAt'] != null ? _parseDateTime(data['submittedAt']) : null,
      reviewedAt: data['reviewedAt'] != null ? _parseDateTime(data['reviewedAt']) : null,
      reviewedBy: data['reviewedBy'],
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'unitId': unitId,
      'status': status.toString(),
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'governmentId': governmentId,
      'profileImageUrl': profileImageUrl,
      'currentAddress': currentAddress,
      'currentCity': currentCity,
      'currentPostalCode': currentPostalCode,
      'currentResidenceStartDate': currentResidenceStartDate?.toIso8601String(),
      'currentLandlordName': currentLandlordName,
      'currentLandlordPhone': currentLandlordPhone,
      'currentRent': currentRent,
      'reasonForLeaving': reasonForLeaving,
      'employmentStatus': employmentStatus.toString(),
      'employerName': employerName,
      'employerAddress': employerAddress,
      'employerPhone': employerPhone,
      'jobTitle': jobTitle,
      'monthlyIncome': monthlyIncome,
      'employmentStartDate': employmentStartDate?.toIso8601String(),
      'previousEmployer': previousEmployer,
      'incomeVerificationStatus': incomeVerificationStatus.toString(),
      'bankBalance': bankBalance,
      'creditScore': creditScore,
      'hasBankruptcy': hasBankruptcy,
      'hasEvictions': hasEvictions,
      'additionalIncome': additionalIncome,
      'additionalIncomeAmount': additionalIncomeAmount,
      'preferredMoveInDate': preferredMoveInDate?.toIso8601String(),
      'leaseDurationMonths': leaseDurationMonths,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'hasPets': hasPets,
      'pets': pets,
      'smokingPreference': smokingPreference,
      'numberOfOccupants': numberOfOccupants,
      'references': references.map((ref) => ref.toMap()).toList(),
      'emergencyContacts': emergencyContacts.map((contact) => contact.toMap()).toList(),
      'documentUrls': documentUrls,
      'requiredDocuments': requiredDocuments,
      'additionalNotes': additionalNotes,
      'specialRequests': specialRequests,
      'screeningResults': screeningResults,
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
    };
  }

  // Copy with method
  TenantApplication copyWith({
    String? id,
    String? buildingId,
    String? unitId,
    ApplicationStatus? status,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? governmentId,
    String? profileImageUrl,
    String? currentAddress,
    String? currentCity,
    String? currentPostalCode,
    DateTime? currentResidenceStartDate,
    String? currentLandlordName,
    String? currentLandlordPhone,
    double? currentRent,
    String? reasonForLeaving,
    EmploymentStatus? employmentStatus,
    String? employerName,
    String? employerAddress,
    String? employerPhone,
    String? jobTitle,
    double? monthlyIncome,
    DateTime? employmentStartDate,
    String? previousEmployer,
    IncomeVerificationStatus? incomeVerificationStatus,
    double? bankBalance,
    int? creditScore,
    bool? hasBankruptcy,
    bool? hasEvictions,
    String? additionalIncome,
    double? additionalIncomeAmount,
    DateTime? preferredMoveInDate,
    int? leaseDurationMonths,
    double? budgetMin,
    double? budgetMax,
    bool? hasPets,
    List<String>? pets,
    bool? smokingPreference,
    int? numberOfOccupants,
    List<Reference>? references,
    List<EmergencyContact>? emergencyContacts,
    List<String>? documentUrls,
    Map<String, bool>? requiredDocuments,
    String? additionalNotes,
    String? specialRequests,
    Map<String, dynamic>? screeningResults,
    String? rejectionReason,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return TenantApplication(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      unitId: unitId ?? this.unitId,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      governmentId: governmentId ?? this.governmentId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currentAddress: currentAddress ?? this.currentAddress,
      currentCity: currentCity ?? this.currentCity,
      currentPostalCode: currentPostalCode ?? this.currentPostalCode,
      currentResidenceStartDate: currentResidenceStartDate ?? this.currentResidenceStartDate,
      currentLandlordName: currentLandlordName ?? this.currentLandlordName,
      currentLandlordPhone: currentLandlordPhone ?? this.currentLandlordPhone,
      currentRent: currentRent ?? this.currentRent,
      reasonForLeaving: reasonForLeaving ?? this.reasonForLeaving,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      employerName: employerName ?? this.employerName,
      employerAddress: employerAddress ?? this.employerAddress,
      employerPhone: employerPhone ?? this.employerPhone,
      jobTitle: jobTitle ?? this.jobTitle,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      previousEmployer: previousEmployer ?? this.previousEmployer,
      incomeVerificationStatus: incomeVerificationStatus ?? this.incomeVerificationStatus,
      bankBalance: bankBalance ?? this.bankBalance,
      creditScore: creditScore ?? this.creditScore,
      hasBankruptcy: hasBankruptcy ?? this.hasBankruptcy,
      hasEvictions: hasEvictions ?? this.hasEvictions,
      additionalIncome: additionalIncome ?? this.additionalIncome,
      additionalIncomeAmount: additionalIncomeAmount ?? this.additionalIncomeAmount,
      preferredMoveInDate: preferredMoveInDate ?? this.preferredMoveInDate,
      leaseDurationMonths: leaseDurationMonths ?? this.leaseDurationMonths,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      hasPets: hasPets ?? this.hasPets,
      pets: pets ?? this.pets,
      smokingPreference: smokingPreference ?? this.smokingPreference,
      numberOfOccupants: numberOfOccupants ?? this.numberOfOccupants,
      references: references ?? this.references,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      documentUrls: documentUrls ?? this.documentUrls,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      specialRequests: specialRequests ?? this.specialRequests,
      screeningResults: screeningResults ?? this.screeningResults,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  @override
  String toString() {
    return 'TenantApplication(id: $id, name: $fullName, status: $status, building: $buildingId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TenantApplication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
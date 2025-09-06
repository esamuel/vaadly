import 'package:flutter/material.dart';

enum LeaseStatus {
  draft, // טיוטה
  active, // פעיל
  expired, // פג תוקף
  terminated, // הופסק
  renewed, // חודש
}

enum LeaseType {
  residential, // מגורים
  commercial, // מסחרי
  office, // משרד
  parking, // חניה
  storage, // מחסן
}

enum RentPaymentFrequency {
  monthly, // חודשי
  quarterly, // רבעוני
  yearly, // שנתי
}

class Lease {
  final String id;
  final String buildingId;
  final String unitId;
  final String landlordId; // Property owner
  final String tenantId; // Resident
  final LeaseType type;
  final LeaseStatus status;
  final String title;
  final String? description;
  
  // Lease terms
  final DateTime startDate;
  final DateTime endDate;
  final int durationMonths;
  final bool autoRenew;
  final int? renewalNoticeMonths;
  
  // Financial terms
  final double monthlyRent;
  final double securityDeposit;
  final double? brokerFee;
  final RentPaymentFrequency paymentFrequency;
  final int paymentDueDay; // Day of month rent is due
  final double? lateFeeAmount;
  final int? lateFeeDays; // Days after due date before late fee applies
  
  // Utilities and services
  final bool utilitiesIncluded;
  final List<String> includedUtilities; // water, electricity, gas, internet, etc.
  final double? maintenanceFee;
  final bool maintenanceIncluded;
  
  // Property details
  final double unitArea;
  final int? bedrooms;
  final int? bathrooms;
  final bool furnished;
  final List<String> includedFurnishing;
  final List<String> amenities;
  
  // Rules and restrictions
  final bool petsAllowed;
  final bool smokingAllowed;
  final int maxOccupants;
  final List<String> specialTerms;
  
  // Documents and legal
  final List<String> documentUrls;
  final String? digitalSignature;
  final DateTime? signedDate;
  final List<String> witnesses;
  
  // Renewal information
  final DateTime? lastRenewalDate;
  final DateTime? nextReviewDate;
  final double? renewalRentIncrease;
  
  // Termination information
  final DateTime? terminationDate;
  final String? terminationReason;
  final double? terminationPenalty;
  
  final Map<String, dynamic> metadata;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Lease({
    required this.id,
    required this.buildingId,
    required this.unitId,
    required this.landlordId,
    required this.tenantId,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.durationMonths,
    this.autoRenew = false,
    this.renewalNoticeMonths,
    required this.monthlyRent,
    required this.securityDeposit,
    this.brokerFee,
    this.paymentFrequency = RentPaymentFrequency.monthly,
    this.paymentDueDay = 1,
    this.lateFeeAmount,
    this.lateFeeDays,
    this.utilitiesIncluded = false,
    this.includedUtilities = const [],
    this.maintenanceFee,
    this.maintenanceIncluded = false,
    required this.unitArea,
    this.bedrooms,
    this.bathrooms,
    this.furnished = false,
    this.includedFurnishing = const [],
    this.amenities = const [],
    this.petsAllowed = false,
    this.smokingAllowed = false,
    this.maxOccupants = 2,
    this.specialTerms = const [],
    this.documentUrls = const [],
    this.digitalSignature,
    this.signedDate,
    this.witnesses = const [],
    this.lastRenewalDate,
    this.nextReviewDate,
    this.renewalRentIncrease,
    this.terminationDate,
    this.terminationReason,
    this.terminationPenalty,
    this.metadata = const {},
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Getters
  String get statusDisplay {
    switch (status) {
      case LeaseStatus.draft:
        return 'טיוטה';
      case LeaseStatus.active:
        return 'פעיל';
      case LeaseStatus.expired:
        return 'פג תוקף';
      case LeaseStatus.terminated:
        return 'הופסק';
      case LeaseStatus.renewed:
        return 'חודש';
    }
  }

  String get typeDisplay {
    switch (type) {
      case LeaseType.residential:
        return 'מגורים';
      case LeaseType.commercial:
        return 'מסחרי';
      case LeaseType.office:
        return 'משרד';
      case LeaseType.parking:
        return 'חניה';
      case LeaseType.storage:
        return 'מחסן';
    }
  }

  String get paymentFrequencyDisplay {
    switch (paymentFrequency) {
      case RentPaymentFrequency.monthly:
        return 'חודשי';
      case RentPaymentFrequency.quarterly:
        return 'רבעוני';
      case RentPaymentFrequency.yearly:
        return 'שנתי';
    }
  }

  bool get isExpiringSoon {
    final daysUntilExpiry = endDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 90 && daysUntilExpiry > 0; // Expiring within 90 days
  }

  bool get isExpired {
    return DateTime.now().isAfter(endDate) && status != LeaseStatus.renewed;
  }

  bool get needsRenewalNotice {
    if (renewalNoticeMonths == null) return false;
    final noticeDate = endDate.subtract(Duration(days: renewalNoticeMonths! * 30));
    return DateTime.now().isAfter(noticeDate) && status == LeaseStatus.active;
  }

  Color get statusColor {
    switch (status) {
      case LeaseStatus.draft:
        return Colors.grey;
      case LeaseStatus.active:
        return isExpiringSoon ? Colors.orange : Colors.green;
      case LeaseStatus.expired:
        return Colors.red;
      case LeaseStatus.terminated:
        return Colors.red;
      case LeaseStatus.renewed:
        return Colors.blue;
    }
  }

  double get totalMonthlyPayment {
    double total = monthlyRent;
    if (maintenanceFee != null) total += maintenanceFee!;
    return total;
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
  factory Lease.fromMap(Map<String, dynamic> data, String id) {
    return Lease(
      id: id,
      buildingId: data['buildingId'] ?? '',
      unitId: data['unitId'] ?? '',
      landlordId: data['landlordId'] ?? '',
      tenantId: data['tenantId'] ?? '',
      type: LeaseType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => LeaseType.residential,
      ),
      status: LeaseStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => LeaseStatus.draft,
      ),
      title: data['title'] ?? '',
      description: data['description'],
      startDate: _parseDateTime(data['startDate']),
      endDate: _parseDateTime(data['endDate']),
      durationMonths: data['durationMonths'] ?? 12,
      autoRenew: data['autoRenew'] ?? false,
      renewalNoticeMonths: data['renewalNoticeMonths'],
      monthlyRent: (data['monthlyRent'] ?? 0.0).toDouble(),
      securityDeposit: (data['securityDeposit'] ?? 0.0).toDouble(),
      brokerFee: data['brokerFee']?.toDouble(),
      paymentFrequency: RentPaymentFrequency.values.firstWhere(
        (e) => e.toString() == data['paymentFrequency'],
        orElse: () => RentPaymentFrequency.monthly,
      ),
      paymentDueDay: data['paymentDueDay'] ?? 1,
      lateFeeAmount: data['lateFeeAmount']?.toDouble(),
      lateFeeDays: data['lateFeeDays'],
      utilitiesIncluded: data['utilitiesIncluded'] ?? false,
      includedUtilities: List<String>.from(data['includedUtilities'] ?? []),
      maintenanceFee: data['maintenanceFee']?.toDouble(),
      maintenanceIncluded: data['maintenanceIncluded'] ?? false,
      unitArea: (data['unitArea'] ?? 0.0).toDouble(),
      bedrooms: data['bedrooms'],
      bathrooms: data['bathrooms'],
      furnished: data['furnished'] ?? false,
      includedFurnishing: List<String>.from(data['includedFurnishing'] ?? []),
      amenities: List<String>.from(data['amenities'] ?? []),
      petsAllowed: data['petsAllowed'] ?? false,
      smokingAllowed: data['smokingAllowed'] ?? false,
      maxOccupants: data['maxOccupants'] ?? 2,
      specialTerms: List<String>.from(data['specialTerms'] ?? []),
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      digitalSignature: data['digitalSignature'],
      signedDate: data['signedDate'] != null ? _parseDateTime(data['signedDate']) : null,
      witnesses: List<String>.from(data['witnesses'] ?? []),
      lastRenewalDate: data['lastRenewalDate'] != null ? _parseDateTime(data['lastRenewalDate']) : null,
      nextReviewDate: data['nextReviewDate'] != null ? _parseDateTime(data['nextReviewDate']) : null,
      renewalRentIncrease: data['renewalRentIncrease']?.toDouble(),
      terminationDate: data['terminationDate'] != null ? _parseDateTime(data['terminationDate']) : null,
      terminationReason: data['terminationReason'],
      terminationPenalty: data['terminationPenalty']?.toDouble(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      notes: data['notes'],
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'unitId': unitId,
      'landlordId': landlordId,
      'tenantId': tenantId,
      'type': type.toString(),
      'status': status.toString(),
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationMonths': durationMonths,
      'autoRenew': autoRenew,
      'renewalNoticeMonths': renewalNoticeMonths,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'brokerFee': brokerFee,
      'paymentFrequency': paymentFrequency.toString(),
      'paymentDueDay': paymentDueDay,
      'lateFeeAmount': lateFeeAmount,
      'lateFeeDays': lateFeeDays,
      'utilitiesIncluded': utilitiesIncluded,
      'includedUtilities': includedUtilities,
      'maintenanceFee': maintenanceFee,
      'maintenanceIncluded': maintenanceIncluded,
      'unitArea': unitArea,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'furnished': furnished,
      'includedFurnishing': includedFurnishing,
      'amenities': amenities,
      'petsAllowed': petsAllowed,
      'smokingAllowed': smokingAllowed,
      'maxOccupants': maxOccupants,
      'specialTerms': specialTerms,
      'documentUrls': documentUrls,
      'digitalSignature': digitalSignature,
      'signedDate': signedDate?.toIso8601String(),
      'witnesses': witnesses,
      'lastRenewalDate': lastRenewalDate?.toIso8601String(),
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'renewalRentIncrease': renewalRentIncrease,
      'terminationDate': terminationDate?.toIso8601String(),
      'terminationReason': terminationReason,
      'terminationPenalty': terminationPenalty,
      'metadata': metadata,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Copy with method
  Lease copyWith({
    String? id,
    String? buildingId,
    String? unitId,
    String? landlordId,
    String? tenantId,
    LeaseType? type,
    LeaseStatus? status,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMonths,
    bool? autoRenew,
    int? renewalNoticeMonths,
    double? monthlyRent,
    double? securityDeposit,
    double? brokerFee,
    RentPaymentFrequency? paymentFrequency,
    int? paymentDueDay,
    double? lateFeeAmount,
    int? lateFeeDays,
    bool? utilitiesIncluded,
    List<String>? includedUtilities,
    double? maintenanceFee,
    bool? maintenanceIncluded,
    double? unitArea,
    int? bedrooms,
    int? bathrooms,
    bool? furnished,
    List<String>? includedFurnishing,
    List<String>? amenities,
    bool? petsAllowed,
    bool? smokingAllowed,
    int? maxOccupants,
    List<String>? specialTerms,
    List<String>? documentUrls,
    String? digitalSignature,
    DateTime? signedDate,
    List<String>? witnesses,
    DateTime? lastRenewalDate,
    DateTime? nextReviewDate,
    double? renewalRentIncrease,
    DateTime? terminationDate,
    String? terminationReason,
    double? terminationPenalty,
    Map<String, dynamic>? metadata,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Lease(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      unitId: unitId ?? this.unitId,
      landlordId: landlordId ?? this.landlordId,
      tenantId: tenantId ?? this.tenantId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationMonths: durationMonths ?? this.durationMonths,
      autoRenew: autoRenew ?? this.autoRenew,
      renewalNoticeMonths: renewalNoticeMonths ?? this.renewalNoticeMonths,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      brokerFee: brokerFee ?? this.brokerFee,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      lateFeeAmount: lateFeeAmount ?? this.lateFeeAmount,
      lateFeeDays: lateFeeDays ?? this.lateFeeDays,
      utilitiesIncluded: utilitiesIncluded ?? this.utilitiesIncluded,
      includedUtilities: includedUtilities ?? this.includedUtilities,
      maintenanceFee: maintenanceFee ?? this.maintenanceFee,
      maintenanceIncluded: maintenanceIncluded ?? this.maintenanceIncluded,
      unitArea: unitArea ?? this.unitArea,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      furnished: furnished ?? this.furnished,
      includedFurnishing: includedFurnishing ?? this.includedFurnishing,
      amenities: amenities ?? this.amenities,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      maxOccupants: maxOccupants ?? this.maxOccupants,
      specialTerms: specialTerms ?? this.specialTerms,
      documentUrls: documentUrls ?? this.documentUrls,
      digitalSignature: digitalSignature ?? this.digitalSignature,
      signedDate: signedDate ?? this.signedDate,
      witnesses: witnesses ?? this.witnesses,
      lastRenewalDate: lastRenewalDate ?? this.lastRenewalDate,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      renewalRentIncrease: renewalRentIncrease ?? this.renewalRentIncrease,
      terminationDate: terminationDate ?? this.terminationDate,
      terminationReason: terminationReason ?? this.terminationReason,
      terminationPenalty: terminationPenalty ?? this.terminationPenalty,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Lease(id: $id, title: $title, tenant: $tenantId, rent: $monthlyRent, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lease && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
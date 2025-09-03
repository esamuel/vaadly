import 'package:flutter/material.dart';

enum VendorCategory {
  plumbing, // אינסטלציה
  electrical, // חשמל
  hvac, // מיזוג אוויר
  cleaning, // ניקיון
  gardening, // גינון
  elevator, // מעליות
  security, // אבטחה
  structural, // מבני
  general, // כללי
  painting, // צביעה
  carpentry, // נגרות
  roofing, // גגות
}

enum VendorStatus {
  active, // פעיל
  inactive, // לא פעיל
  suspended, // מושהה
  blacklisted, // ברשימה שחורה
}

class Vendor {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String? email;
  final String? website;
  final String address;
  final String city;
  final String postalCode;
  final String country;
  final List<VendorCategory> categories;
  final VendorStatus status;
  final String? licenseNumber;
  final String? insuranceInfo;
  final double? hourlyRate;
  final double? rating;
  final int completedJobs;
  final int totalJobs;
  final String? notes;
  final List<String> photoUrls;
  final List<String> documentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Vendor({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.email,
    this.website,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.categories,
    required this.status,
    this.licenseNumber,
    this.insuranceInfo,
    this.hourlyRate,
    this.rating,
    this.completedJobs = 0,
    this.totalJobs = 0,
    this.notes,
    this.photoUrls = const [],
    this.documentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Getters for display
  String get statusDisplay {
    switch (status) {
      case VendorStatus.active:
        return 'פעיל';
      case VendorStatus.inactive:
        return 'לא פעיל';
      case VendorStatus.suspended:
        return 'מושהה';
      case VendorStatus.blacklisted:
        return 'ברשימה שחורה';
    }
  }

  Color get statusColor {
    switch (status) {
      case VendorStatus.active:
        return Colors.green;
      case VendorStatus.inactive:
        return Colors.grey;
      case VendorStatus.suspended:
        return Colors.orange;
      case VendorStatus.blacklisted:
        return Colors.red;
    }
  }

  String get fullAddress => '$address, $city, $postalCode, $country';

  double get successRate =>
      totalJobs > 0 ? (completedJobs / totalJobs * 100) : 0.0;

  String get successRateDisplay => '${successRate.toStringAsFixed(1)}%';

  String getCategoryDisplay(VendorCategory category) {
    switch (category) {
      case VendorCategory.plumbing:
        return 'אינסטלציה';
      case VendorCategory.electrical:
        return 'חשמל';
      case VendorCategory.hvac:
        return 'מיזוג אוויר';
      case VendorCategory.cleaning:
        return 'ניקיון';
      case VendorCategory.gardening:
        return 'גינון';
      case VendorCategory.elevator:
        return 'מעליות';
      case VendorCategory.security:
        return 'אבטחה';
      case VendorCategory.structural:
        return 'מבני';
      case VendorCategory.general:
        return 'כללי';
      case VendorCategory.painting:
        return 'צביעה';
      case VendorCategory.carpentry:
        return 'נגרות';
      case VendorCategory.roofing:
        return 'גגות';
    }
  }

  String get categoriesDisplay =>
      categories.map((c) => getCategoryDisplay(c)).join(', ');

  // Factory methods
  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      website: map['website'],
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      categories: (map['categories'] as List<dynamic>? ?? []).map((category) {
        return VendorCategory.values.firstWhere(
          (e) => e.toString().split('.').last == category,
          orElse: () => VendorCategory.general,
        );
      }).toList(),
      status: VendorStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => VendorStatus.active,
      ),
      licenseNumber: map['licenseNumber'],
      insuranceInfo: map['insuranceInfo'],
      hourlyRate: map['hourlyRate']?.toDouble(),
      rating: map['rating']?.toDouble(),
      completedJobs: map['completedJobs'] ?? 0,
      totalJobs: map['totalJobs'] ?? 0,
      notes: map['notes'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'categories':
          categories.map((c) => c.toString().split('.').last).toList(),
      'status': status.toString().split('.').last,
      'licenseNumber': licenseNumber,
      'insuranceInfo': insuranceInfo,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'completedJobs': completedJobs,
      'totalJobs': totalJobs,
      'notes': notes,
      'photoUrls': photoUrls,
      'documentUrls': documentUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Copy with method for updates
  Vendor copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    List<VendorCategory>? categories,
    VendorStatus? status,
    String? licenseNumber,
    String? insuranceInfo,
    double? hourlyRate,
    double? rating,
    int? completedJobs,
    int? totalJobs,
    String? notes,
    List<String>? photoUrls,
    List<String>? documentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      categories: categories ?? this.categories,
      status: status ?? this.status,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      totalJobs: totalJobs ?? this.totalJobs,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

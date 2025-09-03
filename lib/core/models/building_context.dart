import 'package:cloud_firestore/cloud_firestore.dart';

class BuildingContext {
  final String buildingId;
  final String buildingName;
  final String buildingCode; // Unique code for URL access
  final String address;
  final String managerName;
  final String managerPhone;
  final String managerEmail;
  final bool isActive;
  final DateTime createdAt;

  const BuildingContext({
    required this.buildingId,
    required this.buildingName,
    required this.buildingCode,
    required this.address,
    required this.managerName,
    required this.managerPhone,
    required this.managerEmail,
    required this.isActive,
    required this.createdAt,
  });

  BuildingContext.create({
    required String buildingId,
    required String buildingName,
    required String buildingCode,
    required String address,
    required String managerName,
    required String managerPhone,
    required String managerEmail,
    required bool isActive,
    DateTime? createdAt,
  }) : this(
         buildingId: buildingId,
         buildingName: buildingName,
         buildingCode: buildingCode,
         address: address,
         managerName: managerName,
         managerPhone: managerPhone,
         managerEmail: managerEmail,
         isActive: isActive,
         createdAt: createdAt ?? DateTime.now(),
       );

  factory BuildingContext.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BuildingContext.fromMap(data, doc.id);
  }

  factory BuildingContext.fromMap(Map<String, dynamic> data, String id) {
    return BuildingContext(
      buildingId: id,
      buildingName: data['name'] ?? '',
      buildingCode: data['buildingCode'] ?? '',
      address: data['fullAddress'] ?? '${data['address'] ?? ''}, ${data['city'] ?? ''}',
      managerName: data['buildingManager'] ?? '',
      managerPhone: data['managerPhone'] ?? '',
      managerEmail: data['managerEmail'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingCode': buildingCode,
      'name': buildingName,
      'address': address,
      'buildingManager': managerName,
      'managerPhone': managerPhone,
      'managerEmail': managerEmail,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get residentPortalUrl => 'https://vaadly.app/building/$buildingCode';
  String get committeePortalUrl => 'https://vaadly.app/manage/$buildingCode';

  @override
  String toString() {
    return 'BuildingContext(id: $buildingId, name: $buildingName, code: $buildingCode)';
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class Building {
  final String id;
  final String name;
  final String address;
  final int totalUnits;
  final DateTime createdAt;
  final DateTime updatedAt;

  Building({
    required this.id,
    required this.name,
    required this.address,
    required this.totalUnits,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Building.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Building(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      totalUnits: data['totalUnits'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'totalUnits': totalUnits,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class BuildingMember {
  final String uid;
  final String buildingId;
  final String role; // 'committee' | 'resident' | 'vendor_user' | 'super_admin'
  final String? unitNumber;
  final DateTime joinedAt;
  final bool isActive;

  BuildingMember({
    required this.uid,
    required this.buildingId,
    required this.role,
    this.unitNumber,
    required this.joinedAt,
    required this.isActive,
  });

  factory BuildingMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BuildingMember(
      uid: doc.id,
      buildingId: data['buildingId'] ?? '',
      role: data['role'] ?? 'resident',
      unitNumber: data['unitNumber'],
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'role': role,
      'unitNumber': unitNumber,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
    };
  }
}

class Unit {
  final String id;
  final String buildingId;
  final String number;
  final String? ownerUid;
  final String status; // 'occupied' | 'vacant' | 'maintenance'
  final DateTime createdAt;

  Unit({
    required this.id,
    required this.buildingId,
    required this.number,
    this.ownerUid,
    required this.status,
    required this.createdAt,
  });

  factory Unit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Unit(
      id: doc.id,
      buildingId: data['buildingId'] ?? '',
      number: data['number'] ?? '',
      ownerUid: data['ownerUid'],
      status: data['status'] ?? 'vacant',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'number': number,
      'ownerUid': ownerUid,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

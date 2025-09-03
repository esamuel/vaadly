import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  appOwner, // Platform owner (you) - manages multiple buildings
  buildingCommittee, // Building committee - manages specific building
  resident, // Building resident - limited access
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.appOwner:
        return 'App Owner';
      case UserRole.buildingCommittee:
        return 'Building Committee';
      case UserRole.resident:
        return 'Resident';
    }
  }
}

enum AccessLevel {
  read,
  write,
  admin,
}

class VaadlyUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final Map<String, String>
      buildingAccess; // buildingId -> access type (committee/resident)
  final Map<String, String>? unitAccess; // unitId -> buildingId (for residents)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final List<String>
      permissions; // List of permissions for granular access control
  final String? ownerId; // Reference to app owner (for multi-tenancy)

  const VaadlyUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.buildingAccess,
    this.unitAccess,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.permissions = const [],
    this.ownerId,
  });

  // Convert from Firestore document
  factory VaadlyUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper function to parse timestamps (handles both Timestamp and String)
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          print('Warning: Could not parse timestamp string: $timestamp');
          return null;
        }
      }
      return null;
    }

    return VaadlyUser(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString() == data['role'],
        orElse: () => UserRole.resident,
      ),
      buildingAccess: Map<String, String>.from(data['buildingAccess'] ?? {}),
      unitAccess: data['unitAccess'] != null
          ? Map<String, String>.from(data['unitAccess'])
          : null,
      isActive: data['isActive'] ?? true,
      createdAt: parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseTimestamp(data['updatedAt']) ?? DateTime.now(),
      lastLogin: parseTimestamp(data['lastLogin']),
      permissions: List<String>.from(data['permissions'] ?? []),
      ownerId: data['ownerId'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString(),
      'buildingAccess': buildingAccess,
      'unitAccess': unitAccess,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'permissions': permissions,
      'ownerId': ownerId,
    };
  }

  static Map<String, AccessLevel> _parseAccessMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(
          key,
          AccessLevel.values.firstWhere(
            (a) => a.toString().split('.').last == value,
            orElse: () => AccessLevel.read,
          ),
        ));
  }

  static Map<String, String> _serializeAccessMap(
      Map<String, AccessLevel> access) {
    return access.map((key, value) => MapEntry(
          key,
          value.toString().split('.').last,
        ));
  }

  // Helper methods
  bool get isAppOwner => role == UserRole.appOwner;
  bool get isBuildingCommittee => role == UserRole.buildingCommittee;
  bool get isResident => role == UserRole.resident;

  bool canAccessBuilding(String buildingId) {
    if (isAppOwner) return true;
    return buildingAccess.containsKey(buildingId) ||
        buildingAccess.containsKey('all');
  }

  bool canManageBuilding(String buildingId) {
    if (isAppOwner) return true;
    return buildingAccess[buildingId] == 'admin';
  }

  bool canEditBuilding(String buildingId) {
    if (isAppOwner) return true;
    final access = buildingAccess[buildingId];
    return access == 'write' || access == 'admin';
  }

  List<String> get accessibleBuildings => buildingAccess.keys.toList();

  String? getResidentUnit(String buildingId) {
    if (!isResident || unitAccess == null) return null;
    return unitAccess!.entries
        .firstWhere(
          (entry) => entry.value == buildingId,
          orElse: () => const MapEntry('', ''),
        )
        .key;
  }

  VaadlyUser copyWith({
    String? email,
    String? name,
    UserRole? role,
    Map<String, String>? buildingAccess,
    Map<String, String>? unitAccess,
    bool? isActive,
    DateTime? lastLogin,
  }) {
    return VaadlyUser(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      buildingAccess: buildingAccess ?? this.buildingAccess,
      unitAccess: unitAccess ?? this.unitAccess,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastLogin: lastLogin ?? this.lastLogin,
      permissions: permissions,
      ownerId: ownerId,
    );
  }

  @override
  String toString() {
    return 'VaadlyUser(id: $id, email: $email, role: $role, buildings: ${buildingAccess.keys})';
  }
}

// Factory for creating default users
class UserFactory {
  static VaadlyUser createAppOwner({
    required String id,
    required String email,
    required String name,
  }) {
    return VaadlyUser(
      id: id,
      email: email,
      name: name,
      role: UserRole.appOwner,
      buildingAccess: {
        'all': 'admin'
      }, // App owners have access to all buildings by role
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static VaadlyUser createBuildingCommittee({
    required String id,
    required String email,
    required String name,
    required String buildingId,
  }) {
    return VaadlyUser(
      id: id,
      email: email,
      name: name,
      role: UserRole.buildingCommittee,
      buildingAccess: {buildingId: 'admin'},
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static VaadlyUser createResident({
    required String id,
    required String email,
    required String name,
    required String buildingId,
    required String unitId,
  }) {
    return VaadlyUser(
      id: id,
      email: email,
      name: name,
      role: UserRole.resident,
      buildingAccess: {buildingId: 'read'},
      unitAccess: {unitId: buildingId},
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

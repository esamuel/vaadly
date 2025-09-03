import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user.dart';
import '../models/app_owner.dart';

/// Multi-tenant authentication service
/// Handles App Owner, Building Committee, and Resident authentication
class MultiTenantAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static VaadlyUser? _currentUser;
  static String? _currentUserEmail;
  static String? _currentOwnerId; // New: Track which app owner this user belongs to
  static AppOwner? _currentAppOwner; // New: Current app owner context

  // Current user getters
  static VaadlyUser? get currentUser => _currentUser;
  static String? get currentUserEmail => _currentUserEmail;
  static String? get currentOwnerId => _currentOwnerId;
  static AppOwner? get currentAppOwner => _currentAppOwner;
  static bool get isLoggedIn => _currentUser != null;

  // Role checks
  static bool get isAppOwner => _currentUser?.role == UserRole.appOwner;
  static bool get isBuildingCommittee => _currentUser?.role == UserRole.buildingCommittee;
  static bool get isResident => _currentUser?.role == UserRole.resident;

  // Initialize auth service
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('✅ MultiTenantAuthService initialized');
    } catch (e) {
      print('❌ MultiTenantAuthService initialization failed: $e');
      rethrow;
    }
  }

  // =================== APP OWNER AUTHENTICATION ===================

  /// Sign in as App Owner (platform administrator)
  static Future<VaadlyUser?> signInAsAppOwner(String email, String password) async {
    try {
      print('🏢 App Owner sign in attempt: $email');
      
      // Simple password validation
      if (password.length < 8) {
        throw Exception('App Owner password must be at least 8 characters');
      }

      // Query app owner by email
      final ownerQuery = await _firestore
          .collection('app_owners')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (ownerQuery.docs.isEmpty) {
        throw Exception('App Owner not found or inactive');
      }

      final ownerDoc = ownerQuery.docs.first;
      final appOwner = AppOwner.fromMap(ownerDoc.data(), ownerDoc.id);

      // Create user object for app owner
      final user = VaadlyUser(
        id: appOwner.id,
        email: appOwner.email,
        name: appOwner.name,
        role: UserRole.appOwner,
        isActive: appOwner.isActive,
        createdAt: appOwner.createdAt,
        updatedAt: appOwner.updatedAt,
        buildingAccess: {}, // App owner has access to all buildings
        permissions: ['all'], // Full platform access
      );

      // Set current context
      _currentUser = user;
      _currentUserEmail = email;
      _currentOwnerId = appOwner.id;
      _currentAppOwner = appOwner;

      print('✅ App Owner signed in: ${user.name} (${appOwner.company})');
      return user;

    } catch (e) {
      print('❌ App Owner sign in error: $e');
      rethrow;
    }
  }

  // =================== BUILDING COMMITTEE AUTHENTICATION ===================

  /// Sign in as Building Committee (with owner context)
  static Future<VaadlyUser?> signInAsBuildingCommittee(String email, String password, {String? buildingCode}) async {
    try {
      print('🏘️ Building Committee sign in: $email');
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Find user in multi-tenant structure
      final userResult = await _findUserInTenantStructure(email, UserRole.buildingCommittee);
      if (userResult == null) {
        throw Exception('Building Committee user not found');
      }

      final user = userResult['user'] as VaadlyUser;
      final ownerId = userResult['ownerId'] as String;
      final appOwner = userResult['appOwner'] as AppOwner;

      // Set current context
      _currentUser = user;
      _currentUserEmail = email;
      _currentOwnerId = ownerId;
      _currentAppOwner = appOwner;

      print('✅ Building Committee signed in: ${user.name} (Owner: ${appOwner.company})');
      return user;

    } catch (e) {
      print('❌ Building Committee sign in error: $e');
      rethrow;
    }
  }

  // =================== RESIDENT AUTHENTICATION ===================

  /// Sign in as Resident (with building context)
  static Future<VaadlyUser?> signInAsResident(String email, String password, {String? buildingCode}) async {
    try {
      print('🏠 Resident sign in: $email');
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Find user in multi-tenant structure
      final userResult = await _findUserInTenantStructure(email, UserRole.resident);
      if (userResult == null) {
        throw Exception('Resident not found');
      }

      final user = userResult['user'] as VaadlyUser;
      final ownerId = userResult['ownerId'] as String;
      final appOwner = userResult['appOwner'] as AppOwner;

      // Set current context
      _currentUser = user;
      _currentUserEmail = email;
      _currentOwnerId = ownerId;
      _currentAppOwner = appOwner;

      print('✅ Resident signed in: ${user.name}');
      return user;

    } catch (e) {
      print('❌ Resident sign in error: $e');
      rethrow;
    }
  }

  // =================== TENANT CONTEXT METHODS ===================

  /// Get available buildings for current user based on role
  static Future<List<Map<String, dynamic>>> getAvailableBuildings() async {
    if (_currentUser == null || _currentOwnerId == null) return [];

    try {
      final buildings = <Map<String, dynamic>>[];

      if (isAppOwner) {
        // App owner can access all their buildings
        final buildingsSnapshot = await _firestore
            .collection('app_owners')
            .doc(_currentOwnerId)
            .collection('buildings')
            .get();

        for (final doc in buildingsSnapshot.docs) {
          buildings.add({
            'id': doc.id,
            'name': doc.data()['name'] ?? 'Unknown Building',
            'data': doc.data(),
          });
        }
      } else {
        // Building committee/residents: only buildings they have access to
        final accessibleBuildingIds = _currentUser!.buildingAccess.keys.toList();
        for (final buildingId in accessibleBuildingIds) {
          final doc = await _firestore
              .collection('app_owners')
              .doc(_currentOwnerId)
              .collection('buildings')
              .doc(buildingId)
              .get();

          if (doc.exists) {
            buildings.add({
              'id': doc.id,
              'name': doc.data()!['name'] ?? 'Unknown Building',
              'data': doc.data(),
            });
          }
        }
      }

      return buildings;
    } catch (e) {
      print('❌ Error getting available buildings: $e');
      return [];
    }
  }

  /// Get current tenant context (ownerId, buildingId)
  static Map<String, String?> getCurrentTenantContext() {
    return {
      'ownerId': _currentOwnerId,
      'buildingId': _currentUser?.buildingAccess.keys.first,
      'userId': _currentUser?.id,
    };
  }

  /// Validate access to specific building
  static bool canAccessBuilding(String buildingId) {
    if (_currentUser == null) return false;
    
    // App owners can access all their buildings
    if (isAppOwner) return true;
    
    // Other users need explicit building access
    return _currentUser!.buildingAccess.containsKey(buildingId);
  }

  // =================== USER MANAGEMENT ===================

  /// Create new building committee user
  static Future<String?> createBuildingCommitteeUser({
    required String ownerId,
    required String buildingId,
    required String name,
    required String email,
    required List<String> permissions,
  }) async {
    try {
      print('👥 Creating building committee user: $email');

      final user = VaadlyUser(
        id: '', // Will be set by Firestore
        email: email.toLowerCase().trim(),
        name: name,
        role: UserRole.buildingCommittee,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        buildingAccess: {buildingId: 'committee'},
        permissions: permissions,
      );

      // Store user in tenant-specific collection
      final docRef = await _firestore
          .collection('app_owners')
          .doc(ownerId)
          .collection('users')
          .add(user.toMap());

      print('✅ Building committee user created: ${docRef.id}');
      return docRef.id;

    } catch (e) {
      print('❌ Error creating building committee user: $e');
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      _currentUser = null;
      _currentUserEmail = null;
      _currentOwnerId = null;
      _currentAppOwner = null;
      print('✅ User signed out');
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }

  // =================== PRIVATE HELPERS ===================

  /// Find user in multi-tenant structure
  static Future<Map<String, dynamic>?> _findUserInTenantStructure(String email, UserRole expectedRole) async {
    try {
      // Search across all app owners for the user
      final ownersSnapshot = await _firestore.collection('app_owners').get();
      
      for (final ownerDoc in ownersSnapshot.docs) {
        final ownerId = ownerDoc.id;
        final appOwner = AppOwner.fromMap(ownerDoc.data(), ownerId);
        
        // Search for user in this owner's users collection
        final userQuery = await _firestore
            .collection('app_owners')
            .doc(ownerId)
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase().trim())
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;
          final userData = userDoc.data();
          
          final user = VaadlyUser(
            id: userDoc.id,
            email: userData['email'],
            name: userData['name'],
            role: UserRole.values.firstWhere(
              (role) => role.toString() == userData['role'],
              orElse: () => expectedRole,
            ),
            isActive: userData['isActive'] ?? true,
            createdAt: _parseDateTime(userData['createdAt']),
            updatedAt: _parseDateTime(userData['updatedAt']),
            buildingAccess: Map<String, String>.from(userData['buildingAccess'] ?? {}),
            permissions: List<String>.from(userData['permissions'] ?? []),
          );

          return {
            'user': user,
            'ownerId': ownerId,
            'appOwner': appOwner,
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Error finding user in tenant structure: $e');
      return null;
    }
  }

  /// Parse DateTime from Firestore data
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }
}
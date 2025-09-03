import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user.dart';

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static VaadlyUser? _currentUser;
  static String? _currentUserEmail;

  // Current user getters
  static VaadlyUser? get currentUser => _currentUser;
  static String? get currentUserEmail => _currentUserEmail;
  static bool get isLoggedIn => _currentUser != null;

  // Initialize auth service
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('✅ AuthService initialized');
    } catch (e) {
      print('❌ AuthService initialization failed: $e');
      rethrow;
    }
  }

  // Simple email-based authentication (for demo purposes)
  static Future<VaadlyUser?> signInWithEmail(
      String email, String password) async {
    try {
      print('🔐 Attempting sign in for: $email');

      // For demo: Simple password validation
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Query user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found or inactive');
      }

      final userDoc = userQuery.docs.first;
      final user = VaadlyUser.fromFirestore(userDoc);

      // Update last login
      await _firestore.collection('users').doc(user.id).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });

      _currentUser = user.copyWith(lastLogin: DateTime.now());
      _currentUserEmail = email;

      print('✅ Successfully signed in: ${user.name} (${user.role})');
      return _currentUser;
    } catch (e) {
      print('❌ Sign in failed: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    _currentUser = null;
    _currentUserEmail = null;
    print('✅ User signed out');
  }

  // Create new user (admin function)
  static Future<VaadlyUser> createUser({
    required String email,
    required String name,
    required UserRole role,
    required Map<String, String> buildingAccess,
    Map<String, String>? unitAccess,
  }) async {
    try {
      print('👤 Creating user: $email ($role)');

      // Check if user already exists
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('User with this email already exists');
      }

      // Create user document
      final userDoc = _firestore.collection('users').doc();
      final user = VaadlyUser(
        id: userDoc.id,
        email: email.toLowerCase().trim(),
        name: name,
        role: role,
        buildingAccess: buildingAccess,
        unitAccess: unitAccess,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userDoc.set(user.toMap());
      print('✅ User created successfully: ${user.id}');

      return user;
    } catch (e) {
      print('❌ Failed to create user: $e');
      rethrow;
    }
  }

  // Get user by ID
  static Future<VaadlyUser?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      return VaadlyUser.fromFirestore(userDoc);
    } catch (e) {
      print('❌ Failed to get user by ID: $e');
      return null;
    }
  }

  // Get users by building access
  static Future<List<VaadlyUser>> getUsersByBuilding(String buildingId) async {
    try {
      // Query users who have access to this building
      final usersQuery = await _firestore
          .collection('users')
          .where('buildingAccess.$buildingId', isNotEqualTo: null)
          .get();

      return usersQuery.docs
          .map((doc) => VaadlyUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Failed to get users by building: $e');
      return [];
    }
  }

  // Get all committee members for a building
  static Future<List<VaadlyUser>> getBuildingCommitteeMembers(
      String buildingId) async {
    try {
      final users = await getUsersByBuilding(buildingId);
      return users
          .where((user) =>
              user.isBuildingCommittee && user.canManageBuilding(buildingId))
          .toList();
    } catch (e) {
      print('❌ Failed to get committee members: $e');
      return [];
    }
  }

  // Get all residents for a building
  static Future<List<VaadlyUser>> getBuildingResidents(
      String buildingId) async {
    try {
      final users = await getUsersByBuilding(buildingId);
      return users.where((user) => user.isResident).toList();
    } catch (e) {
      print('❌ Failed to get building residents: $e');
      return [];
    }
  }

  // Update user access
  static Future<void> updateUserAccess({
    required String userId,
    Map<String, String>? buildingAccess,
    Map<String, String>? unitAccess,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (buildingAccess != null) {
        updates['buildingAccess'] = buildingAccess;
      }
      if (unitAccess != null) {
        updates['unitAccess'] = unitAccess;
      }

      await _firestore.collection('users').doc(userId).update(updates);

      // Update current user if it's the same user
      if (_currentUser?.id == userId) {
        _currentUser = _currentUser!.copyWith(
          buildingAccess: buildingAccess ?? _currentUser!.buildingAccess,
          unitAccess: unitAccess ?? _currentUser!.unitAccess,
        );
      }

      print('✅ User access updated: $userId');
    } catch (e) {
      print('❌ Failed to update user access: $e');
      rethrow;
    }
  }

  // Deactivate user
  static Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
      });
      print('✅ User deactivated: $userId');
    } catch (e) {
      print('❌ Failed to deactivate user: $e');
      rethrow;
    }
  }

  // Permission check helpers
  static bool canAccessBuilding(String buildingId) {
    return _currentUser?.canAccessBuilding(buildingId) ?? false;
  }

  static bool canManageBuilding(String buildingId) {
    return _currentUser?.canManageBuilding(buildingId) ?? false;
  }

  static bool canEditBuilding(String buildingId) {
    return _currentUser?.canEditBuilding(buildingId) ?? false;
  }

  static bool get isAppOwner => _currentUser?.isAppOwner ?? false;
  static bool get isBuildingCommittee =>
      _currentUser?.isBuildingCommittee ?? false;
  static bool get isResident => _currentUser?.isResident ?? false;

  // Initialize demo users
  static Future<void> initializeDemoUsers() async {
    try {
      print('🎭 Initializing demo users...');

      // Check if demo users already exist
      final existingUsers = await _firestore.collection('users').limit(1).get();
      if (existingUsers.docs.isNotEmpty) {
        print('✅ Demo users already exist');
        // Fix any existing timestamp issues
        await _fixTimestampIssues();
        return;
      }

      // Create demo app owner
      final appOwner = UserFactory.createAppOwner(
        id: 'demo_owner',
        email: 'owner@vaadly.com',
        name: 'Samuel - App Owner',
      );

      // Create demo building committee
      final committee = UserFactory.createBuildingCommittee(
        id: 'demo_committee',
        email: 'committee@shalom-tower.co.il',
        name: 'יוסי כהן - Building Manager',
        buildingId: 'demo_building_1',
      );

      // Create demo resident
      final resident = UserFactory.createResident(
        id: 'demo_resident',
        email: 'resident@example.com',
        name: 'משה לוי - Resident',
        buildingId: 'demo_building_1',
        unitId: 'unit_101',
      );

      // Save users to Firestore
      await _firestore
          .collection('users')
          .doc(appOwner.id)
          .set(appOwner.toMap());
      await _firestore
          .collection('users')
          .doc(committee.id)
          .set(committee.toMap());
      await _firestore
          .collection('users')
          .doc(resident.id)
          .set(resident.toMap());

      print('✅ Demo users created:');
      print('   App Owner: owner@vaadly.com (password: 123456)');
      print('   Committee: committee@shalom-tower.co.il (password: 123456)');
      print('   Resident: resident@example.com (password: 123456)');
    } catch (e) {
      print('❌ Failed to initialize demo users: $e');
    }
  }

  // Fix timestamp issues in existing users
  static Future<void> _fixTimestampIssues() async {
    try {
      print('🔧 Checking for timestamp issues...');

      final usersQuery = await _firestore.collection('users').get();
      int fixedCount = 0;

      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};

        // Fix createdAt
        if (data['createdAt'] is String) {
          try {
            final date = DateTime.parse(data['createdAt'] as String);
            updates['createdAt'] = Timestamp.fromDate(date);
            print('   ✅ Fixed createdAt for ${data['email']}');
          } catch (e) {
            print('   ❌ Could not parse createdAt: ${data['createdAt']}');
          }
        }

        // Fix updatedAt
        if (data['updatedAt'] is String) {
          try {
            final date = DateTime.parse(data['updatedAt'] as String);
            updates['updatedAt'] = Timestamp.fromDate(date);
            print('   ✅ Fixed updatedAt for ${data['email']}');
          } catch (e) {
            print('   ❌ Could not parse updatedAt: ${data['updatedAt']}');
          }
        }

        // Fix lastLogin
        if (data['lastLogin'] is String) {
          try {
            final date = DateTime.parse(data['lastLogin'] as String);
            updates['lastLogin'] = Timestamp.fromDate(date);
            print('   ✅ Fixed lastLogin for ${data['email']}');
          } catch (e) {
            print('   ❌ Could not parse lastLogin: ${data['lastLogin']}');
          }
        }

        // Update the document if there are changes
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(doc.id).update(updates);
          fixedCount++;
        }
      }

      if (fixedCount > 0) {
        print('🎉 Fixed timestamp issues for $fixedCount users');
      } else {
        print('✅ No timestamp issues found');
      }
    } catch (e) {
      print('❌ Error fixing timestamp issues: $e');
    }
  }
}

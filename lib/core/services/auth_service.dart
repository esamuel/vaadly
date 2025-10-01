import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'building_context_service.dart';
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
      // Disable Auth emulator for production Firebase use
      // Note: Emulator was disabled to use real Firebase project
      print('ℹ️ Using production Firebase (emulator disabled)');
      print('✅ AuthService initialized');
    } catch (e) {
      print('❌ AuthService initialization failed: $e');
      rethrow;
    }
  }

  // Send password reset email via Firebase Auth
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      final auth = fb_auth.FirebaseAuth.instance;
      await auth.sendPasswordResetEmail(email: email.toLowerCase().trim());
      print('✉️ Password reset email sent to $email');
    } on fb_auth.FirebaseAuthException catch (e) {
      // Provide friendly messages
      switch (e.code) {
        case 'invalid-email':
          throw Exception('כתובת אימייל לא תקינה');
        case 'user-not-found':
          throw Exception('לא נמצא משתמש עם האימייל הזה');
        default:
          throw Exception('שגיאה בשליחת קישור לאיפוס סיסמה: ${e.message}');
      }
    } catch (e) {
      print('❌ sendPasswordResetEmail failed: $e');
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

      // Query all profiles by email (can exist multiple: owner + committee)
      final userQueryAll = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('isActive', isEqualTo: true)
          .get();

      if (userQueryAll.docs.isEmpty) {
        throw Exception('User not found or inactive');
      }

      // Choose the best matching profile
      final candidates = userQueryAll.docs
          .map((d) => VaadlyUser.fromFirestore(d))
          .toList();

      VaadlyUser user = candidates.first;
      // If building context is available, prefer a profile with access to it
      try {
        final ctxId = BuildingContextService.buildingId;
        final ctxCode = BuildingContextService.currentBuilding?.buildingCode;
        final byAccess = candidates.where((u) {
          final a = u.buildingAccess;
          return a.containsKey('all') ||
              (ctxId != null && a.containsKey(ctxId)) ||
              (ctxCode != null && a.containsKey(ctxCode));
        }).toList();
        if (byAccess.isNotEmpty) {
          // Prefer admin access over read
          byAccess.sort((a, b) {
            final aid = a.buildingAccess[ctxId ?? ''] ?? a.buildingAccess[ctxCode ?? ''] ?? '';
            final bid = b.buildingAccess[ctxId ?? ''] ?? b.buildingAccess[ctxCode ?? ''] ?? '';
            if (aid == 'admin' && bid != 'admin') return -1;
            if (bid == 'admin' && aid != 'admin') return 1;
            return 0;
          });
          user = byAccess.first;
        } else {
          // Otherwise prefer committee over owner/resident
          final committee = candidates.where((u) => u.isBuildingCommittee).toList();
          if (committee.isNotEmpty) {
            user = committee.first;
          }
        }
      } catch (_) {}

      print('🔍 Selected profile role: ${user.role}');
      print('🔍 Parsed user role: ${user.role}');

      // Ensure Firebase Auth session (for Firestore security rules)
      final authUser = await _ensureAuthSession(email, password);

      // Ensure a corresponding users/<uid> doc exists for rules getUserData()
      await _ensureUserDocForUid(uid: authUser.uid, userFromProfile: user);

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
    try {
      await fb_auth.FirebaseAuth.instance.signOut();
    } catch (_) {}
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

  // Create Firebase Auth account with email and password
  static Future<fb_auth.User> createFirebaseAuthAccount(String email, String password) async {
    try {
      print('🔐 Creating Firebase Auth account for: $email');
      
      final auth = fb_auth.FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );
      
      print('✅ Firebase Auth account created successfully');
      return credential.user!;
    } catch (e) {
      print('❌ Failed to create Firebase Auth account: $e');
      
      // Rethrow with more specific error handling
      if (e is fb_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('האימייל כבר קיים במערכת');
          case 'invalid-email':
            throw Exception('כתובת אימייל לא תקינה');
          case 'weak-password':
            throw Exception('סיסמה חלשה מדי');
          case 'operation-not-allowed':
            throw Exception('פעולת יצירת משתמש לא מופעלת');
          default:
            throw Exception('שגיאה ביצירת חשבון Firebase: ${e.message}');
        }
      }
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
      
      // Always attempt to fix timestamp issues on existing users
      await _fixTimestampIssues();

      // Locate demo building id (created earlier by BuildingContextService)
      String? demoBuildingId;
      try {
        final ctx = await BuildingContextService.getBuildingByCode('shalom1234');
        demoBuildingId = ctx?.buildingId;
      } catch (_) {}

      // Ensure core demo users exist
      await _ensureUserByEmail(
        email: 'owner@vaadly.com',
        create: () => UserFactory.createAppOwner(
          id: 'demo_owner',
          email: 'owner@vaadly.com',
          name: 'Samuel - App Owner',
        ),
      );

      await _ensureUserByEmail(
        email: 'committee@shalom-tower.co.il',
        create: () => UserFactory.createBuildingCommittee(
          id: 'demo_committee',
          email: 'committee@shalom-tower.co.il',
          name: 'יוסי כהן - Building Manager',
          buildingId: demoBuildingId ?? 'pending_building',
        ),
      );

      await _ensureUserByEmail(
        email: 'resident@example.com',
        create: () => UserFactory.createResident(
          id: 'demo_resident',
          email: 'resident@example.com',
          name: 'משה לוי - Resident',
          buildingId: demoBuildingId ?? 'pending_building',
          unitId: 'unit_101',
        ),
      );

      // Ensure owner account for Samuel exists
      await _ensureUserByEmail(
        email: 'samuel.eskenasy@gmail.com',
        create: () => UserFactory.createAppOwner(
          id: 'owner_samuel',
          email: 'samuel.eskenasy@gmail.com',
          name: 'Samuel Eskenasy',
        ),
      );

      print('✅ Demo users verified/created');
      print('   App Owner: owner@vaadly.com (password: 123456)');
      print('   Committee: committee@shalom-tower.co.il (password: 123456)');
      print('   Resident: resident@example.com (password: 123456)');
    } catch (e) {
      print('❌ Failed to initialize demo users: $e');
    }
  }

  // Helper: ensure a user with email exists; create via factory when missing
  static Future<void> _ensureUserByEmail({
    required String email,
    required VaadlyUser Function() create,
  }) async {
    final existing = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      // Ensure active and correct role
      final doc = existing.docs.first;
      final data = doc.data();
      final expectedUser = create(); // Get the expected user configuration
      final updates = <String, dynamic>{};
      
      if (data['isActive'] != true) {
        updates['isActive'] = true;
      }
      
      // Check if role needs to be corrected
      final currentRoleRaw = (data['role'] ?? '').toString();
      final currentRoleShort = currentRoleRaw.contains('.') ? currentRoleRaw.split('.').last : currentRoleRaw;
      final expectedRoleShort = expectedUser.role.toString().split('.').last;
      if (currentRoleShort != expectedRoleShort) {
        updates['role'] = expectedRoleShort;
        print('🔧 Correcting role for ${data['email']}: $currentRoleShort → $expectedRoleShort');
      }
      
      // Apply updates if needed
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(doc.id).update(updates);
      }
      
      // Also ensure that if current auth matches this email, we have a uid-matching doc
      try {
        final current = fb_auth.FirebaseAuth.instance.currentUser;
        if (current != null && (current.email ?? '').toLowerCase() == email.toLowerCase()) {
          await _ensureUserDocForUid(uid: current.uid, userFromProfile: expectedUser);
        }
      } catch (_) {}
      // Continue to ensure Firebase Auth exists
    }
    
    VaadlyUser user;
    if (existing.docs.isNotEmpty) {
      // Re-fetch the document after potential updates
      final updatedDoc = await _firestore.collection('users').doc(existing.docs.first.id).get();
      user = VaadlyUser.fromFirestore(updatedDoc);
    } else {
      user = create();
      // Create profile doc with preferred ID
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      print('👤 Created Firestore user: $email (${user.role})');
    }
    
    // Always ensure Firebase Auth account exists for demo users
    try {
      final pwd = email == 'owner@vaadly.com' ? '123456' : (email == 'samuel.eskenasy@gmail.com' ? 'vaadly123' : '123456');
      print('🔐 Creating/ensuring Firebase Auth for: $email');
      final cred = await _ensureAuthSession(email, pwd);
      await _ensureUserDocForUid(uid: cred.uid, userFromProfile: user);
      print('✅ Firebase Auth account created/verified: $email');
    } catch (e) {
      print('⚠️ Failed to create Firebase Auth for $email: $e');
      // Continue anyway - at least Firestore doc exists
    }
  }

  // Create or sign in to auth user and return the fb user
  static Future<fb_auth.User> _ensureAuthSession(String email, String password) async {
    final auth = fb_auth.FirebaseAuth.instance;
    final normalizedEmail = email.toLowerCase().trim();
    try {
      // Prefer sign-in first to avoid unnecessary sign-up requests (400s from signUp endpoint)
      final cred = await auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      print('✅ Signed in existing Firebase Auth user: $normalizedEmail');
      return cred.user!;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Create the user if they don't exist
        try {
          final cred = await auth.createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
          print('✅ Created new Firebase Auth user: $normalizedEmail');
          return cred.user!;
        } catch (createError) {
          print('❌ Failed to create user $normalizedEmail: $createError');
          rethrow;
        }
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        // Do not attempt sign-up when password is wrong/invalid
        print('❌ Wrong/invalid password for $normalizedEmail');
        rethrow;
      } else if (e.code == 'too-many-requests') {
        print('⚠️ Too many requests when signing in $normalizedEmail');
        rethrow;
      }
      // Fallback
      print('❌ Firebase Auth error for $normalizedEmail: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Ensure there is a users/<uid> doc with at least role/email/name matching the profile
  static Future<void> _ensureUserDocForUid({required String uid, required VaadlyUser userFromProfile}) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final base = userFromProfile.toMap();
    if (!doc.exists) {
      await _firestore.collection('users').doc(uid).set({
        ...base,
        'email': userFromProfile.email.toLowerCase().trim(),
        'role': userFromProfile.role.toString().split('.').last,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('👤 Created users/$uid for security rules');
    } else {
      await _firestore.collection('users').doc(uid).update({
        'role': userFromProfile.role.toString().split('.').last,
        'name': userFromProfile.name,
        'email': userFromProfile.email.toLowerCase().trim(),
        'isActive': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('🔄 Updated users/$uid for security rules');
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

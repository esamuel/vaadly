import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/multi_tenant_auth_service.dart';
import '../services/building_context_service.dart';
import '../models/user.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/building_auth_screen.dart';
import '../../features/onboarding/committee_invitation_screen.dart';
import '../../features/dashboards/app_owner_dashboard_simple.dart';
import '../../features/dashboards/committee_dashboard.dart';
import '../../features/dashboards/resident_dashboard.dart';
import '../config/runtime_flags.dart';
import '../../features/buildings/building_selector_page.dart';

class AuthWrapper extends StatefulWidget {
  final String? buildingCode;
  final bool isManagementPortal;

  const AuthWrapper({
    super.key,
    this.buildingCode,
    this.isManagementPortal = false,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  // Development-only allowlist to bypass all tier checks
  static const Set<String> _adminAllowlist = {
    'admin@vaadly.dev',
  };

  bool _isAllowlisted(String email) =>
      _adminAllowlist.contains(email.trim().toLowerCase());

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await AuthService.initialize();
      // Seed demo data only when explicitly enabled
      if (kEnableDemoSeeding) {
        await BuildingContextService.initializeDemoBuildingContext();
        await AuthService.initializeDemoUsers();
      }
      
      // If building code is provided, set building context
      if (widget.buildingCode != null) {
        await BuildingContextService.setBuildingContext(widget.buildingCode!);
      }
    } catch (e) {
      print('❌ Auth wrapper initialization failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('מאתחל את ועד-לי...'),
              ],
            ),
          ),
        ),
      );
    }

    // Check if user is logged in (check both auth systems)
    final isLoggedInOldSystem = AuthService.isLoggedIn;
    final isLoggedInNewSystem = MultiTenantAuthService.isLoggedIn;
    
    if (!isLoggedInOldSystem && !isLoggedInNewSystem) {
      // If building code is provided, route based on portal type
      if (widget.buildingCode != null) {
        if (widget.isManagementPortal) {
          // Management portal: committee invitation / setup
          return CommitteeInvitationScreen(buildingCode: widget.buildingCode!);
        }
        // Resident portal: building auth (sign-in)
        return BuildingAuthScreen(buildingCode: widget.buildingCode!);
      }
      
      // Otherwise show general auth (for app owners and management)
      return const AuthScreen();
    }

    // Route to appropriate dashboard based on user role and context
    // Try new auth system first, then fall back to old system
    final user = MultiTenantAuthService.currentUser ?? AuthService.currentUser;
    
    // If no user found in either system, return to auth screen
    if (user == null) {
      print('⚠️ No user found in either auth system, redirecting to auth');
      return const AuthScreen();
    }
    
    // Quick allowlist bypass: full access for allowlisted emails
    if (_isAllowlisted(user.email)) {
      return const AppOwnerDashboard();
    }

    // Ensure we have a building context for committee/resident users
    if (!BuildingContextService.hasBuilding && (user.isBuildingCommittee || user.isResident)) {
      final accessible = user.accessibleBuildings;
      if (accessible.length == 1) {
        final key = accessible.first; // May be an ID or a building code
        // Fire-and-forget: don't await in build()
        Future(() async {
          try {
            await BuildingContextService.setBuildingContext(key);
            print('✅ Building context set automatically for user: ${BuildingContextService.buildingId}');
            if (mounted) setState(() {});
          } catch (e) {
            print('⚠️ Failed to set building context automatically: $e');
          }
        });
      }
    }

    // If we have a building context, ensure user has access (by id or code)
    if (BuildingContextService.hasBuilding) {
      final buildingId = BuildingContextService.buildingId!;
      final buildingCode = BuildingContextService.currentBuilding?.buildingCode;
      final access = user.buildingAccess;
      final hasAccess = user.isAppOwner ||
          access.containsKey('all') ||
          access.containsKey(buildingId) ||
          (buildingCode != null && access.containsKey(buildingCode));

      if (!hasAccess) {
        AuthService.signOut();
        return widget.buildingCode != null
            ? BuildingAuthScreen(buildingCode: widget.buildingCode!)
            : const AuthScreen();
      }
    }
    
    // If no building context yet and user has multiple options, let them choose
    final accessKeys = user.accessibleBuildings;
    final hasAll = user.buildingAccess.containsKey('all') || user.isAppOwner;
    if (!BuildingContextService.hasBuilding && (hasAll || accessKeys.length > 1)) {
      return const BuildingSelectorPage();
    }

    // Prefer context-aware routing: decide by access in current building
    if (BuildingContextService.hasBuilding) {
      final buildingId = BuildingContextService.buildingId!;
      final code = BuildingContextService.currentBuilding?.buildingCode;
      String? level;
      if (user.isAppOwner) {
        level = 'admin';
      } else {
        level = user.buildingAccess[buildingId] ?? (code != null ? user.buildingAccess[code] : null) ?? user.buildingAccess['all'];
      }
      if (level == 'admin') {
        return const CommitteeDashboard();
      }
      if (level != null) {
        return const ResidentDashboard();
      }
    }

    // If no building context, owners go to owner dashboard
    if (user.isAppOwner) {
      return const AppOwnerDashboard();
    }

    // Fallback to role-based when no building context or no specific access
    switch (user.role) {
      case UserRole.appOwner:
        return const AppOwnerDashboard();
      case UserRole.buildingCommittee:
        return const CommitteeDashboard();
      case UserRole.resident:
        return const ResidentDashboard();
    }
  }

  bool _shouldShowCommitteeInvitation() {
    // For now, always show committee invitation for building codes
    // This should be improved to check if the building already has committee setup
    return true;
  }
}

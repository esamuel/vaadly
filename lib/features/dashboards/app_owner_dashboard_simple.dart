import 'package:flutter/material.dart';
import 'package:vaadly/features/buildings/buildings_list_screen.dart';
import 'package:vaadly/features/finance/financial_module/pages/financial_management_page.dart';
import 'package:vaadly/features/pricing/pages/pricing_calculator_page.dart';
import 'package:vaadly/pages/firebase_residents_page.dart';
import 'package:vaadly/pages/firebase_maintenance_page.dart';
import 'package:vaadly/services/firebase_building_service.dart';
import 'package:vaadly/core/models/building.dart';
import '../../main_vaadly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vaadly/core/services/auth_service.dart';
import 'package:vaadly/core/config/app_links.dart';
import 'package:vaadly/services/firebase_activity_service.dart';

/// App Owner Dashboard - Your main SaaS business control center
/// This is where YOU manage your entire Vaadly platform
class AppOwnerDashboard extends StatefulWidget {
  const AppOwnerDashboard({super.key});

  @override
  State<AppOwnerDashboard> createState() => _AppOwnerDashboardState();
}

class _AppOwnerDashboardState extends State<AppOwnerDashboard> {
  // Owner tools controllers
  final _emailController = TextEditingController();
  final _buildingController = TextEditingController(); // code or id
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.business_center, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Vaadly - App Owner Dashboard'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_center,
                size: 64,
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Owner Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your SaaS business control center',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Quick navigation actions
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BuildingsListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.apartment),
                    label: const Text('בניינים'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FinancialManagementPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('ניהול כספי'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FutureBuilder<List<Building>>(
                            future: FirebaseBuildingService.getAllBuildings(),
                            builder: (context, snap) {
                              final buildings = snap.data ?? const <Building>[];
                              return FirebaseResidentsPage(buildings: buildings);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('דיירים'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FutureBuilder<List<Building>>(
                            future: FirebaseBuildingService.getAllBuildings(),
                            builder: (context, snap) {
                              final buildings = snap.data ?? const <Building>[];
                              return FirebaseMaintenancePage(buildings: buildings);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.build),
                    label: const Text('תחזוקה'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PricingCalculatorPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate),
                    label: const Text('מחשבון מחיר'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.apps),
                    label: const Text('אפליקציה ראשית'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                '🎉 Multi-Tenant Architecture Complete!',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready to onboard building committees',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Owner Tools',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'User Email',
                          prefixIcon: Icon(Icons.alternate_email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _buildingController,
                        decoration: const InputDecoration(
                          labelText: 'Building Code or ID',
                          prefixIcon: Icon(Icons.apartment),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _grantCommitteeAccess,
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Grant Committee Admin'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _sendPasswordReset,
                            icon: const Icon(Icons.mark_email_read_outlined),
                            label: const Text('Send Password Reset'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final code = _buildingController.text.trim();
                              if (code.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter building code to generate link')),
                                );
                                return;
                              }
                              final url = AppLinks.managePortal(code, canonical: true);
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Management Link'),
                                  content: SelectableText(url),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    )
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.link),
                            label: const Text('Generate Committee Link'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _migrateActivityNames,
                            icon: const Icon(Icons.history_toggle_off),
                            label: const Text('Migrate Activity Names'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _migrateAllActivityNames,
                            icon: const Icon(Icons.all_inclusive),
                            label: const Text('Migrate All Buildings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _grantCommitteeAccess() async {
    final email = _emailController.text.trim().toLowerCase();
    final codeOrId = _buildingController.text.trim();
    if (email.isEmpty || codeOrId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and building code/id')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      // Resolve building id by code or treat as id
      String buildingId = codeOrId;
      try {
        final q = await FirebaseFirestore.instance
            .collection('buildings')
            .where('buildingCode', isEqualTo: codeOrId)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          buildingId = q.docs.first.id;
        }
      } catch (_) {}

      // Lookup user by email
      final uq = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (uq.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found: $email')),
        );
        return;
      }
      final userDoc = uq.docs.first;
      final current = Map<String, dynamic>.from(userDoc['buildingAccess'] ?? {});
      current[buildingId] = 'admin';
      await userDoc.reference.update({'buildingAccess': current, 'updatedAt': FieldValue.serverTimestamp()});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Granted committee admin for $email on $buildingId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter user email')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await AuthService.sendPasswordResetEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _migrateActivityNames() async {
    final codeOrId = _buildingController.text.trim();
    if (codeOrId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter building code or id first')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      // Resolve id
      String buildingId = codeOrId;
      try {
        final q = await FirebaseFirestore.instance
            .collection('buildings')
            .where('buildingCode', isEqualTo: codeOrId)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) buildingId = q.docs.first.id;
      } catch (_) {}

      final updated = await FirebaseActivityService.migrateActivityUserNames(buildingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated $updated activity records')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _migrateAllActivityNames() async {
    setState(() => _isProcessing = true);
    try {
      final updated = await FirebaseActivityService.migrateActivityUserNamesAllBuildings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated $updated activity records across all buildings')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

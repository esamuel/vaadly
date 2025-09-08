import 'package:flutter/material.dart';
import 'package:vaadly/features/buildings/buildings_list_screen.dart';
import 'package:vaadly/features/finance/financial_module/pages/financial_management_page.dart';
import 'package:vaadly/features/pricing/pages/pricing_calculator_page.dart';
import 'package:vaadly/pages/firebase_residents_page.dart';
import 'package:vaadly/pages/firebase_maintenance_page.dart';
import 'package:vaadly/services/firebase_building_service.dart';
import 'package:vaadly/core/models/building.dart';

/// App Owner Dashboard - Your main SaaS business control center
/// This is where YOU manage your entire Vaadly platform
class AppOwnerDashboard extends StatefulWidget {
  const AppOwnerDashboard({super.key});

  @override
  State<AppOwnerDashboard> createState() => _AppOwnerDashboardState();
}

class _AppOwnerDashboardState extends State<AppOwnerDashboard> {
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
            ],
          ),
        ),
      ),
    );
  }
}
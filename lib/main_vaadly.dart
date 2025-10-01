import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/maintenance/maintenance_dashboard.dart';
import 'core/services/building_context_service.dart';

// Simplified Firebase Service
class SimpleFirebaseService {
  static FirebaseFirestore? _firestore;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      
      // Initialize demo building context
      await BuildingContextService.initializeDemoBuildingContext();
      
      // Initialize sample maintenance data
      await _initializeSampleMaintenanceData();
      
      print('✅ Firebase and sample data initialized');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized');
    }
    return _firestore!;
  }

  static Future<void> _initializeSampleMaintenanceData() async {
    try {
      final now = DateTime.now();
      
      // Check if data already exists
      final existingRequests = await _firestore!
          .collection('buildings')
          .doc('demo_building_1')
          .collection('maintenance_requests')
          .limit(1)
          .get();
          
      if (existingRequests.docs.isNotEmpty) {
        print('✅ Sample maintenance data already exists');
        return;
      }

      // Create sample maintenance requests
      final requests = [
        {
          'buildingId': 'demo_building_1',
          'residentId': 'resident_1',
          'title': 'דליפת מים בקומה 3',
          'description': 'יש דליפת מים מהתקרה בחדר המדרגות',
          'category': 'plumbing',
          'priority': 'high',
          'status': 'pending',
          'reportedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
          'location': 'קומה 3 - חדר מדרגות',
          'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
          'updatedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
          'isActive': true,
        },
        {
          'buildingId': 'demo_building_1',
          'residentId': 'resident_2',
          'title': 'תקלה במעלית',
          'description': 'המעלית לא עובדת כראוי',
          'category': 'elevator',
          'priority': 'urgent',
          'status': 'assigned',
          'assignedVendorId': 'vendor_1',
          'assignedVendorName': 'חברת מעליות גולדברג',
          'reportedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
          'assignedAt': now.subtract(const Duration(hours: 12)).toIso8601String(),
          'location': 'מעלית מרכזית',
          'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
          'updatedAt': now.subtract(const Duration(hours: 12)).toIso8601String(),
          'isActive': true,
        },
        {
          'buildingId': 'demo_building_1',
          'residentId': 'resident_3',
          'title': 'ניקיון גינה',
          'description': 'הגינה צריכה ניקוי וטיפוח',
          'category': 'gardening',
          'priority': 'normal',
          'status': 'pending',
          'reportedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
          'location': 'גינה ציבורית',
          'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
          'updatedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
          'isActive': true,
        },
      ];

      for (final req in requests) {
        await _firestore!
            .collection('buildings')
            .doc('demo_building_1')
            .collection('maintenance_requests')
            .add(req);
      }

      // Create committee vendor profiles
      final vendors = [
        {
          'name': 'חברת מעליות גולדברג',
          'contactEmail': 'service@goldberg-elevators.co.il',
          'contactPhone': '+972-50-700-0001',
          'serviceCategories': ['elevator'],
          'coverageRegions': ['tel-aviv'],
          'ratingAvg': 4.5,
          'jobsDone': 120,
          'slaAvgHours': 4.0,
        },
        {
          'name': 'אינסטלציה מקצועית',
          'contactEmail': 'info@pro-plumbing.co.il',
          'contactPhone': '+972-50-700-0002',
          'serviceCategories': ['plumbing'],
          'coverageRegions': ['tel-aviv'],
          'ratingAvg': 4.2,
          'jobsDone': 85,
          'slaAvgHours': 8.0,
        },
      ];

      final vendorIds = <String>[];
      for (final vendor in vendors) {
        final doc = await _firestore!
            .collection('buildings')
            .doc('demo_building_1')
            .collection('committee_vendor_profiles')
            .add(vendor);
        vendorIds.add(doc.id);
      }

      // Create default pool
      await _firestore!
          .collection('buildings')
          .doc('demo_building_1')
          .collection('committee_vendor_pools')
          .doc('default')
          .set({
        'poolId': 'default',
        'name': 'מאגר ועד הבית (ברירת מחדל)',
        'scope': 'committee',
        'active': true,
        'vendorIds': vendorIds,
        'services': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Sample maintenance data created');
    } catch (e) {
      print('❌ Error creating sample maintenance data: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SimpleFirebaseService.initialize();
    print('✅ Firebase initialized successfully in main');
  } catch (e) {
    print('❌ Firebase initialization failed in main: $e');
  }
  runApp(const VaadlyMainApp());
}

class VaadlyMainApp extends StatelessWidget {
  const VaadlyMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vaadly - ועד-לי',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPlaceholder(),
    const ResidentsPagePlaceholder(),
    const BuildingPagePlaceholder(),
    const MaintenanceDashboard(), // This is the key fix!
    const FinancialPagePlaceholder(),
    const SettingsPagePlaceholder(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'דשבורד',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'דיירים',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.business),
      label: 'בניין',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.build),
      label: 'תחזוקה',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.payment),
      label: 'תשלומים',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'הגדרות',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _bottomNavItems,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
      ),
    );
  }
}

// Placeholder widgets
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 דשבורד'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('דשבורד ראשי', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class ResidentsPagePlaceholder extends StatelessWidget {
  const ResidentsPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 דיירים'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('ניהול דיירים', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class BuildingPagePlaceholder extends StatelessWidget {
  const BuildingPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 בניין'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('ניהול בניין', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class FinancialPagePlaceholder extends StatelessWidget {
  const FinancialPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 תשלומים'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('ניהול פיננסי', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class SettingsPagePlaceholder extends StatelessWidget {
  const SettingsPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ הגדרות'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('הגדרות מערכת', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

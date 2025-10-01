import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/maintenance/maintenance_dashboard.dart';
import 'features/buildings/building_module/widgets/add_building_form.dart';

// Simplified Firebase Service without auth dependencies
class SimpleFirebaseService {
  static FirebaseFirestore? _firestore;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: options);
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  static FirebaseFirestore get firestore {
    if (!_initialized || _firestore == null) {
      throw Exception('Firebase not initialized');
    }
    return _firestore!;
  }

  static Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      final docRef = await firestore.collection(collection).add(data);
      print('✅ Document added to $collection with ID: ${docRef.id}');
      return docRef;
    } catch (e) {
      print('❌ Error adding document to $collection: $e');
      rethrow;
    }
  }

  static Future<QuerySnapshot> getDocuments(String collection) async {
    try {
      return await firestore.collection(collection).get();
    } catch (e) {
      print('❌ Error getting documents from $collection: $e');
      rethrow;
    }
  }

  static Future<void> updateDocument(String collection, String id, Map<String, dynamic> data) async {
    try {
      await firestore.collection(collection).doc(id).update(data);
      print('✅ Document updated in $collection');
    } catch (e) {
      print('❌ Error updating document in $collection: $e');
      rethrow;
    }
  Future<void> initializeSampleData() async {
    try {
      // Create demo building with specific ID
      final buildingData = {
        'buildingCode': 'shalom1234',
        'name': 'מגדל השלום',
        'address': 'רחוב הרצל 123',
        'city': 'תל אביב',
        'fullAddress': 'רחוב הרצל 123, תל אביב',
        'buildingManager': 'יוסי כהן',
        'managerPhone': '050-1234567',
        'managerEmail': 'yossi@shalom-tower.co.il',
        'totalFloors': 8,
        'totalUnits': 24,
        'parkingSpaces': 30,
        'storageUnits': 24,
        'buildingArea': 2500.0,
        'yearBuilt': 2010,
        'buildingType': 'residential',
        'amenities': ['elevator', 'parking', 'garden'],
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Set with specific document ID
      await _firestore!.collection('buildings').doc('demo_building_1').set(buildingData);
      
      // Create sample maintenance requests
      await initializeSampleMaintenanceRequests();
      
      // Create committee vendor profiles
      await _initializeCommitteeVendors();
      
      print('✅ Sample building and maintenance data created');
    } catch (e) {
      print('❌ Error initializing sample data: $e');
    }
  }

  Future<void> initializeSampleMaintenanceRequests() async {
    final now = DateTime.now();
    final requests = [
      {
        'id': 'req_1',
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
        'id': 'req_2',
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
    ];
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
  int currentIndex = 0;

  final List<Widget> pages = [
    const VaadlyDashboardPage(),
    const ResidentsPagePlaceholder(),
    const BuildingManagementPageSimple(),
    const MaintenanceDashboard(),
    const FinancialPagePlaceholder(),
    const SettingsPagePlaceholder(),
  ];

  final List<BottomNavigationBarItem> bottomNavItems = [
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
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: bottomNavItems,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
      ),
    );
  }
}

class VaadlyDashboardPage extends StatefulWidget {
  const VaadlyDashboardPage({super.key});

  @override
  State<VaadlyDashboardPage> createState() => _VaadlyDashboardPageState();
}

class _VaadlyDashboardPageState extends State<VaadlyDashboardPage> {
  Building? selectedBuilding;
  List<Building> buildings = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    setState(() => loading = true);
    try {
      await SimpleFirebaseService.initialize();
      await SimpleFirebaseService.initializeSampleData();

      final buildingsSnapshot = await SimpleFirebaseService.getDocuments('buildings');
      buildings = buildingsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Building.fromMap(data, doc.id);
      }).toList();

      if (buildings.isNotEmpty) {
        selectedBuilding = buildings.first;
      }

      setState(() => loading = false);
    } catch (e) {
      print('❌ Dashboard: Error loading data: $e');
      setState(() => loading = false);
    }
  }

  void addBuilding(Building building) async {
    try {
      if (building.id.isEmpty) {
        final docRef = await SimpleFirebaseService.addDocument('buildings', building.toMap());
        print('✅ Building saved to Firebase with ID: ${docRef.id}');
      } else {
        await SimpleFirebaseService.updateDocument('buildings', building.id, building.toMap());
        print('✅ Building updated in Firebase');
      }

      loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              building.id.isEmpty 
                  ? 'הבניין נוסף בהצלחה' 
                  : 'הבניין עודכן בהצלחה',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving building: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הבניין: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('📊 דשבורד'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (buildings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('📊 דשבורד'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('אין בניינים במערכת', style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('הוסף בניין ראשון כדי להתחיל', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddBuildingForm(onBuildingAdded: addBuilding),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('הוסף בניין'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 דשבורד'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Building selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('בניין:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<Building>(
                            value: selectedBuilding,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: buildings.map((building) {
                              return DropdownMenuItem(
                                value: building,
                                child: Text(building.name),
                              );
                            }).toList(),
                            onChanged: (building) {
                              setState(() {
                                selectedBuilding = building;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Selected building info
            if (selectedBuilding != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, size: 32, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedBuilding!.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  selectedBuilding!.fullAddress,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: buildInfoRow('יחידות', selectedBuilding!.totalUnits.toString())),
                          Expanded(child: buildInfoRow('קומות', selectedBuilding!.totalFloors.toString())),
                          Expanded(child: buildInfoRow('חניות', selectedBuilding!.parkingSpaces.toString())),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Statistics
            Text(
              'סטטיסטיקות',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: buildStatCard(context, 'בניינים', buildings.length.toString(), Icons.business, Colors.indigo)),
                const SizedBox(width: 16),
                Expanded(child: buildStatCard(context, 'יחידות כללית', buildings.fold<int>(0, (sum, b) => sum + b.totalUnits).toString(), Icons.apartment, Colors.teal)),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddBuildingForm(onBuildingAdded: addBuilding),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('הוסף בניין'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class BuildingManagementPageSimple extends StatefulWidget {
  const BuildingManagementPageSimple({super.key});

  @override
  State<BuildingManagementPageSimple> createState() => _BuildingManagementPageSimpleState();
}

class _BuildingManagementPageSimpleState extends State<BuildingManagementPageSimple> {
  List<Building> buildings = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    setState(() => loading = true);
    try {
      await SimpleFirebaseService.initialize();
      await SimpleFirebaseService.initializeSampleData();

      final buildingsSnapshot = await SimpleFirebaseService.getDocuments('buildings');
      buildings = buildingsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Building.fromMap(data, doc.id);
      }).toList();

      setState(() => loading = false);
    } catch (e) {
      print('❌ Building Management: Error loading data: $e');
      setState(() => loading = false);
    }
  }

  void addBuilding(Building building) async {
    try {
      if (building.id.isEmpty) {
        final docRef = await SimpleFirebaseService.addDocument('buildings', building.toMap());
        print('✅ Building saved to Firebase with ID: ${docRef.id}');
      } else {
        await SimpleFirebaseService.updateDocument('buildings', building.id, building.toMap());
        print('✅ Building updated in Firebase');
      }

      loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              building.id.isEmpty 
                  ? 'הבניין נוסף בהצלחה' 
                  : 'הבניין עודכן בהצלחה',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving building: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הבניין: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 ניהול בניינים'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : buildings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('אין בניינים במערכת', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: buildings.length,
                  itemBuilder: (context, index) {
                    final building = buildings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.business, color: Colors.blue),
                        title: Text(building.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(building.fullAddress),
                            const SizedBox(height: 4),
                            Text('${building.totalUnits} יחידות • ${building.totalFloors} קומות'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddBuildingForm(
                                  onBuildingAdded: addBuilding,
                                  buildingToEdit: building,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddBuildingForm(onBuildingAdded: addBuilding),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('הוסף בניין'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// Placeholder pages for other features
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
            SizedBox(height: 8),
            Text('תכונה זו תהיה זמינה בקרוב', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class MaintenancePagePlaceholder extends StatelessWidget {
  const MaintenancePagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 תחזוקה'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('מערכת תחזוקה חכמה', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('עם AI וניהול אוטומטי', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
            SizedBox(height: 8),
            Text('חשבוניות ותשלומים', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
            SizedBox(height: 8),
            Text('תצורה וניהול', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
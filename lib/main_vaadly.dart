import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/models/building.dart';
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
  }

  static Future<void> initializeSampleData() async {
    try {
      final buildingsSnapshot = await getDocuments('buildings');
      if (buildingsSnapshot.docs.isNotEmpty) {
        print('✅ Sample data already exists');
        return;
      }

      final buildingData = {
        'name': 'מגדל השלום',
        'address': 'רחוב הרצל 123',
        'city': 'תל אביב',
        'postalCode': '12345',
        'country': 'ישראל',
        'totalFloors': 8,
        'totalUnits': 24,
        'parkingSpaces': 30,
        'storageUnits': 24,
        'buildingArea': 2500.0,
        'yearBuilt': 2010,
        'buildingType': 'residential',
        'amenities': ['elevator', 'parking', 'garden'],
        'buildingManager': 'יוסי כהן',
        'managerPhone': '050-1234567',
        'managerEmail': 'yossi@shalom-tower.co.il',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await addDocument('buildings', buildingData);
      print('✅ Sample building created');
    } catch (e) {
      print('❌ Error initializing sample data: $e');
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
        cardTheme: CardThemeData(
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
    const VaadlyDashboardPage(),
    const ResidentsPagePlaceholder(),
    const BuildingManagementPageSimple(),
    const MaintenancePagePlaceholder(),
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

class VaadlyDashboardPage extends StatefulWidget {
  const VaadlyDashboardPage({super.key});

  @override
  State<VaadlyDashboardPage> createState() => _VaadlyDashboardPageState();
}

class _VaadlyDashboardPageState extends State<VaadlyDashboardPage> {
  Building? _selectedBuilding;
  List<Building> _buildings = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _loading = true);
    try {
      await SimpleFirebaseService.initialize();
      await SimpleFirebaseService.initializeSampleData();

      final buildingsSnapshot = await SimpleFirebaseService.getDocuments('buildings');
      _buildings = buildingsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Building.fromMap(data, doc.id);
      }).toList();

      if (_buildings.isNotEmpty) {
        _selectedBuilding = _buildings.first;
      }

      setState(() => _loading = false);
    } catch (e) {
      print('❌ Dashboard: Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  void _addBuilding(Building building) async {
    try {
      if (building.id.isEmpty) {
        final docRef = await SimpleFirebaseService.addDocument('buildings', building.toMap());
        print('✅ Building saved to Firebase with ID: ${docRef.id}');
      } else {
        await SimpleFirebaseService.updateDocument('buildings', building.id, building.toMap());
        print('✅ Building updated in Firebase');
      }

      _loadData();

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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('📊 דשבורד'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_buildings.isEmpty) {
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
                builder: (context) => AddBuildingForm(onBuildingAdded: _addBuilding),
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
                            initialValue: _selectedBuilding,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _buildings.map((building) {
                              return DropdownMenuItem(
                                value: building,
                                child: Text(building.name),
                              );
                            }).toList(),
                            onChanged: (building) {
                              setState(() {
                                _selectedBuilding = building;
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
            if (_selectedBuilding != null) ...[
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
                                  _selectedBuilding!.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  _selectedBuilding!.fullAddress,
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
                          Expanded(child: _buildInfoRow('יחידות', _selectedBuilding!.totalUnits.toString())),
                          Expanded(child: _buildInfoRow('קומות', _selectedBuilding!.totalFloors.toString())),
                          Expanded(child: _buildInfoRow('חניות', _selectedBuilding!.parkingSpaces.toString())),
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
                Expanded(child: _buildStatCard(context, 'בניינים', _buildings.length.toString(), Icons.business, Colors.indigo)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(context, 'יחידות כללית', _buildings.fold<int>(0, (sum, b) => sum + b.totalUnits).toString(), Icons.apartment, Colors.teal)),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddBuildingForm(onBuildingAdded: _addBuilding),
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

  Widget _buildInfoRow(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
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
  List<Building> _buildings = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _loading = true);
    try {
      await SimpleFirebaseService.initialize();
      await SimpleFirebaseService.initializeSampleData();

      final buildingsSnapshot = await SimpleFirebaseService.getDocuments('buildings');
      _buildings = buildingsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Building.fromMap(data, doc.id);
      }).toList();

      setState(() => _loading = false);
    } catch (e) {
      print('❌ Building Management: Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  void _addBuilding(Building building) async {
    try {
      if (building.id.isEmpty) {
        final docRef = await SimpleFirebaseService.addDocument('buildings', building.toMap());
        print('✅ Building saved to Firebase with ID: ${docRef.id}');
      } else {
        await SimpleFirebaseService.updateDocument('buildings', building.id, building.toMap());
        print('✅ Building updated in Firebase');
      }

      _loadData();

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildings.isEmpty
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
                  itemCount: _buildings.length,
                  itemBuilder: (context, index) {
                    final building = _buildings[index];
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
                                  onBuildingAdded: _addBuilding,
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
              builder: (context) => AddBuildingForm(onBuildingAdded: _addBuilding),
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
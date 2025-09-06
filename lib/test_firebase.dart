import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/models/building.dart';

// Placeholder for AddBuildingForm to satisfy analyzer in this demo file.
class AddBuildingForm extends StatelessWidget {
  final Function? onBuildingAdded;
  final Building? buildingToEdit;
  const AddBuildingForm({super.key, this.onBuildingAdded, this.buildingToEdit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הוסף/ערוך בניין')),
      body: const Center(child: Text('AddBuildingForm placeholder (demo only)')),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VaadlyMainDashboard());
}

class VaadlyMainDashboard extends StatelessWidget {
  const VaadlyMainDashboard({super.key});

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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      VaadlyDashboardPage(onNavigateToTab: changeTab),
      const ResidentsPagePlaceholder(),
      const BuildingManagementPagePlaceholder(),
      const MaintenancePagePlaceholder(),
      const FinancialPagePlaceholder(),
      const SettingsPagePlaceholder(),
    ];
  }

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

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<Map<String, dynamic>> _buildings = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    setState(() => _loading = true);
    try {
      final snapshot = await _firestore.collection('buildings').get();
      _buildings = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      print('✅ Loaded ${_buildings.length} buildings');
    } catch (e) {
      print('❌ Error loading buildings: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _addBuilding() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final buildingData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': 'תל אביב',
        'country': 'ישראל',
        'totalFloors': 5,
        'totalUnits': 20,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('buildings').add(buildingData);
      print('✅ Building added with ID: ${docRef.id}');
      
      _nameController.clear();
      _addressController.clear();
      await _loadBuildings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('בניין נוסף בהצלחה!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding building: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Building Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Building',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Building Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addBuilding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: _loading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Add Building'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.list),
                          const SizedBox(width: 8),
                          Text(
                            'Buildings (${_buildings.length})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _loading ? null : _loadBuildings,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildings.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.business, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No buildings yet', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _buildings.length,
                              itemBuilder: (context, index) {
                                final building = _buildings[index];
                                return ListTile(
                                  leading: const Icon(Icons.business, color: Colors.blue),
                                  title: Text(building['name'] ?? 'Unknown'),
                                  subtitle: Text(building['address'] ?? 'No address'),
                                  trailing: Text(
                                    building['id'].substring(0, 8),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

// Real Dashboard Page with Firebase Integration
class VaadlyDashboardPage extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const VaadlyDashboardPage({super.key, this.onNavigateToTab});

  @override
  State<VaadlyDashboardPage> createState() => _VaadlyDashboardPageState();
}

class _VaadlyDashboardPageState extends State<VaadlyDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Building? _selectedBuilding;
  List<Building> _buildings = [];
  Map<String, dynamic> _buildingStats = {};
  Map<String, dynamic> _overallStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      // Load buildings from Firebase
      final buildingsSnapshot = await _firestore.collection('buildings').get();
      print('📊 Dashboard: Loaded ${buildingsSnapshot.docs.length} buildings');
      
      _buildings = buildingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Building(
          id: doc.id,
          buildingCode: data['buildingCode'] ?? doc.id,
          name: data['name'] ?? 'Unknown Building',
          address: data['address'] ?? '',
          city: data['city'] ?? 'תל אביב',
          postalCode: data['postalCode'] ?? '',
          country: data['country'] ?? 'ישראל',
          totalFloors: data['totalFloors'] ?? 5,
          totalUnits: data['totalUnits'] ?? 20,
          parkingSpaces: data['parkingSpaces'] ?? 10,
          storageUnits: data['storageUnits'] ?? 5,
          buildingArea: (data['buildingArea'] ?? 1000.0).toDouble(),
          yearBuilt: data['yearBuilt'] ?? 2020,
          buildingType: data['buildingType'] ?? 'residential',
          amenities: List<String>.from(data['amenities'] ?? []),
          buildingManager: data['buildingManager'],
          managerPhone: data['managerPhone'],
          managerEmail: data['managerEmail'],
          emergencyContact: data['emergencyContact'],
          emergencyPhone: data['emergencyPhone'],
          notes: data['notes'],
          isActive: data['isActive'] ?? true,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      if (_buildings.isNotEmpty) {
        _selectedBuilding = _buildings.first;
        print('🏢 Dashboard: Selected building: ${_selectedBuilding!.name}');
      }
      
      // Calculate building stats
      if (_selectedBuilding != null) {
        _buildingStats = {
          'totalUnits': _selectedBuilding!.totalUnits,
          'occupiedUnits': (_selectedBuilding!.totalUnits * 0.8).round(), // Mock 80% occupancy
          'apartments': _selectedBuilding!.totalUnits,
          'parkingSpaces': _selectedBuilding!.parkingSpaces,
          'storageUnits': _selectedBuilding!.storageUnits,
          'occupancyRate': '80.0',
        };
      }
      
      // Calculate overall stats
      final totalUnits = _buildings.fold<int>(0, (sum, b) => sum + b.totalUnits);
      final occupiedUnits = (totalUnits * 0.75).round(); // Mock 75% overall occupancy
      
      _overallStats = {
        'totalBuildings': _buildings.length,
        'totalUnits': totalUnits,
        'occupiedUnits': occupiedUnits,
        'overallOccupancyRate': '75.0',
      };

      setState(() => _loading = false);
      print('✅ Dashboard: Data loaded successfully');
    } catch (e) {
      print('❌ Dashboard: Error loading data: $e');
      setState(() {
        _buildings = [];
        _buildingStats = {};
        _overallStats = {};
        _loading = false;
      });
    }
  }

  void _onBuildingChanged(Building? building) {
    setState(() {
      _selectedBuilding = building;
      if (building != null) {
        _buildingStats = {
          'totalUnits': building.totalUnits,
          'occupiedUnits': (building.totalUnits * 0.8).round(),
          'apartments': building.totalUnits,
          'parkingSpaces': building.parkingSpaces,
          'storageUnits': building.storageUnits,
          'occupancyRate': '80.0',
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('📊 דשבורד'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
              Icon(
                Icons.business,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'אין בניינים במערכת',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'הוסף בניין ראשון כדי להתחיל',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddBuildingForm(
                  onBuildingAdded: _addBuilding,
                ),
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
        actions: [
          IconButton(
            onPressed: () => _showOverallStatistics(context, _overallStats),
            icon: const Icon(Icons.analytics),
            tooltip: 'סטטיסטיקות כלליות',
          ),
        ],
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
                        const Text('בניין:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<Building>(
                            initialValue: _selectedBuilding,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: _buildings.map((building) {
                              return DropdownMenuItem(
                                value: building,
                                child: Text(building.name),
                              );
                            }).toList(),
                            onChanged: _onBuildingChanged,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Selected building info card
            if (_selectedBuilding != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedBuilding!.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                Text(
                                  '${_selectedBuilding!.address}, ${_selectedBuilding!.city}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
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
                          Expanded(
                            child: _buildInfoRow(
                                'יחידות',
                                _buildingStats['totalUnits']?.toString() ??
                                    '0'),
                          ),
                          Expanded(
                            child: _buildInfoRow(
                                'דיירים',
                                _buildingStats['occupiedUnits']?.toString() ??
                                    '0'),
                          ),
                          Expanded(
                            child: _buildInfoRow('אחוז תפוסה',
                                '${_buildingStats['occupancyRate'] ?? '0.0'}%'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Building statistics
            if (_selectedBuilding != null) ...[
              Text(
                'סטטיסטיקות בניין',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'דירות',
                      _buildingStats['apartments']?.toString() ?? '0',
                      Icons.home,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'חניות',
                      _buildingStats['parkingSpaces']?.toString() ?? '0',
                      Icons.local_parking,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'מחסנים',
                      _buildingStats['storageUnits']?.toString() ?? '0',
                      Icons.inventory,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'יחידות תפוסות',
                      _buildingStats['occupiedUnits']?.toString() ?? '0',
                      Icons.people,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Platform overview (for app owner)
            Text(
              'סקירת פלטפורמה',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'בניינים',
                    _overallStats['totalBuildings']?.toString() ?? '0',
                    Icons.business,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'יחידות כללית',
                    _overallStats['totalUnits']?.toString() ?? '0',
                    Icons.apartment,
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'יחידות תפוסות',
                    _overallStats['occupiedUnits']?.toString() ?? '0',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'אחוז תפוסה כללי',
                    '${_overallStats['overallOccupancyRate'] ?? '0.0'}%',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            Text(
              'פעולות מהירות',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'הוסף בניין',
                    Icons.add_business,
                    Colors.green,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddBuildingForm(
                            onBuildingAdded: _addBuilding,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'ניהול דיירים',
                    Icons.people,
                    Colors.blue,
                    () => _navigateToTab(1), // Navigate to residents tab
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'תחזוקה',
                    Icons.build,
                    Colors.orange,
                    () => _navigateToTab(3), // Navigate to maintenance tab
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'תשלומים',
                    Icons.payment,
                    Colors.purple,
                    () => _navigateToTab(4), // Navigate to payments tab
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddBuildingForm(
                onBuildingAdded: _addBuilding,
              ),
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int tabIndex) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabIndex);
    }
  }

  void _addBuilding(Building building) async {
    try {
      Map<String, dynamic> buildingData = {
        'name': building.name,
        'address': building.address,
        'city': building.city,
        'postalCode': building.postalCode,
        'country': building.country,
        'totalFloors': building.totalFloors,
        'totalUnits': building.totalUnits,
        'parkingSpaces': building.parkingSpaces,
        'storageUnits': building.storageUnits,
        'buildingArea': building.buildingArea,
        'yearBuilt': building.yearBuilt,
        'buildingType': building.buildingType,
        'amenities': building.amenities,
        'buildingManager': building.buildingManager,
        'managerPhone': building.managerPhone,
        'managerEmail': building.managerEmail,
        'emergencyContact': building.emergencyContact,
        'emergencyPhone': building.emergencyPhone,
        'notes': building.notes,
        'isActive': building.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (building.id.isNotEmpty) {
        // Update existing building
        await _firestore.collection('buildings').doc(building.id).update(buildingData);
        print('✅ Building updated in Firebase');
      } else {
        // Add new building
        final docRef = await _firestore.collection('buildings').add(buildingData);
        print('✅ Building saved to Firebase with ID: ${docRef.id}');
      }

      // Reload data to refresh the UI
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

  void _showOverallStatistics(
      BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סטטיסטיקות כלליות'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('בניינים', stats['totalBuildings'].toString()),
            _buildStatRow('יחידות כללית', stats['totalUnits'].toString()),
            _buildStatRow('יחידות תפוסות', stats['occupiedUnits'].toString()),
            _buildStatRow(
                'אחוז תפוסה כללי', '${stats['overallOccupancyRate']}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

// Placeholder Pages
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
            Icon(Icons.people, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('עמוד דיירים', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('כאן תוכל לנהל את הדיירים בבניין', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class BuildingManagementPagePlaceholder extends StatefulWidget {
  const BuildingManagementPagePlaceholder({super.key});

  @override
  State<BuildingManagementPagePlaceholder> createState() => _BuildingManagementPagePlaceholderState();
}

class _BuildingManagementPagePlaceholderState extends State<BuildingManagementPagePlaceholder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Building> _buildings = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final buildingsSnapshot = await _firestore.collection('buildings').get();
      _buildings = buildingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Building(
          id: doc.id,
          buildingCode: data['buildingCode'] ?? doc.id,
          name: data['name'] ?? 'Unknown Building',
          address: data['address'] ?? '',
          city: data['city'] ?? 'תל אביב',
          postalCode: data['postalCode'] ?? '',
          country: data['country'] ?? 'ישראל',
          totalFloors: data['totalFloors'] ?? 5,
          totalUnits: data['totalUnits'] ?? 20,
          parkingSpaces: data['parkingSpaces'] ?? 10,
          storageUnits: data['storageUnits'] ?? 5,
          buildingArea: (data['buildingArea'] ?? 1000.0).toDouble(),
          yearBuilt: data['yearBuilt'] ?? 2020,
          buildingType: data['buildingType'] ?? 'residential',
          amenities: List<String>.from(data['amenities'] ?? []),
          buildingManager: data['buildingManager'],
          managerPhone: data['managerPhone'],
          managerEmail: data['managerEmail'],
          emergencyContact: data['emergencyContact'],
          emergencyPhone: data['emergencyPhone'],
          notes: data['notes'],
          isActive: data['isActive'] ?? true,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      setState(() => _loading = false);
    } catch (e) {
      print('❌ Building Management: Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  void _addBuilding(Building building) async {
    try {
      Map<String, dynamic> buildingData = {
        'name': building.name,
        'address': building.address,
        'city': building.city,
        'postalCode': building.postalCode,
        'country': building.country,
        'totalFloors': building.totalFloors,
        'totalUnits': building.totalUnits,
        'parkingSpaces': building.parkingSpaces,
        'storageUnits': building.storageUnits,
        'buildingArea': building.buildingArea,
        'yearBuilt': building.yearBuilt,
        'buildingType': building.buildingType,
        'amenities': building.amenities,
        'buildingManager': building.buildingManager,
        'managerPhone': building.managerPhone,
        'managerEmail': building.managerEmail,
        'emergencyContact': building.emergencyContact,
        'emergencyPhone': building.emergencyPhone,
        'notes': building.notes,
        'isActive': building.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (building.id.isNotEmpty) {
        await _firestore.collection('buildings').doc(building.id).update(buildingData);
        print('✅ Building updated in Firebase');
      } else {
        final docRef = await _firestore.collection('buildings').add(buildingData);
        print('✅ Building saved to Firebase with ID: ${docRef.id}');
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
          title: const Text('🏢 ניהול בניינים'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 ניהול בניינים'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildings.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('אין בניינים במערכת', 
                       style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('הוסף בניין ראשון כדי להתחיל', 
                       style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _buildings.length,
              itemBuilder: (context, index) {
                final building = _buildings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      building.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${building.address}, ${building.city}'),
                        const SizedBox(height: 4),
                        Text(
                          '${building.totalUnits} יחידות • ${building.totalFloors} קומות',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
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
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBuilding(building),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddBuildingForm(
                onBuildingAdded: _addBuilding,
              ),
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

  void _deleteBuilding(Building building) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק בניין'),
        content: Text('האם אתה בטוח שברצונך למחוק את הבניין "${building.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('בטל'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _firestore.collection('buildings').doc(building.id).delete();
                print('✅ Building deleted from Firebase');
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('הבניין נמחק בהצלחה'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error deleting building: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('שגיאה במחיקת הבניין: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            Icon(Icons.build, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('תחזוקה', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('כאן תוכל לנהל בקשות תחזוקה', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            Icon(Icons.payment, size: 64, color: Colors.purple),
            SizedBox(height: 16),
            Text('תשלומים', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('כאן תוכל לנהל תשלומים וחשבוניות', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            Text('הגדרות', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('כאן תוכל לשנות הגדרות האפליקציה', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
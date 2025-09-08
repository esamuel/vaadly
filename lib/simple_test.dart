import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vaadly Test',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const TestDashboard(),
    );
  }
}

class TestDashboard extends StatefulWidget {
  const TestDashboard({super.key});

  @override
  State<TestDashboard> createState() => _TestDashboardState();
}

class _TestDashboardState extends State<TestDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _buildings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    try {
      final snapshot = await _firestore.collection('buildings').get();
      _buildings = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
      print('✅ Loaded ${_buildings.length} buildings');
    } catch (e) {
      print('❌ Error loading buildings: $e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 Vaadly Dashboard Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Buildings', _buildings.length.toString(),
                          Icons.business, Colors.blue),
                      _buildStatCard('Total Units', _getTotalUnits().toString(),
                          Icons.apartment, Colors.green),
                      _buildStatCard(
                          'Occupancy', '75%', Icons.people, Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildings.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No buildings found',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey)),
                              Text('Add your first building to get started',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey)),
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
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child:
                                      Icon(Icons.business, color: Colors.white),
                                ),
                                title: Text(
                                    building['name'] ?? 'Unknown Building'),
                                subtitle:
                                    Text(building['address'] ?? 'No address'),
                                trailing: Text(
                                    '${building['totalUnits'] ?? 0} units'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTestBuilding,
        icon: const Icon(Icons.add),
        label: const Text('Add Test Building'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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

  int _getTotalUnits() {
    return _buildings.fold<int>(
        0, (sum, building) => sum + (building['totalUnits'] as int? ?? 0));
  }

  Future<void> _addTestBuilding() async {
    try {
      final buildingData = {
        'name': 'Test Building ${_buildings.length + 1}',
        'address': 'Test Address ${_buildings.length + 1}',
        'city': 'Tel Aviv',
        'country': 'Israel',
        'totalFloors': 5,
        'totalUnits': 20,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('buildings').add(buildingData);
      print('✅ Test building added');

      // Reload buildings
      _loadBuildings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test building added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding test building: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:vaadly/core/services/firebase_service.dart';
import 'package:vaadly/core/models/building.dart';
import 'package:vaadly/features/buildings/building_module/widgets/add_building_form.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Building? _selectedBuilding;
  List<Building> _buildings = [];
  Map<String, dynamic> _buildingStats = {};
  Map<String, dynamic> _overallStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _selectedBuilding = null);
    
    try {
      // Initialize Firebase if needed
      await FirebaseService.initialize();
      print('✅ Dashboard: Firebase initialized');

      // Initialize sample data
      await FirebaseService.initializeSampleData();
      print('✅ Dashboard: Sample data initialized');

      // Load buildings from Firebase
      final buildingsSnapshot = await FirebaseService.getDocuments('buildings');
      print('📊 Dashboard: Loaded ${buildingsSnapshot.docs.length} buildings');
      
      _buildings = buildingsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Building.fromMap(data, doc.id);
      }).toList();

      if (_buildings.isNotEmpty) {
        _selectedBuilding = _buildings.first;
        print('🏢 Dashboard: Selected building: ${_selectedBuilding!.name}');
      }
      
      // For now, use empty stats until we implement Firebase queries
      _buildingStats = {
        'totalUnits': _selectedBuilding?.totalUnits ?? 0,
        'occupiedUnits': 0,
        'apartments': _selectedBuilding?.totalUnits ?? 0,
        'parkingSpaces': _selectedBuilding?.parkingSpaces ?? 0,
        'storageUnits': _selectedBuilding?.storageUnits ?? 0,
        'occupancyRate': '0.0',
      };
      
      _overallStats = {
        'totalBuildings': _buildings.length,
        'totalUnits': _buildings.fold<int>(0, (sum, b) => sum + b.totalUnits),
        'occupiedUnits': 0,
        'overallOccupancyRate': '0.0',
      };

      setState(() {});
      print('✅ Dashboard: Data loaded successfully');
    } catch (e) {
      print('❌ Dashboard: Error loading data: $e');
      setState(() {
        _buildings = [];
        _buildingStats = {};
        _overallStats = {};
      });
    }
  }

  void _onBuildingChanged(Building? building) {
    setState(() {
      _selectedBuilding = building;
      if (building != null) {
        // For now, use empty stats until we implement Firebase queries
        _buildingStats = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_buildings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                                  _selectedBuilding!.fullAddress,
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
                    () => _navigateToBuildingManagement(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'ניהול דיירים',
                    Icons.people,
                    Colors.blue,
                    () => _navigateToResidents(),
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
                    () => _navigateToMaintenance(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'תשלומים',
                    Icons.payment,
                    Colors.purple,
                    () => _navigateToPayments(),
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

  void _navigateToBuildingManagement() {
    // Navigate to building management tab
    // This will be handled by the parent navigation
  }

  void _navigateToResidents() {
    // Navigate to residents tab
    // This will be handled by the parent navigation
  }

  void _navigateToMaintenance() {
    // Navigate to maintenance tab
    // This will be handled by the parent navigation
  }

  void _navigateToPayments() {
    // Navigate to payments tab
    // This will be handled by the parent navigation
  }

  void _addBuilding(Building building) async {
    try {
      if (building.id == '' || building.id.isEmpty) {
        // New building - save to Firebase
        final docRef = await FirebaseService.addDocument('buildings', building.toMap());
        print('✅ Building saved to Firebase with ID: ${docRef.id}');
      } else {
        // Update existing building
        await FirebaseService.updateDocument(
            'buildings', building.id, building.toMap());
        print('✅ Building updated in Firebase');
      }

      // Reload data to refresh the UI
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              building.id == '' || building.id.isEmpty 
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
            _buildStatRow('יחידות פנויות', stats['vacantUnits'].toString()),
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

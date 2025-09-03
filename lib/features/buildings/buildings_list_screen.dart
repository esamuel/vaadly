import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_building_service.dart';
import '../../core/models/building.dart';
import 'building_detail_screen.dart';
import 'add_building_screen.dart';

class BuildingsListScreen extends StatefulWidget {
  const BuildingsListScreen({super.key});

  @override
  State<BuildingsListScreen> createState() => _BuildingsListScreenState();
}

class _BuildingsListScreenState extends State<BuildingsListScreen> {
  bool _loading = true;
  List<Building> _buildings = [];

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    setState(() => _loading = true);
    try {
      // Load buildings from Firebase
      _buildings = await FirebaseBuildingService.getAllBuildings();
    } catch (e) {
      print('❌ Error loading buildings: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDeleteBuilding(Building building) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('אזהרה'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('האם אתה בטוח שברצונך למחוק את הבניין "${building.name}"?'),
            const SizedBox(height: 12),
            const Text(
              'פעולה זו תמחק את:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• כל נתוני הבניין'),
            const Text('• רשימת הדיירים'),
            const Text('• בקשות התחזוקה'),
            const Text('• הנתונים הכספיים'),
            const SizedBox(height: 12),
            const Text(
              'לא ניתן לבטל פעולה זו!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('בטל'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק בניין'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBuilding(building);
    }
  }

  Future<void> _deleteBuilding(Building building) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('מוחק בניין...'),
            ],
          ),
        ),
      );

      // Delete from Firebase
      final success = await FirebaseBuildingService.deleteBuilding(building.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('הבניין "${building.name}" נמחק בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the buildings list
        _loadBuildings();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה במחיקת הבניין'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה במחיקת הבניין: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCommitteeInvitationLink(Building building) {
    final invitationLink = 'http://localhost:3000/#/manage/${building.buildingCode}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link, color: Colors.indigo),
            SizedBox(width: 8),
            Text('קישור הזמנה לועד הבית'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('בניין: ${building.name}'),
            const SizedBox(height: 16),
            const Text(
              'שלח קישור זה לועד הבית:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      invitationLink,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: invitationLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('קישור הועתק ללוח הגזירים')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'העתק קישור',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'הועד יוכל להקים חשבון ולהתחיל לנהל את הבניין.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'פעיל':
        return Colors.green;
      case 'לא פעיל':
        return Colors.red;
      case 'השעיה':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.indigo),
            SizedBox(width: 8),
            Text('ניהול בניינים'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadBuildings,
            icon: const Icon(Icons.refresh),
            tooltip: 'רענן רשימה',
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddBuildingScreen()),
              );
              // Refresh the list when returning from add building screen
              if (result == true) {
                _loadBuildings();
              }
            },
            icon: const Icon(Icons.add_business),
            tooltip: 'הוסף בניין חדש',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('טוען בניינים...'),
                ],
              ),
            )
          : Column(
              children: [
                // Summary cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'סה״כ בניינים',
                          _buildings.length.toString(),
                          Icons.business,
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'סה״כ דירות',
                          _buildings.fold(0, (sum, b) => sum + b.totalUnits).toString(),
                          Icons.home,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'סה״כ קומות',
                          _buildings.fold(0, (sum, b) => sum + b.totalFloors).toString(),
                          Icons.layers,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'מספר בניינים פעילים',
                          _buildings.where((b) => b.isActive).length.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Buildings list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _buildings.length,
                    itemBuilder: (context, index) {
                      final building = _buildings[index];
                      return _buildBuildingCard(building);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddBuildingScreen()),
          );
          // Refresh the list when returning from add building screen
          if (result == true) {
            _loadBuildings();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('הוסף בניין'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingCard(Building building) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          // Convert Building model to Map for BuildingDetailScreen
          final buildingMap = {
            'id': building.id,
            'code': building.buildingCode,
            'name': building.name,
            'address': '${building.address}, ${building.city}',
            'units': building.totalUnits,
            'residents': building.totalUnits * 2, // Estimate
            'committee': building.buildingManager ?? 'לא מוגדר',
            'phone': building.managerPhone ?? '',
            'email': building.managerEmail ?? '',
            'status': building.isActive ? 'פעיל' : 'לא פעיל',
            'created': building.createdAt.year.toString(),
            'monthlyRevenue': building.totalUnits * 1500, // Estimate
            'openIssues': 0, // Default
            'lastActivity': 'לפני כמה דקות',
          };
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BuildingDetailScreen(building: buildingMap),
            ),
          );
          
          // If building was deleted, refresh the list
          if (result == true) {
            _loadBuildings();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business, color: Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              building.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(building.isActive ? 'פעיל' : 'לא פעיל').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(building.isActive ? 'פעיל' : 'לא פעיל').withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                building.isActive ? 'פעיל' : 'לא פעיל',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getStatusColor(building.isActive ? 'פעיל' : 'לא פעיל'),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${building.address}, ${building.city}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'קוד: ${building.buildingCode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'נוצר: ${building.createdAt.year}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDeleteBuilding(building);
                      } else if (value == 'committee_link') {
                        _showCommitteeInvitationLink(building);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'committee_link',
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text('קישור לועד הבית'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('מחק בניין', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _buildStatChip('${building.totalUnits} דירות', Icons.home, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip('${building.totalFloors} קומות', Icons.layers, Colors.teal),
                  const SizedBox(width: 8),
                  _buildStatChip('${building.yearBuilt}', Icons.calendar_today, Colors.green),
                ],
              ),
              const SizedBox(height: 12),

              // Committee info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'ועד: ${building.buildingManager ?? 'לא מוגדר'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (building.notes != null && building.notes!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'הערות',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
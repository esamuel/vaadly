import 'package:flutter/material.dart';
import '../../../core/models/building.dart';
import '../../../core/models/unit.dart';
import '../../../core/services/firebase_service.dart';
import '../widgets/add_building_form.dart';

class BuildingManagementPage extends StatefulWidget {
  const BuildingManagementPage({super.key});

  @override
  State<BuildingManagementPage> createState() => _BuildingManagementPageState();
}

class _BuildingManagementPageState extends State<BuildingManagementPage> {
  List<Building> _buildings = [];
  List<Unit> _units = [];
  Building? _selectedBuilding;
  String _searchQuery = '';
  UnitType? _selectedUnitTypeFilter;
  UnitStatus? _selectedUnitStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _selectedBuilding = null);
    
    try {
      // Initialize Firebase if needed
      await FirebaseService.initialize();
      print('✅ Building Management: Firebase initialized');

      // Initialize sample data
      await FirebaseService.initializeSampleData();
      print('✅ Building Management: Sample data initialized');

      // Load buildings from Firebase
      final buildingsSnapshot = await FirebaseService.getDocuments('buildings');
      print('📊 Building Management: Loaded ${buildingsSnapshot.docs.length} buildings');
      
      _buildings = buildingsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Building.fromMap(data, doc.id);
      }).toList();

      if (_buildings.isNotEmpty) {
        _selectedBuilding = _buildings.first;
        print('🏢 Building Management: Selected building: ${_selectedBuilding!.name}');
      }
      
      // For now, use empty units until we implement Firebase queries
      _units = [];

      setState(() {});
      print('✅ Building Management: Data loaded successfully');
    } catch (e) {
      print('❌ Building Management: Error loading data: $e');
      setState(() {
        _buildings = [];
        _units = [];
      });
    }
  }

  void _applyFilters() {
    if (_selectedBuilding == null) return;

    // For now, use empty units until we implement Firebase queries
    _units = [];

    // Apply unit type filter
    if (_selectedUnitTypeFilter != null) {
      _units = _units
          .where((unit) => unit.unitType == _selectedUnitTypeFilter)
          .toList();
    }

    // Apply unit status filter
    if (_selectedUnitStatusFilter != null) {
      _units = _units
          .where((unit) => unit.status == _selectedUnitStatusFilter)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _units = _units.where((unit) {
        return unit.unitNumber.toLowerCase().contains(query) ||
            (unit.floor != null && unit.floor!.toLowerCase().contains(query)) ||
            unit.description?.toLowerCase().contains(query) == true;
      }).toList();
    }
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

  void _editBuilding(Building building) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBuildingForm(
          onBuildingAdded: _addBuilding,
          buildingToEdit: building,
        ),
      ),
    );
  }

  void _deleteBuilding(Building building) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק בניין'),
        content: Text(
            'האם אתה בטוח שברצונך למחוק את ${building.name}?\nפעולה זו תמחק גם את כל היחידות הקשורות לבניין.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseService.deleteDocument('buildings', building.id);
                Navigator.of(context).pop();
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('הבניין נמחק בהצלחה'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                print('❌ Error deleting building: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('שגיאה במחיקת הבניין: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('מחק', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBuildingOptions(BuildContext context) {
    if (_selectedBuilding == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('ערוך בניין'),
              onTap: () {
                Navigator.of(context).pop();
                _editBuilding(_selectedBuilding!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('מחק בניין', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _deleteBuilding(_selectedBuilding!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('פרטי בניין'),
              onTap: () {
                Navigator.of(context).pop();
                _showBuildingDetails(context, _selectedBuilding!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildingDetails(BuildContext context, Building building) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('פרטי בניין - ${building.name}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBuildingDetailRow('שם', building.name),
                      _buildBuildingDetailRow('כתובת', building.fullAddress),
                      _buildBuildingDetailRow('סוג',
                          _getBuildingTypeDisplay(building.buildingType)),
                      _buildBuildingDetailRow(
                          'קומות', building.totalFloors.toString()),
                      _buildBuildingDetailRow(
                          'יחידות', building.totalUnits.toString()),
                      _buildBuildingDetailRow(
                          'חניות', building.parkingSpaces.toString()),
                      _buildBuildingDetailRow(
                          'מחסנים', building.storageUnits.toString()),
                      _buildBuildingDetailRow(
                          'שטח', '${building.buildingArea} מ"ר'),
                      _buildBuildingDetailRow(
                          'שנת בנייה', building.yearBuilt.toString()),
                      if (building.buildingManager != null)
                        _buildBuildingDetailRow(
                            'מנהל', building.buildingManager!),
                      if (building.managerPhone != null)
                        _buildBuildingDetailRow(
                            'טלפון מנהל', building.managerPhone!),
                      if (building.managerEmail != null)
                        _buildBuildingDetailRow(
                            'אימייל מנהל', building.managerEmail!),
                      if (building.emergencyContact != null)
                        _buildBuildingDetailRow(
                            'איש קשר חירום', building.emergencyContact!),
                      if (building.emergencyPhone != null)
                        _buildBuildingDetailRow(
                            'טלפון חירום', building.emergencyPhone!),
                      if (building.notes != null)
                        _buildBuildingDetailRow('הערות', building.notes!),
                      if (building.amenities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'שירותים ונוחות:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: building.amenities.map((amenity) {
                            return Chip(
                              label: Text(_getAmenityDisplay(amenity)),
                              backgroundColor: Colors.blue[50],
                              side: BorderSide(color: Colors.blue[200]!),
                            );
                          }).toList(),
                        ),
                      ],
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

  Widget _buildBuildingDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getBuildingTypeDisplay(String type) {
    switch (type) {
      case 'residential':
        return 'מגורים';
      case 'commercial':
        return 'מסחרי';
      case 'mixed':
        return 'מעורב';
      case 'office':
        return 'משרדים';
      case 'industrial':
        return 'תעשייתי';
      default:
        return type;
    }
  }

  String _getAmenityDisplay(String amenity) {
    switch (amenity) {
      case 'pool':
        return 'בריכה';
      case 'gym':
        return 'חדר כושר';
      case 'garden':
        return 'גינה';
      case 'playground':
        return 'מגרש משחקים';
      case 'parking':
        return 'חניה';
      case 'storage':
        return 'מחסן';
      case 'elevator':
        return 'מעלית';
      case 'security':
        return 'אבטחה';
      case 'cctv':
        return 'מצלמות אבטחה';
      case 'intercom':
        return 'אינטרקום';
      case 'airConditioning':
        return 'מיזוג אוויר';
      case 'heating':
        return 'חימום';
      case 'wifi':
        return 'אינטרנט אלחוטי';
      case 'laundry':
        return 'חדר כביסה';
      case 'bikeStorage':
        return 'אחסון אופניים';
      case 'petFriendly':
        return 'ידידותי לחיות מחמד';
      case 'accessibility':
        return 'נגישות';
      default:
        return amenity;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_buildings.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('אין בניינים זמינים'),
        ),
      );
    }

    // For now, use empty stats until we implement Firebase queries
    final buildingStats = <String, dynamic>{};
    final overallStats = <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 ניהול בניין'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showOverallStatistics(context, overallStats),
            icon: const Icon(Icons.analytics),
            tooltip: 'סטטיסטיקות כלליות',
          ),
          IconButton(
            onPressed: () => _showBuildingOptions(context),
            icon: const Icon(Icons.more_vert),
            tooltip: 'אפשרויות בניין',
          ),
        ],
      ),
      body: Column(
        children: [
          // Building selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _buildings.map((building) {
                      return DropdownMenuItem(
                        value: building,
                        child: Text(building.displayName),
                      );
                    }).toList(),
                    onChanged: (building) {
                      setState(() {
                        _selectedBuilding = building;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Building statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'סטטיסטיקות ${_selectedBuilding?.name ?? ""}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'סה"כ יחידות',
                        buildingStats['totalUnits']?.toString() ?? '0',
                        Icons.home,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'תפוסות',
                        buildingStats['occupiedUnits']?.toString() ?? '0',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'פנויות',
                        buildingStats['vacantUnits']?.toString() ?? '0',
                        Icons.cancel,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'אחוז תפוסה',
                        '${buildingStats['occupancyRate'] ?? '0.0'}%',
                        Icons.pie_chart,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search and filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'חיפוש יחידות...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filters
                Row(
                  children: [
                    // Unit type filter
                    Expanded(
                      child: DropdownButtonFormField<UnitType?>(
                        initialValue: _selectedUnitTypeFilter,
                        decoration: const InputDecoration(
                          labelText: 'סוג יחידה',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('כל הסוגים'),
                          ),
                          ...UnitType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getUnitTypeDisplay(type)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitTypeFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Unit status filter
                    Expanded(
                      child: DropdownButtonFormField<UnitStatus?>(
                        initialValue: _selectedUnitStatusFilter,
                        decoration: const InputDecoration(
                          labelText: 'סטטוס',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('כל הסטטוסים'),
                          ),
                          ...UnitStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_getUnitStatusDisplay(status)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitStatusFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'נמצאו ${_units.length} יחידות',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_units.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedUnitTypeFilter = null;
                        _selectedUnitStatusFilter = null;
                        _applyFilters();
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('נקה סינון'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Units list
          Expanded(
            child: _units.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _units.length,
                    itemBuilder: (context, index) {
                      final unit = _units[index];
                      return _buildUnitCard(unit);
                    },
                  ),
          ),
        ],
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(Unit unit) {
    // For now, use null resident until we implement Firebase queries
    const resident = null;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getUnitTypeIcon(unit.unitType),
                  color: _getUnitTypeColor(unit.unitType),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.fullIdentifier,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${unit.typeDisplay} - ${unit.statusDisplay}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(unit.status),
              ],
            ),

            const SizedBox(height: 16),

            // Unit details
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow('שטח', '${unit.area} מ"ר'),
                ),
                if (unit.bedrooms > 0)
                  Expanded(
                    child: _buildDetailRow('חדרים', '${unit.bedrooms}'),
                  ),
                if (unit.bathrooms > 0)
                  Expanded(
                    child: _buildDetailRow('חדרי רחצה', '${unit.bathrooms}'),
                  ),
              ],
            ),

            // Description
            if (unit.description != null && unit.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                unit.description!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],

            // Features
            if (unit.features.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: unit.features.map((feature) {
                  return Chip(
                    label: Text(
                      _getFeatureDisplay(feature),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue[50],
                    side: BorderSide(color: Colors.blue[200]!),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
              ),
            ],

            // Current resident
            if (resident != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'דייר נוכחי:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            resident.fullName,
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Financial info
            if (unit.monthlyRent != null ||
                unit.monthlyMaintenance != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (unit.monthlyRent != null)
                    Expanded(
                      child: _buildDetailRow(
                          'שכירות', '₪${unit.monthlyRent!.toStringAsFixed(0)}'),
                    ),
                  if (unit.monthlyMaintenance != null)
                    Expanded(
                      child: _buildDetailRow('דמי ניהול',
                          '₪${unit.monthlyMaintenance!.toStringAsFixed(0)}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(UnitStatus status) {
    Color color;
    String text;

    switch (status) {
      case UnitStatus.occupied:
        color = Colors.green;
        text = 'תפוס';
        break;
      case UnitStatus.vacant:
        color = Colors.orange;
        text = 'פנוי';
        break;
      case UnitStatus.maintenance:
        color = Colors.red;
        text = 'בתחזוקה';
        break;
      case UnitStatus.reserved:
        color = Colors.blue;
        text = 'שמור';
        break;
      case UnitStatus.renovation:
        color = Colors.purple;
        text = 'בשיפוץ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'לא נמצאו יחידות',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'נסה לשנות את הסינון או הוסף יחידה חדשה',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showOverallStatistics(
      BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סטטיסטיקות כלליות'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('סה"כ בניינים', stats['totalBuildings'].toString()),
            _buildStatRow('סה"כ יחידות', stats['totalUnits'].toString()),
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
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getUnitTypeDisplay(UnitType type) {
    switch (type) {
      case UnitType.apartment:
        return 'דירה';
      case UnitType.parking:
        return 'חניה';
      case UnitType.storage:
        return 'מחסן';
      case UnitType.commercial:
        return 'מסחר';
      case UnitType.common:
        return 'שטח משותף';
    }
  }

  String _getUnitStatusDisplay(UnitStatus status) {
    switch (status) {
      case UnitStatus.occupied:
        return 'תפוס';
      case UnitStatus.vacant:
        return 'פנוי';
      case UnitStatus.maintenance:
        return 'בתחזוקה';
      case UnitStatus.reserved:
        return 'שמור';
      case UnitStatus.renovation:
        return 'בשיפוץ';
    }
  }

  IconData _getUnitTypeIcon(UnitType type) {
    switch (type) {
      case UnitType.apartment:
        return Icons.home;
      case UnitType.parking:
        return Icons.local_parking;
      case UnitType.storage:
        return Icons.inventory;
      case UnitType.commercial:
        return Icons.store;
      case UnitType.common:
        return Icons.people;
    }
  }

  Color _getUnitTypeColor(UnitType type) {
    switch (type) {
      case UnitType.apartment:
        return Colors.blue;
      case UnitType.parking:
        return Colors.orange;
      case UnitType.storage:
        return Colors.grey;
      case UnitType.commercial:
        return Colors.green;
      case UnitType.common:
        return Colors.purple;
    }
  }

  String _getFeatureDisplay(String feature) {
    switch (feature) {
      case 'balcony':
        return 'מרפסת';
      case 'elevator':
        return 'מעלית';
      case 'airConditioning':
        return 'מיזוג אוויר';
      case 'parking':
        return 'חניה';
      case 'garden':
        return 'גינה';
      case 'security':
        return 'אבטחה';
      case 'cctv':
        return 'מצלמות';
      default:
        return feature;
    }
  }
}

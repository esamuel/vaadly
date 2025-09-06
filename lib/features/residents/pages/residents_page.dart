import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/models/resident.dart';
import '../../../core/services/resident_service.dart';
import '../../../services/firebase_resident_service.dart';
import '../../../services/firebase_activity_service.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/add_resident_form.dart';
import '../widgets/resident_card.dart';

class ResidentsPage extends StatefulWidget {
  final bool showFloatingActionButton;
  
  const ResidentsPage({
    super.key, 
    this.showFloatingActionButton = true,
  });

  @override
  State<ResidentsPage> createState() => _ResidentsPageState();
}

class _ResidentsPageState extends State<ResidentsPage> {
  List<Resident> _residents = [];
  List<Resident> _filteredResidents = [];
  String _searchQuery = '';
  ResidentType? _selectedTypeFilter;
  ResidentStatus? _selectedStatusFilter;
  bool _showOnlyActive = true;
  String? _buildingId;
  bool _loading = false;
  StreamSubscription<List<Resident>>? _residentsSub;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initializeBuildingContext();
  }

  @override
  void dispose() {
    _residentsSub?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initializeBuildingContext() async {
    // Get the building ID from current user context
    final user = AuthService.currentUser;
    print('🔍 ResidentsPage - Current user: ${user?.name} (${user?.role})');
    print('🔍 ResidentsPage - Building access: ${user?.buildingAccess}');
    
    if (user != null && user.isBuildingCommittee) {
      _buildingId = user.buildingAccess.keys.first;
      print('🔍 ResidentsPage - Using building ID: $_buildingId');
      _subscribeToResidents();
    } else {
      // Fallback to old service for other users
      _loadResidentsLocal();
    }
  }

  void _subscribeToResidents() {
    if (_buildingId == null) return;
    _residentsSub?.cancel();
    setState(() => _loading = true);
    _residentsSub = FirebaseResidentService
        .streamResidents(_buildingId!)
        .listen((list) {
      setState(() {
        _residents = list;
        _applyFilters();
        _loading = false;
      });
    }, onError: (e) {
      print('❌ Error in residents stream: $e');
      setState(() => _loading = false);
    });
  }

  Future<void> _loadResidents() async {
    if (_buildingId == null) return;
    
    setState(() => _loading = true);
    
    try {
      print('📋 Loading residents for building: $_buildingId');
      _residents = await FirebaseResidentService.getResidents(_buildingId!);
      _applyFilters();
      print('✅ Loaded ${_residents.length} residents from Firebase');
    } catch (e) {
      print('❌ Error loading residents: $e');
      // Fallback to local service if Firebase fails
      _loadResidentsLocal();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _loadResidentsLocal() {
    // Initialize sample data if empty
    if (ResidentService.getAllResidents().isEmpty) {
      ResidentService.initializeSampleData();
    }
    
    setState(() {
      _residents = ResidentService.getAllResidents();
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    _filteredResidents = _residents.where((resident) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!resident.firstName.toLowerCase().contains(query) &&
            !resident.lastName.toLowerCase().contains(query) &&
            !resident.fullName.toLowerCase().contains(query) &&
            !resident.apartmentNumber.contains(query)) {
          return false;
        }
      }

      // Type filter
      if (_selectedTypeFilter != null && resident.residentType != _selectedTypeFilter) {
        return false;
      }

      // Status filter
      if (_selectedStatusFilter != null && resident.status != _selectedStatusFilter) {
        return false;
      }

      // Active filter
      if (_showOnlyActive && !resident.isActive) {
        return false;
      }

      return true;
    }).toList();

    // Sort by name
    _filteredResidents.sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<void> _addResident(Resident resident) async {
    if (_buildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שגיאה: לא נמצא מזהה בניין'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (resident.id.isEmpty) {
        // New resident - add to Firebase
        print('👤 Adding new resident: ${resident.firstName} ${resident.lastName}');
        
        // Show loading indicator
        setState(() => _loading = true);
        
        final newId = await FirebaseResidentService.addResident(_buildingId!, resident);
        if (newId != null) {
          print('✅ Resident added with ID: $newId');
          
          // Real-time stream will update the UI automatically
          setState(() => _loading = false);
          
          // Log activity (best-effort)
          try {
            await FirebaseActivityService.logActivity(
              buildingId: _buildingId!,
              type: 'resident_added',
              title: 'דייר חדש נוסף',
subtitle: 'app ${resident.apartmentNumber}, ${resident.firstName} ${resident.lastName}',
              extra: {'residentId': newId},
            );
          } catch (_) {}

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('הדייר נוסף בהצלחה'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() => _loading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('שגיאה בהוספת דייר'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Update existing resident
        print('✏️ Updating existing resident: ${resident.firstName} ${resident.lastName}');
        
        setState(() => _loading = true);
        
        final success = await FirebaseResidentService.updateResident(_buildingId!, resident.id, resident);
        if (success) {
          // Real-time stream will update the UI automatically
          setState(() => _loading = false);
          
          // Log activity (best-effort)
          try {
            await FirebaseActivityService.logActivity(
              buildingId: _buildingId!,
              type: 'resident_updated',
              title: 'עודכן דייר',
subtitle: 'app ${resident.apartmentNumber}, ${resident.firstName} ${resident.lastName}',
              extra: {'residentId': resident.id},
            );
          } catch (_) {}

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('הדייר עודכן בהצלחה'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() => _loading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('שגיאה בעדכון דייר'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error saving resident: $e');
      setState(() => _loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הדייר: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Fallback to local service
      try {
        ResidentService.addResident(resident);
        _loadResidentsLocal();
      } catch (localError) {
        print('❌ Local fallback also failed: $localError');
      }
    }
  }

  void _editResident(Resident resident) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddResidentForm(
          onResidentAdded: _addResident,
          residentToEdit: resident,
        ),
      ),
    );
  }

  Future<void> _deleteResident(Resident resident) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק דייר'),
        content: Text('האם אתה בטוח שברצונך למחוק את ${resident.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              if (_buildingId != null) {
                try {
                  print('🗑️ Deleting resident: ${resident.firstName} ${resident.lastName}');
                  
                  // Show loading state
                  setState(() => _loading = true);
                  
                  // Delete from Firebase
                  final success = await FirebaseResidentService.deleteResident(_buildingId!, resident.id);
                  
                  if (success) {
                    print('✅ Resident deleted successfully');
                    // Real-time stream will update the UI automatically
                    setState(() => _loading = false);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('הדייר נמחק בהצלחה'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    setState(() => _loading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('שגיאה במחיקת הדייר'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  print('❌ Error deleting resident: $e');
                  setState(() => _loading = false);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('שגיאה במחיקת הדייר: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                try {
                  // Fallback to local service
                  ResidentService.deleteResident(resident.id);
                  _loadResidentsLocal();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('הדייר נמחק בהצלחה'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Local delete failed: $e');
                }
              }
            },
            child: const Text('מחק', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResidentDetails(Resident resident) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('פרטי דייר - ${resident.fullName}'),
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
                  child: ResidentCard(
                    resident: resident,
                    onEdit: () {
                      Navigator.of(context).pop();
                      _editResident(resident);
                    },
                    onDelete: () {
                      Navigator.of(context).pop();
                      _deleteResident(resident);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getFirebaseStatistics() {
    if (_residents.isEmpty) return {'total': 0, 'active': 0, 'inactive': 0, 'owners': 0, 'tenants': 0, 'familyMembers': 0, 'guests': 0, 'occupancyRate': 0};
    
    int total = _residents.length;
    int active = _residents.where((r) => r.status == ResidentStatus.active).length;
    int owners = _residents.where((r) => r.residentType == ResidentType.owner).length;
    int tenants = _residents.where((r) => r.residentType == ResidentType.tenant).length;
    int familyMembers = _residents.where((r) => r.residentType == ResidentType.familyMember).length;
    int guests = _residents.where((r) => r.residentType == ResidentType.guest).length;
    
    return {
      'total': total,
      'active': active,
      'inactive': total - active,
      'owners': owners,
      'tenants': tenants,
      'familyMembers': familyMembers,
      'guests': guests,
      'occupancyRate': total > 0 ? ((active * 100) / total).round() : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Use Firebase statistics if we have a building ID, otherwise fallback to local
    final stats = _buildingId != null 
        ? _getFirebaseStatistics() 
        : ResidentService.getResidentStatistics();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('👥 דיירי הבניין'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showStatistics(context, stats),
            icon: const Icon(Icons.analytics),
            tooltip: 'סטטיסטיקות',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'סה"כ דיירים',
                    stats['total'].toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'פעילים',
                    stats['active'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'בעלי דירה',
                    stats['owners'].toString(),
                    Icons.home,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'שוכרים',
                    stats['tenants'].toString(),
                    Icons.key,
                    Colors.orange,
                  ),
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
                    hintText: 'חיפוש לפי שם או מספר דירה...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchQuery = value;
                    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                      if (!mounted) return;
                      setState(() {
                        _applyFilters();
                      });
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filters
                Row(
                  children: [
                    // Type filter
                    Expanded(
                      child: DropdownButtonFormField<ResidentType?>(
                        initialValue: _selectedTypeFilter,
                        decoration: const InputDecoration(
                          labelText: 'סוג דייר',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('כל הסוגים'),
                          ),
                          ...ResidentType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getTypeDisplay(type)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTypeFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<ResidentStatus?>(
                        initialValue: _selectedStatusFilter,
                        decoration: const InputDecoration(
                          labelText: 'סטטוס',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('כל הסטטוסים'),
                          ),
                          ...ResidentStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusDisplay(status)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Active filter
                    FilterChip(
                      label: const Text('רק פעילים'),
                      selected: _showOnlyActive,
                      onSelected: (value) {
                        setState(() {
                          _showOnlyActive = value;
                          _applyFilters();
                        });
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      checkmarkColor: Colors.white,
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
                  'נמצאו ${_filteredResidents.length} דיירים',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_filteredResidents.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedTypeFilter = null;
                        _selectedStatusFilter = null;
                        _showOnlyActive = true;
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

          // Residents list
          Expanded(
            child: _filteredResidents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredResidents.length,
                    itemBuilder: (context, index) {
                      final resident = _filteredResidents[index];
                      return ResidentCard(
                        resident: resident,
                        onEdit: () => _editResident(resident),
                        onDelete: () => _deleteResident(resident),
                        onTap: () => _showResidentDetails(resident),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.showFloatingActionButton ? FloatingActionButton.extended(
        heroTag: "residents_fab", // Unique hero tag
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddResidentForm(
                onResidentAdded: _addResident,
              ),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('הוסף דייר'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ) : null,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
              fontSize: 20,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'לא נמצאו דיירים',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'נסה לשנות את הסינון או הוסף דייר חדש',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סטטיסטיקות דיירים'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('סה"כ דיירים', stats['total'].toString()),
            _buildStatRow('דיירים פעילים', stats['active'].toString()),
            _buildStatRow('דיירים לא פעילים', stats['inactive'].toString()),
            _buildStatRow('בעלי דירה', stats['owners'].toString()),
            _buildStatRow('שוכרים', stats['tenants'].toString()),
            _buildStatRow('בני משפחה', stats['familyMembers'].toString()),
            _buildStatRow('אורחים', stats['guests'].toString()),
            _buildStatRow('אחוז תפוסה', '${stats['occupancyRate']}%'),
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

  String _getTypeDisplay(ResidentType type) {
    switch (type) {
      case ResidentType.owner:
        return 'בעל דירה';
      case ResidentType.tenant:
        return 'שוכר';
      case ResidentType.familyMember:
        return 'בן משפחה';
      case ResidentType.guest:
        return 'אורח';
    }
  }

  String _getStatusDisplay(ResidentStatus status) {
    switch (status) {
      case ResidentStatus.active:
        return 'פעיל';
      case ResidentStatus.inactive:
        return 'לא פעיל';
      case ResidentStatus.pending:
        return 'ממתין לאישור';
      case ResidentStatus.suspended:
        return 'מושעה';
    }
  }
}

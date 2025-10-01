import 'package:flutter/material.dart';
import '../core/models/resident.dart';
import '../core/models/building.dart';
import '../services/firebase_resident_service.dart';

class FirebaseResidentsPage extends StatefulWidget {
  final List<Building> buildings;
  
  const FirebaseResidentsPage({
    super.key,
    required this.buildings,
  });

  @override
  State<FirebaseResidentsPage> createState() => _FirebaseResidentsPageState();
}

class _FirebaseResidentsPageState extends State<FirebaseResidentsPage> {
  static const Map<String, String> _tagTranslations = {
    'VIP': 'VIP',
    'Special Needs': 'צרכים מיוחדים',
    'Pet Owner': 'בעל/ת חיית מחמד',
    'Senior Citizen': 'אזרח/ית ותיק/ה',
    'Student': 'סטודנט/ית',
    'Family with Children': 'משפחה עם ילדים',
    'Single': 'רווק/ה',
    'Working Professional': 'עובד/ת',
    'Retired': 'גמלאי/ת',
    'Medical Professional': 'איש/אשת רפואה',
    'Emergency Contact': 'איש קשר לחירום',
    'Building Committee Member': 'חבר/ת ועד הבית',
  };

  String _t(String key) => _tagTranslations[key] ?? key;
  Building? _selectedBuilding;
  List<Resident> _residents = [];
  List<Resident> _filteredResidents = [];
  String _searchQuery = '';
  ResidentType? _selectedTypeFilter;
  ResidentStatus? _selectedStatusFilter;
  bool _showOnlyActive = true;
  bool _loading = false;
  Map<String, int> _statistics = {};

  @override
  void initState() {
    super.initState();
    if (widget.buildings.isNotEmpty) {
      _selectedBuilding = widget.buildings.first;
      _loadResidents();
    }
  }

  Future<void> _loadResidents() async {
    if (_selectedBuilding == null) return;
    
    setState(() => _loading = true);
    
    try {
      // Initialize sample residents if none exist
      await FirebaseResidentService.initializeSampleResidents(_selectedBuilding!.id);
      
      // Load residents
      final residents = await FirebaseResidentService.getResidents(_selectedBuilding!.id);
      final stats = await FirebaseResidentService.getResidentStatistics(_selectedBuilding!.id);
      
      setState(() {
        _residents = residents;
        _statistics = stats;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading residents: $e');
      setState(() => _loading = false);
    }
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

  Future<void> _addResident() async {
    final result = await _showAddResidentDialog();
    if (result != null && _selectedBuilding != null) {
      await FirebaseResidentService.addResident(_selectedBuilding!.id, result);
      await _loadResidents();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הדייר נוסף בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editResident(Resident resident) async {
    final result = await _showAddResidentDialog(residentToEdit: resident);
    if (result != null && _selectedBuilding != null) {
      await FirebaseResidentService.updateResident(_selectedBuilding!.id, resident.id, result);
      await _loadResidents();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הדייר עודכן בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteResident(Resident resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק דייר'),
        content: Text('האם אתה בטוח שברצונך למחוק את ${resident.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true && _selectedBuilding != null) {
      await FirebaseResidentService.deleteResident(_selectedBuilding!.id, resident.id);
      await _loadResidents();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הדייר נמחק בהצלחה'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.buildings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('👥 דיירי הבניין'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('אין בניינים במערכת', style: TextStyle(fontSize: 18, color: Colors.grey)),
              Text('הוסף בניין ראשון כדי לנהל דיירים', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 דיירי הבניין'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _showStatisticsDialog(),
            icon: const Icon(Icons.analytics),
            tooltip: 'סטטיסטיקות',
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
                const Text('בניין:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Building>(
                    value: _selectedBuilding,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: widget.buildings.map((building) {
                      return DropdownMenuItem(
                        value: building,
                        child: Text(building.name),
                      );
                    }).toList(),
                    onChanged: (building) {
                      setState(() {
                        _selectedBuilding = building;
                      });
                      if (building != null) {
                        _loadResidents();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Statistics bar
          if (_statistics.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'סה"כ דיירים',
                      _statistics['total'].toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'פעילים',
                      _statistics['active'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'בעלי דירה',
                      _statistics['owners'].toString(),
                      Icons.home,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'שוכרים',
                      _statistics['tenants'].toString(),
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
                    // Type filter
                    Expanded(
                      child: DropdownButtonFormField<ResidentType?>(
                        value: _selectedTypeFilter,
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
                        value: _selectedStatusFilter,
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredResidents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredResidents.length,
                        itemBuilder: (context, index) {
                          final resident = _filteredResidents[index];
                          return _buildResidentCard(resident);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedBuilding != null ? _addResident : null,
        icon: const Icon(Icons.person_add),
        label: const Text('הוסף דייר'),
        backgroundColor: _selectedBuilding != null 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey,
        foregroundColor: Colors.white,
      ),
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

  Widget _buildResidentCard(Resident resident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getResidentTypeColor(resident.residentType),
          child: Icon(
            _getResidentTypeIcon(resident.residentType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          resident.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${resident.apartmentDisplay} • ${resident.phoneNumber}'),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getResidentTypeColor(resident.residentType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resident.typeDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getResidentTypeColor(resident.residentType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getResidentStatusColor(resident.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resident.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getResidentStatusColor(resident.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editResident(resident),
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'ערוך',
            ),
            IconButton(
              onPressed: () => _deleteResident(resident),
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              tooltip: 'מחק',
            ),
          ],
        ),
        onTap: () => _showResidentDetails(resident),
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

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סטטיסטיקות דיירים'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('סה"כ דיירים', _statistics['total'].toString()),
            _buildStatRow('דיירים פעילים', _statistics['active'].toString()),
            _buildStatRow('דיירים לא פעילים', _statistics['inactive'].toString()),
            _buildStatRow('בעלי דירה', _statistics['owners'].toString()),
            _buildStatRow('שוכרים', _statistics['tenants'].toString()),
            _buildStatRow('בני משפחה', _statistics['familyMembers'].toString()),
            _buildStatRow('אורחים', _statistics['guests'].toString()),
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

  void _showResidentDetails(Resident resident) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
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
                  child: _buildResidentDetailsContent(resident),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResidentDetailsContent(Resident resident) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic info
        _buildDetailSection('פרטים בסיסיים', [
          _buildDetailRow('שם מלא', resident.fullName),
          _buildDetailRow('מספר דירה', resident.apartmentDisplay),
          _buildDetailRow('טלפון', resident.phoneNumber),
          _buildDetailRow('דוא"ל', resident.email),
          _buildDetailRow('סוג דייר', resident.typeDisplay),
          _buildDetailRow('סטטוס', resident.statusDisplay),
        ]),
        
        const SizedBox(height: 20),
        
        // Dates
        _buildDetailSection('תאריכים', [
          _buildDetailRow('תאריך כניסה', _formatDate(resident.moveInDate)),
          if (resident.moveOutDate != null)
            _buildDetailRow('תאריך יציאה', _formatDate(resident.moveOutDate!)),
        ]),
        
        const SizedBox(height: 20),
        
        // Emergency contact
        if (resident.emergencyContact != null || resident.emergencyPhone != null)
          _buildDetailSection('איש קשר לחירום', [
            if (resident.emergencyContact != null)
              _buildDetailRow('שם', resident.emergencyContact!),
            if (resident.emergencyPhone != null)
              _buildDetailRow('טלפון', resident.emergencyPhone!),
          ]),
        
        const SizedBox(height: 20),
        
        // Notes
        if (resident.notes != null && resident.notes!.isNotEmpty)
          _buildDetailSection('הערות', [
            Text(resident.notes!, style: const TextStyle(fontSize: 14)),
          ]),
        
        const SizedBox(height: 20),
        
        // Tags
        if (resident.tags.isNotEmpty)
          _buildDetailSection('תגיות', [
            Wrap(
              spacing: 8,
              children: resident.tags.map((tag) => Chip(
                label: Text(_t(tag)),
                backgroundColor: Colors.blue[100],
              )).toList(),
            ),
          ]),
        
        const SizedBox(height: 20),
        
        // Custom fields
        if (resident.customFields.isNotEmpty)
          _buildDetailSection('מידע נוסף', resident.customFields.entries.map((entry) {
            return _buildDetailRow(entry.key, entry.value.toString());
          }).toList()),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<Resident?> _showAddResidentDialog({Resident? residentToEdit}) async {
    return showDialog<Resident>(
      context: context,
      builder: (context) => _AddResidentDialog(residentToEdit: residentToEdit),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getResidentTypeColor(ResidentType type) {
    switch (type) {
      case ResidentType.owner:
        return Colors.indigo;
      case ResidentType.tenant:
        return Colors.orange;
      case ResidentType.familyMember:
        return Colors.teal;
      case ResidentType.guest:
        return Colors.purple;
    }
  }

  Color _getResidentStatusColor(ResidentStatus status) {
    switch (status) {
      case ResidentStatus.active:
        return Colors.green;
      case ResidentStatus.inactive:
        return Colors.grey;
      case ResidentStatus.pending:
        return Colors.orange;
      case ResidentStatus.suspended:
        return Colors.red;
    }
  }

  IconData _getResidentTypeIcon(ResidentType type) {
    switch (type) {
      case ResidentType.owner:
        return Icons.home;
      case ResidentType.tenant:
        return Icons.key;
      case ResidentType.familyMember:
        return Icons.family_restroom;
      case ResidentType.guest:
        return Icons.person_outline;
    }
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

class _AddResidentDialog extends StatefulWidget {
  final Resident? residentToEdit;

  const _AddResidentDialog({this.residentToEdit});

  @override
  State<_AddResidentDialog> createState() => _AddResidentDialogState();
}

class _AddResidentDialogState extends State<_AddResidentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _floorController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _emergencyPhoneController;
  late final TextEditingController _notesController;
  
  late ResidentType _selectedType;
  late ResidentStatus _selectedStatus;
  late DateTime _moveInDate;

  @override
  void initState() {
    super.initState();
    
    final resident = widget.residentToEdit;
    
    _firstNameController = TextEditingController(text: resident?.firstName ?? '');
    _lastNameController = TextEditingController(text: resident?.lastName ?? '');
    _apartmentController = TextEditingController(text: resident?.apartmentNumber ?? '');
    _floorController = TextEditingController(text: resident?.floor ?? '');
    _phoneController = TextEditingController(text: resident?.phoneNumber ?? '');
    _emailController = TextEditingController(text: resident?.email ?? '');
    _emergencyContactController = TextEditingController(text: resident?.emergencyContact ?? '');
    _emergencyPhoneController = TextEditingController(text: resident?.emergencyPhone ?? '');
    _notesController = TextEditingController(text: resident?.notes ?? '');
    
    _selectedType = resident?.residentType ?? ResidentType.tenant;
    _selectedStatus = resident?.status ?? ResidentStatus.active;
    _moveInDate = resident?.moveInDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _apartmentController.dispose();
    _floorController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.residentToEdit != null;
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            AppBar(
              title: Text(isEditing ? 'ערוך דייר' : 'הוסף דייר'),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Personal details
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'שם פרטי *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'שדה חובה' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'שם משפחה *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'שדה חובה' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Apartment details
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _apartmentController,
                              decoration: const InputDecoration(
                                labelText: 'מספר דירה *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'שדה חובה' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _floorController,
                              decoration: const InputDecoration(
                                labelText: 'קומה',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Contact details
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'טלפון *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'שדה חובה' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'דוא"ל *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true) return 'שדה חובה';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                            return 'כתובת דוא"ל לא תקינה';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Type and status
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ResidentType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'סוג דייר',
                                border: OutlineInputBorder(),
                              ),
                              items: ResidentType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_getTypeDisplay(type)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<ResidentStatus>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'סטטוס',
                                border: OutlineInputBorder(),
                              ),
                              items: ResidentStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(_getStatusDisplay(status)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Move in date
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('תאריך כניסה'),
                        subtitle: Text(_formatDate(_moveInDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _moveInDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _moveInDate = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Emergency contact
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emergencyContactController,
                              decoration: const InputDecoration(
                                labelText: 'איש קשר לחירום',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emergencyPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'טלפון חירום',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'הערות',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('ביטול'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _saveResident,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isEditing ? 'עדכן' : 'הוסף'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveResident() {
    if (!_formKey.currentState!.validate()) return;
    
    final now = DateTime.now();
    final resident = Resident(
      id: widget.residentToEdit?.id ?? '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      apartmentNumber: _apartmentController.text.trim(),
      floor: _floorController.text.trim().isNotEmpty ? _floorController.text.trim() : null,
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      residentType: _selectedType,
      status: _selectedStatus,
      moveInDate: _moveInDate,
      emergencyContact: _emergencyContactController.text.trim().isNotEmpty ? _emergencyContactController.text.trim() : null,
      emergencyPhone: _emergencyPhoneController.text.trim().isNotEmpty ? _emergencyPhoneController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: widget.residentToEdit?.createdAt ?? now,
      updatedAt: now,
      isActive: _selectedStatus == ResidentStatus.active,
    );
    
    Navigator.of(context).pop(resident);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
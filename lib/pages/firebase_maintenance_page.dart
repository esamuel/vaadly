import 'package:flutter/material.dart';
import '../core/models/maintenance_request.dart';
import '../core/models/building.dart';
import '../services/firebase_maintenance_service.dart';

class FirebaseMaintenancePage extends StatefulWidget {
  final List<Building> buildings;
  
  const FirebaseMaintenancePage({
    super.key,
    required this.buildings,
  });

  @override
  State<FirebaseMaintenancePage> createState() => _FirebaseMaintenancePageState();
}

class _FirebaseMaintenancePageState extends State<FirebaseMaintenancePage> {
  Building? _selectedBuilding;
  List<MaintenanceRequest> _requests = [];
  List<MaintenanceRequest> _filteredRequests = [];
  String _searchQuery = '';
  MaintenanceCategory? _selectedCategoryFilter;
  MaintenancePriority? _selectedPriorityFilter;
  MaintenanceStatus? _selectedStatusFilter;
  bool _showOnlyUrgent = false;
  bool _showOnlyOverdue = false;
  bool _loading = false;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    if (widget.buildings.isNotEmpty) {
      _selectedBuilding = widget.buildings.first;
      _loadMaintenanceRequests();
    }
  }

  Future<void> _loadMaintenanceRequests() async {
    if (_selectedBuilding == null) return;
    
    setState(() => _loading = true);
    
    try {
      // Initialize sample requests if none exist
      await FirebaseMaintenanceService.initializeSampleMaintenanceRequests(_selectedBuilding!.id);
      
      // Load requests and statistics
      final requests = await FirebaseMaintenanceService.getMaintenanceRequests(_selectedBuilding!.id);
      final stats = await FirebaseMaintenanceService.getMaintenanceStatistics(_selectedBuilding!.id);
      
      setState(() {
        _requests = requests;
        _statistics = stats;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading maintenance requests: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    _filteredRequests = _requests.where((request) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!request.title.toLowerCase().contains(query) &&
            !request.description.toLowerCase().contains(query) &&
            !(request.location?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategoryFilter != null && request.category != _selectedCategoryFilter) {
        return false;
      }

      // Priority filter
      if (_selectedPriorityFilter != null && request.priority != _selectedPriorityFilter) {
        return false;
      }

      // Status filter
      if (_selectedStatusFilter != null && request.status != _selectedStatusFilter) {
        return false;
      }

      // Urgent filter
      if (_showOnlyUrgent && request.priority != MaintenancePriority.urgent) {
        return false;
      }

      // Overdue filter
      if (_showOnlyOverdue && !request.isOverdue) {
        return false;
      }

      return true;
    }).toList();

    // Sort by priority and date (urgent first, then by date)
    _filteredRequests.sort((a, b) {
      // First by priority (urgent first)
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      // Then by date (newest first)
      return b.reportedAt.compareTo(a.reportedAt);
    });
  }

  Future<void> _addMaintenanceRequest() async {
    final result = await _showAddMaintenanceRequestDialog();
    if (result != null && _selectedBuilding != null) {
      await FirebaseMaintenanceService.addMaintenanceRequest(_selectedBuilding!.id, result);
      await _loadMaintenanceRequests();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('בקשת תחזוקה נוספה בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editMaintenanceRequest(MaintenanceRequest request) async {
    final result = await _showAddMaintenanceRequestDialog(requestToEdit: request);
    if (result != null && _selectedBuilding != null) {
      await FirebaseMaintenanceService.updateMaintenanceRequest(_selectedBuilding!.id, request.id, result);
      await _loadMaintenanceRequests();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('בקשת תחזוקה עודכנה בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _updateRequestStatus(MaintenanceRequest request, MaintenanceStatus newStatus) async {
    if (_selectedBuilding == null) return;

    String? reason;
    String? cost;
    
    if (newStatus == MaintenanceStatus.cancelled) {
      reason = await _showReasonDialog('סיבת ביטול', 'נא להזין סיבה לביטול הבקשה');
      if (reason == null) return;
    } else if (newStatus == MaintenanceStatus.completed) {
      cost = await _showCostDialog('עלות בפועל', 'נא להזין את העלות הסופית');
      if (cost == null) return;
    }

    bool success = false;
    switch (newStatus) {
      case MaintenanceStatus.inProgress:
        success = await FirebaseMaintenanceService.startWork(_selectedBuilding!.id, request.id);
        break;
      case MaintenanceStatus.completed:
        success = await FirebaseMaintenanceService.completeWork(_selectedBuilding!.id, request.id, cost!);
        break;
      case MaintenanceStatus.cancelled:
        success = await FirebaseMaintenanceService.cancelRequest(_selectedBuilding!.id, request.id, reason!);
        break;
      default:
        break;
    }

    if (success) {
      await _loadMaintenanceRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('סטטוס עודכן ל${_getStatusDisplay(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteMaintenanceRequest(MaintenanceRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק בקשת תחזוקה'),
        content: Text('האם אתה בטוח שברצונך למחוק את "${request.title}"?'),
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
      await FirebaseMaintenanceService.deleteMaintenanceRequest(_selectedBuilding!.id, request.id);
      await _loadMaintenanceRequests();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('בקשת תחזוקה נמחקה בהצלחה'),
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
          title: const Text('🔧 תחזוקה'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('אין בניינים במערכת', style: TextStyle(fontSize: 18, color: Colors.grey)),
              Text('הוסף בניין ראשון כדי לנהל תחזוקה', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 תחזוקה'),
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
                        _loadMaintenanceRequests();
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
              color: Colors.orange[50],
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'סה"כ בקשות',
                          _statistics['total'].toString(),
                          Icons.build,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'ממתינות',
                          _statistics['pending'].toString(),
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'בתהליך',
                          _statistics['inProgress'].toString(),
                          Icons.work,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'דחופות',
                          _statistics['urgent'].toString(),
                          Icons.priority_high,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'הושלמו',
                          _statistics['completed'].toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'איחור',
                          _statistics['overdue'].toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'השלמות',
                          '${_statistics['completionRate']}%',
                          Icons.trending_up,
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox()), // Empty space for alignment
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
                    hintText: 'חיפוש לפי כותרת, תיאור או מיקום...',
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

                // Filters row 1
                Row(
                  children: [
                    // Category filter
                    Expanded(
                      child: DropdownButtonFormField<MaintenanceCategory?>(
                        value: _selectedCategoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'קטגוריה',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('כל הקטגוריות')),
                          ...MaintenanceCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(_getCategoryDisplay(category)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Priority filter
                    Expanded(
                      child: DropdownButtonFormField<MaintenancePriority?>(
                        value: _selectedPriorityFilter,
                        decoration: const InputDecoration(
                          labelText: 'עדיפות',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('כל העדיפויות')),
                          ...MaintenancePriority.values.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Text(_getPriorityDisplay(priority)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPriorityFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filters row 2
                Row(
                  children: [
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<MaintenanceStatus?>(
                        value: _selectedStatusFilter,
                        decoration: const InputDecoration(
                          labelText: 'סטטוס',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('כל הסטטוסים')),
                          ...MaintenanceStatus.values.map((status) {
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

                    // Special filters
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: FilterChip(
                              label: const Text('רק דחופות'),
                              selected: _showOnlyUrgent,
                              onSelected: (value) {
                                setState(() {
                                  _showOnlyUrgent = value;
                                  _applyFilters();
                                });
                              },
                              selectedColor: Colors.red.withOpacity(0.3),
                              checkmarkColor: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilterChip(
                              label: const Text('רק באיחור'),
                              selected: _showOnlyOverdue,
                              onSelected: (value) {
                                setState(() {
                                  _showOnlyOverdue = value;
                                  _applyFilters();
                                });
                              },
                              selectedColor: Colors.orange.withOpacity(0.3),
                              checkmarkColor: Colors.orange,
                            ),
                          ),
                        ],
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
                  'נמצאו ${_filteredRequests.length} בקשות תחזוקה',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_filteredRequests.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedCategoryFilter = null;
                        _selectedPriorityFilter = null;
                        _selectedStatusFilter = null;
                        _showOnlyUrgent = false;
                        _showOnlyOverdue = false;
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

          // Maintenance requests list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          return _buildMaintenanceRequestCard(request);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedBuilding != null ? _addMaintenanceRequest : null,
        icon: const Icon(Icons.add),
        label: const Text('הוסף בקשה'),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceRequestCard(MaintenanceRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: request.priorityColor,
          child: Icon(
            _getCategoryIcon(request.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          request.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: request.isOverdue ? Colors.red : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: request.priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.priorityDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: request.priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: request.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (request.isOverdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'באיחור',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${request.categoryDisplay} • ${request.timeSinceReportedDisplay}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editMaintenanceRequest(request);
                break;
              case 'start':
                _updateRequestStatus(request, MaintenanceStatus.inProgress);
                break;
              case 'complete':
                _updateRequestStatus(request, MaintenanceStatus.completed);
                break;
              case 'cancel':
                _updateRequestStatus(request, MaintenanceStatus.cancelled);
                break;
              case 'delete':
                _deleteMaintenanceRequest(request);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('ערוך')),
            if (request.status == MaintenanceStatus.assigned)
              const PopupMenuItem(value: 'start', child: Text('התחל עבודה')),
            if (request.status == MaintenanceStatus.inProgress)
              const PopupMenuItem(value: 'complete', child: Text('סיים עבודה')),
            if (request.status != MaintenanceStatus.cancelled && 
                request.status != MaintenanceStatus.completed)
              const PopupMenuItem(value: 'cancel', child: Text('בטל')),
            const PopupMenuItem(
              value: 'delete', 
              child: Text('מחק', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  'תיאור:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(request.description),
                const SizedBox(height: 12),

                // Details
                if (request.location != null) ...[
                  _buildDetailRow('מיקום', request.location!),
                ],
                if (request.assignedVendorName != null) ...[
                  _buildDetailRow('קבלן', request.assignedVendorName!),
                ],
                if (request.estimatedCost != null) ...[
                  _buildDetailRow('עלות משוערת', request.estimatedCost!),
                ],
                if (request.actualCost != null) ...[
                  _buildDetailRow('עלות בפועל', request.actualCost!),
                ],
                
                // Dates
                _buildDetailRow('דווח בתאריך', _formatDate(request.reportedAt)),
                if (request.assignedAt != null)
                  _buildDetailRow('הוקצה בתאריך', _formatDate(request.assignedAt!)),
                if (request.startedAt != null)
                  _buildDetailRow('התחיל בתאריך', _formatDate(request.startedAt!)),
                if (request.completedAt != null)
                  _buildDetailRow('הושלם בתאריך', _formatDate(request.completedAt!)),

                // Notes
                if (request.notes != null && request.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'הערות:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(request.notes!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'לא נמצאו בקשות תחזוקה',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'נסה לשנות את הסינון או הוסף בקשה חדשה',
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
        title: const Text('סטטיסטיקות תחזוקה'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('סה"כ בקשות', _statistics['total'].toString()),
              _buildStatRow('ממתינות', _statistics['pending'].toString()),
              _buildStatRow('בתהליך', _statistics['inProgress'].toString()),
              _buildStatRow('הושלמו', _statistics['completed'].toString()),
              _buildStatRow('דחופות', _statistics['urgent'].toString()),
              _buildStatRow('באיחור', _statistics['overdue'].toString()),
              _buildStatRow('אחוז השלמות', '${_statistics['completionRate']}%'),
              
              const SizedBox(height: 16),
              const Text('פירוט לפי קטגוריה:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(_statistics['categoryBreakdown'] as Map<String, int>).entries.map(
                (entry) => _buildStatRow(entry.key, entry.value.toString()),
              ),
            ],
          ),
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

  Future<MaintenanceRequest?> _showAddMaintenanceRequestDialog({MaintenanceRequest? requestToEdit}) async {
    return showDialog<MaintenanceRequest>(
      context: context,
      builder: (context) => _AddMaintenanceRequestDialog(requestToEdit: requestToEdit),
    );
  }

  Future<String?> _showReasonDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showCostDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            prefixText: '₪',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('₪${controller.text.trim()}'),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getCategoryIcon(MaintenanceCategory category) {
    switch (category) {
      case MaintenanceCategory.plumbing:
        return Icons.plumbing;
      case MaintenanceCategory.electrical:
        return Icons.electrical_services;
      case MaintenanceCategory.hvac:
        return Icons.air;
      case MaintenanceCategory.cleaning:
        return Icons.cleaning_services;
      case MaintenanceCategory.gardening:
        return Icons.grass;
      case MaintenanceCategory.elevator:
        return Icons.elevator;
      case MaintenanceCategory.security:
        return Icons.security;
      case MaintenanceCategory.structural:
        return Icons.foundation;
      case MaintenanceCategory.sanitation:
        return Icons.cleaning_services;
      case MaintenanceCategory.general:
        return Icons.build;
    }
  }

  String _getCategoryDisplay(MaintenanceCategory category) {
    switch (category) {
      case MaintenanceCategory.plumbing:
        return 'אינסטלציה';
      case MaintenanceCategory.electrical:
        return 'חשמל';
      case MaintenanceCategory.hvac:
        return 'מיזוג אוויר';
      case MaintenanceCategory.cleaning:
        return 'ניקיון';
      case MaintenanceCategory.gardening:
        return 'גינון';
      case MaintenanceCategory.elevator:
        return 'מעליות';
      case MaintenanceCategory.security:
        return 'אבטחה';
      case MaintenanceCategory.structural:
        return 'מבני';
      case MaintenanceCategory.sanitation:
        return 'תברואה';
      case MaintenanceCategory.general:
        return 'כללי';
    }
  }

  String _getPriorityDisplay(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.urgent:
        return 'דחוף';
      case MaintenancePriority.high:
        return 'גבוה';
      case MaintenancePriority.normal:
        return 'רגיל';
      case MaintenancePriority.low:
        return 'נמוך';
    }
  }

  String _getStatusDisplay(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return 'ממתין';
      case MaintenanceStatus.assigned:
        return 'מוקצה';
      case MaintenanceStatus.inProgress:
        return 'בתהליך';
      case MaintenanceStatus.onHold:
        return 'מושהה';
      case MaintenanceStatus.completed:
        return 'הושלם';
      case MaintenanceStatus.cancelled:
        return 'בוטל';
      case MaintenanceStatus.rejected:
        return 'נדחה';
    }
  }
}

class _AddMaintenanceRequestDialog extends StatefulWidget {
  final MaintenanceRequest? requestToEdit;

  const _AddMaintenanceRequestDialog({this.requestToEdit});

  @override
  State<_AddMaintenanceRequestDialog> createState() => _AddMaintenanceRequestDialogState();
}

class _AddMaintenanceRequestDialogState extends State<_AddMaintenanceRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _estimatedCostController;
  late final TextEditingController _notesController;
  
  late MaintenanceCategory _selectedCategory;
  late MaintenancePriority _selectedPriority;
  late bool _isUrgent;

  @override
  void initState() {
    super.initState();
    
    final request = widget.requestToEdit;
    
    _titleController = TextEditingController(text: request?.title ?? '');
    _descriptionController = TextEditingController(text: request?.description ?? '');
    _locationController = TextEditingController(text: request?.location ?? '');
    _estimatedCostController = TextEditingController(text: request?.estimatedCost ?? '');
    _notesController = TextEditingController(text: request?.notes ?? '');
    
    _selectedCategory = request?.category ?? MaintenanceCategory.general;
    _selectedPriority = request?.priority ?? MaintenancePriority.normal;
    _isUrgent = request?.isUrgent ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _estimatedCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.requestToEdit != null;
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: Text(isEditing ? 'ערוך בקשת תחזוקה' : 'הוסף בקשת תחזוקה'),
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
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'כותרת הבקשה *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'שדה חובה' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'תיאור הבעיה *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) => value?.isEmpty == true ? 'שדה חובה' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Category and Priority
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<MaintenanceCategory>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'קטגוריה',
                                border: OutlineInputBorder(),
                              ),
                              items: MaintenanceCategory.values.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(_getCategoryDisplay(category)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<MaintenancePriority>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'עדיפות',
                                border: OutlineInputBorder(),
                              ),
                              items: MaintenancePriority.values.map((priority) {
                                return DropdownMenuItem(
                                  value: priority,
                                  child: Text(_getPriorityDisplay(priority)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value!;
                                  _isUrgent = value == MaintenancePriority.urgent;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'מיקום',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Estimated cost
                      TextFormField(
                        controller: _estimatedCostController,
                        decoration: const InputDecoration(
                          labelText: 'עלות משוערת',
                          border: OutlineInputBorder(),
                          prefixText: '₪',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      
                      // Urgent checkbox
                      CheckboxListTile(
                        title: const Text('בקשה דחופה'),
                        subtitle: const Text('דורש טיפול מיידי'),
                        value: _isUrgent,
                        onChanged: (value) {
                          setState(() {
                            _isUrgent = value!;
                            if (value) {
                              _selectedPriority = MaintenancePriority.urgent;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'הערות נוספות',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
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
                            onPressed: _saveRequest,
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

  void _saveRequest() {
    if (!_formKey.currentState!.validate()) return;
    
    final now = DateTime.now();
    final request = MaintenanceRequest(
      id: widget.requestToEdit?.id ?? '',
      buildingId: widget.requestToEdit?.buildingId ?? '',
      unitId: widget.requestToEdit?.unitId,
      residentId: widget.requestToEdit?.residentId ?? 'current_user',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      status: widget.requestToEdit?.status ?? MaintenanceStatus.pending,
      assignedVendorId: widget.requestToEdit?.assignedVendorId,
      assignedVendorName: widget.requestToEdit?.assignedVendorName,
      reportedAt: widget.requestToEdit?.reportedAt ?? now,
      assignedAt: widget.requestToEdit?.assignedAt,
      startedAt: widget.requestToEdit?.startedAt,
      completedAt: widget.requestToEdit?.completedAt,
      cancelledAt: widget.requestToEdit?.cancelledAt,
      cancellationReason: widget.requestToEdit?.cancellationReason,
      rejectionReason: widget.requestToEdit?.rejectionReason,
      photoUrls: widget.requestToEdit?.photoUrls ?? [],
      documentUrls: widget.requestToEdit?.documentUrls ?? [],
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      estimatedCost: _estimatedCostController.text.trim().isNotEmpty ? '₪${_estimatedCostController.text.trim()}' : null,
      actualCost: widget.requestToEdit?.actualCost,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      isUrgent: _isUrgent,
      requiresImmediateAttention: _isUrgent,
      createdAt: widget.requestToEdit?.createdAt ?? now,
      updatedAt: now,
      isActive: widget.requestToEdit?.isActive ?? true,
    );
    
    Navigator.of(context).pop(request);
  }

  String _getCategoryDisplay(MaintenanceCategory category) {
    switch (category) {
      case MaintenanceCategory.plumbing:
        return 'אינסטלציה';
      case MaintenanceCategory.electrical:
        return 'חשמל';
      case MaintenanceCategory.hvac:
        return 'מיזוג אוויר';
      case MaintenanceCategory.cleaning:
        return 'ניקיון';
      case MaintenanceCategory.gardening:
        return 'גינון';
      case MaintenanceCategory.elevator:
        return 'מעליות';
      case MaintenanceCategory.security:
        return 'אבטחה';
      case MaintenanceCategory.structural:
        return 'מבני';
      case MaintenanceCategory.sanitation:
        return 'תברואה';
      case MaintenanceCategory.general:
        return 'כללי';
    }
  }

  String _getPriorityDisplay(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.urgent:
        return 'דחוף';
      case MaintenancePriority.high:
        return 'גבוה';
      case MaintenancePriority.normal:
        return 'רגיל';
      case MaintenancePriority.low:
        return 'נמוך';
    }
  }
}
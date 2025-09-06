import 'package:flutter/material.dart';
import '../../core/models/maintenance_request.dart';
import '../../core/services/building_context_service.dart';
import '../../services/firebase_activity_service.dart';
import '../../services/firebase_maintenance_service.dart';
import '../../services/firebase_vendor_service.dart';

class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  int _selectedFilterIndex = 0;
  List<MaintenanceRequest> _requests = [];
  bool _loading = false;
  Stream<List<MaintenanceRequest>>? _requestStream;

  final List<String> _filterOptions = [
    'הכל',
    'פתוח',
    'בטיפול',
    'הושלם',
    'דחוף',
  ];

  @override
  void initState() {
    super.initState();
    _loadMaintenanceData();
  }

  Future<void> _loadMaintenanceData() async {
    setState(() => _loading = true);

    // Simulate loading maintenance requests
    await Future.delayed(const Duration(milliseconds: 500));

    // If building context exists, prefer Firestore stream
    final buildingId = BuildingContextService.buildingId;
    if (buildingId != null) {
      _requestStream = _firestoreStream(buildingId);
      setState(() => _loading = false);
      return;
    }

    _requests = [
      MaintenanceRequest(
        id: '1',
        buildingId: 'building1',
        residentId: 'resident1',
        title: 'דליפת מים בקומה 3',
        description: 'יש דליפת מים מהתקרה בחדר המדרגות',
        category: MaintenanceCategory.plumbing,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.pending,
        reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
        location: 'קומה 3 - חדר מדרגות',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      MaintenanceRequest(
        id: '2',
        buildingId: 'building1',
        residentId: 'resident2',
        title: 'תקלה במעלית',
        description: 'המעלית לא עובדת כראוי',
        category: MaintenanceCategory.elevator,
        priority: MaintenancePriority.urgent,
        status: MaintenanceStatus.inProgress,
        reportedAt: DateTime.now().subtract(const Duration(days: 1)),
        location: 'מעלית מרכזית',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MaintenanceRequest(
        id: '3',
        buildingId: 'building1',
        residentId: 'resident3',
        title: 'תיקון דלת כניסה',
        description: 'הדלת הראשית לא נסגרת כראוי',
        category: MaintenanceCategory.general,
        priority: MaintenancePriority.normal,
        status: MaintenanceStatus.completed,
        reportedAt: DateTime.now().subtract(const Duration(days: 3)),
        location: 'כניסה ראשית',
        completedAt: DateTime.now().subtract(const Duration(hours: 6)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      MaintenanceRequest(
        id: '4',
        buildingId: 'building1',
        residentId: 'resident4',
        title: 'ניקוי גינה',
        description: 'הגינה צריכה ניקוי וטיפוח',
        category: MaintenanceCategory.gardening,
        priority: MaintenancePriority.low,
        status: MaintenanceStatus.pending,
        reportedAt: DateTime.now().subtract(const Duration(days: 2)),
        location: 'גינה ציבורית',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    setState(() => _loading = false);
  }

  Stream<List<MaintenanceRequest>> _firestoreStream(String buildingId) {
    return FirebaseMaintenanceService.streamMaintenanceRequests(buildingId);
  }

  List<MaintenanceRequest> _applyFilterTo(List<MaintenanceRequest> src) {
    if (_selectedFilterIndex == 0) return src;

    if (_selectedFilterIndex == 4) {
      return src.where((req) => req.priority == MaintenancePriority.urgent).toList();
    }

    final statusMap = {
      1: MaintenanceStatus.pending,
      2: MaintenanceStatus.inProgress,
      3: MaintenanceStatus.completed,
    };

    final status = statusMap[_selectedFilterIndex];
    return src.where((req) => req.status == status).toList();
  }

  List<MaintenanceRequest> get _filteredRequests {
    if (_selectedFilterIndex == 0) return _requests;

    final statusMap = {
      1: MaintenanceStatus.pending,
      2: MaintenanceStatus.inProgress,
      3: MaintenanceStatus.completed,
      4: MaintenancePriority.urgent,
    };

    if (_selectedFilterIndex == 4) {
      return _requests
          .where((req) => req.priority == MaintenancePriority.urgent)
          .toList();
    }

    return _requests
        .where((req) => req.status == statusMap[_selectedFilterIndex])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 ניהול תחזוקה'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadMaintenanceData,
            icon: const Icon(Icons.refresh),
            tooltip: 'רענן',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                    child: _buildStatCard('סה"כ בקשות',
                        _requests.length.toString(), Icons.list, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'פתוחות',
                        _requests
                            .where((r) => r.status == MaintenanceStatus.pending)
                            .length
                            .toString(),
                        Icons.pending,
                        Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'דחופות',
                        _requests
                            .where(
                                (r) => r.priority == MaintenancePriority.urgent)
                            .length
                            .toString(),
                        Icons.priority_high,
                        Colors.red)),
              ],
            ),
          ),

          // Filter tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedFilterIndex;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterOptions[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilterIndex = index);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.indigo[100],
                    checkmarkColor: Colors.indigo,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Requests list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _requestStream != null
                    ? StreamBuilder<List<MaintenanceRequest>>(
                        stream: _requestStream,
                        builder: (context, snapshot) {
                          final data = snapshot.data ?? _requests;
                          final shown = _applyFilterTo(data);
                          if (shown.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.build, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('אין בקשות תחזוקה',
                                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: shown.length,
                            itemBuilder: (context, index) {
                              final request = shown[index];
                              return _buildRequestCard(request);
                            },
                          );
                        },
                      )
                    : _filteredRequests.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('אין בקשות תחזוקה',
                                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredRequests.length,
                            itemBuilder: (context, index) {
                              final request = _filteredRequests[index];
                              return _buildRequestCard(request);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "maintenance_fab",
        onPressed: () => _showAddRequestDialog(),
        icon: const Icon(Icons.add),
        label: const Text('בקשה חדשה'),
        backgroundColor: Colors.indigo,
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
          Icon(icon, color: color, size: 24),
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

  Widget _buildRequestCard(MaintenanceRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(request.priority).withOpacity(0.2),
          child: Icon(
            _getCategoryIcon(request.category),
            color: _getPriorityColor(request.priority),
          ),
        ),
        title: Text(
          request.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(request.location ?? 'לא צוין',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('דווח על ידי: דייר ${request.residentId}',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusChip(request.status),
            const SizedBox(height: 4),
            Text(
              _formatTimeAgo(request.reportedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _showRequestDetails(request),
      ),
    );
  }

  Widget _buildStatusChip(MaintenanceStatus status) {
    final statusData = {
      MaintenanceStatus.pending: {'label': 'ממתין', 'color': Colors.orange},
      MaintenanceStatus.inProgress: {'label': 'בטיפול', 'color': Colors.blue},
      MaintenanceStatus.completed: {'label': 'הושלם', 'color': Colors.green},
      MaintenanceStatus.cancelled: {'label': 'בוטל', 'color': Colors.grey},
    };

    final data = statusData[status]!;
    final color = data['color'] as Color;
    final label = data['label'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.normal:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.red;
      case MaintenancePriority.urgent:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(MaintenanceCategory category) {
    switch (category) {
      case MaintenanceCategory.plumbing:
        return Icons.water_drop;
      case MaintenanceCategory.electrical:
        return Icons.electric_bolt;
      case MaintenanceCategory.elevator:
        return Icons.elevator;
      case MaintenanceCategory.gardening:
        return Icons.park;
      case MaintenanceCategory.general:
        return Icons.build;
      default:
        return Icons.build;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'לפני ${difference.inMinutes} דקות';
    } else if (difference.inHours < 24) {
      return 'לפני ${difference.inHours} שעות';
    } else {
      return 'לפני ${difference.inDays} ימים';
    }
  }

  void _showRequestDetails(MaintenanceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('תיאור: ${request.description}'),
            const SizedBox(height: 8),
            Text('מיקום: ${request.location ?? 'לא צוין'}'),
            const SizedBox(height: 8),
            Text('דווח על ידי: דייר ${request.residentId}'),
            const SizedBox(height: 8),
            Text('תאריך: ${_formatDateTime(request.reportedAt)}'),
            if (request.completedAt != null) ...[
              const SizedBox(height: 8),
              Text('הושלם: ${_formatDateTime(request.completedAt!)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Assign to vendor
              final vendor = await _pickVendor(request.buildingId);
              if (vendor != null) {
                await FirebaseMaintenanceService.assignToVendor(request.buildingId, request.id, vendor['id']!, vendor['name']!);
                await FirebaseActivityService.logActivity(
                  buildingId: request.buildingId,
                  type: 'maintenance_assigned',
                  title: 'הוקצה לספק',
                  subtitle: vendor['name']!,
                );
                if (mounted) setState(() {});
              }
            },
            child: const Text('שייך לספק'),
          ),
          if (request.status == MaintenanceStatus.pending)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Start work in Firestore
                await FirebaseMaintenanceService.startWork(request.buildingId, request.id);
                await FirebaseActivityService.logActivity(
                  buildingId: request.buildingId,
                  type: 'maintenance_started',
                  title: 'טיפול התחיל',
                  subtitle: request.title,
                );
                setState(() {});
              },
              child: const Text('התחל טיפול'),
            ),
          if (request.status != MaintenanceStatus.completed)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Complete in Firestore
                await FirebaseMaintenanceService.completeWork(request.buildingId, request.id, '');
                await FirebaseActivityService.logActivity(
                  buildingId: request.buildingId,
                  type: 'maintenance_completed',
                  title: 'טיפול הושלם',
                  subtitle: request.title,
                );
                setState(() {});
              },
              child: const Text('סמן כהושלם'),
            ),
        ],
      ),
    );
  }

  void _showAddRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddMaintenanceRequestDialog(
        onSubmit: (request) async {
          // Persist to Firestore if possible
          final buildingId = request.buildingId;
          String? savedId;
          if (buildingId.isNotEmpty) {
            savedId = await FirebaseMaintenanceService.addMaintenanceRequest(buildingId, request);
          }
          if (savedId == null) {
            // Fallback locally
            setState(() {
              _requests.insert(0, request);
            });
          }
        },
      ),
    );
  }

  Future<Map<String, String>?> _pickVendor(String buildingId) async {
    final vendors = await FirebaseVendorService.getAllVendors();
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר ספק'),
        content: SizedBox(
          width: 420,
          height: 360,
          child: ListView.builder(
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final v = vendors[index];
              return ListTile(
                leading: const Icon(Icons.business),
                title: Text(v.name),
                subtitle: Text(v.categoriesDisplay),
                onTap: () => Navigator.of(context).pop({'id': v.id, 'name': v.name}),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  void _updateRequestStatus(
      MaintenanceRequest request, MaintenanceStatus newStatus) {
    setState(() {
      final index = _requests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _requests[index] = request.copyWith(
          status: newStatus,
          completedAt:
              newStatus == MaintenanceStatus.completed ? DateTime.now() : null,
        );
      }
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _AddMaintenanceRequestDialog extends StatefulWidget {
  final void Function(MaintenanceRequest request) onSubmit;
  const _AddMaintenanceRequestDialog({required this.onSubmit});

  @override
  State<_AddMaintenanceRequestDialog> createState() => _AddMaintenanceRequestDialogState();
}

class _AddMaintenanceRequestDialogState extends State<_AddMaintenanceRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  MaintenanceCategory _category = MaintenanceCategory.general;
  MaintenancePriority _priority = MaintenancePriority.normal;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('בקשת תחזוקה חדשה'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'כותרת *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'נדרשת כותרת' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'תיאור *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'נדרש תיאור' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'מיקום',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<MaintenanceCategory>(
                        value: _category,
                        items: MaintenanceCategory.values.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_categoryLabel(c)),
                        )).toList(),
                        onChanged: (v) => setState(() => _category = v ?? MaintenanceCategory.general),
                        decoration: const InputDecoration(
                          labelText: 'קטגוריה',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<MaintenancePriority>(
                        value: _priority,
                        items: MaintenancePriority.values.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(_priorityLabel(p)),
                        )).toList(),
                        onChanged: (v) => setState(() => _priority = v ?? MaintenancePriority.normal),
                        decoration: const InputDecoration(
                          labelText: 'עדיפות',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('שמור'),
        ),
      ],
    );
  }

  String _categoryLabel(MaintenanceCategory c) {
    switch (c) {
      case MaintenanceCategory.plumbing:
        return 'אינסטלציה';
      case MaintenanceCategory.electrical:
        return 'חשמל';
      case MaintenanceCategory.elevator:
        return 'מעלית';
      case MaintenanceCategory.gardening:
        return 'גינון';
      case MaintenanceCategory.general:
      default:
        return 'כללי';
    }
  }

  String _priorityLabel(MaintenancePriority p) {
    switch (p) {
      case MaintenancePriority.low:
        return 'נמוכה';
      case MaintenancePriority.normal:
        return 'רגילה';
      case MaintenancePriority.high:
        return 'גבוהה';
      case MaintenancePriority.urgent:
        return 'דחופה';
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final request = MaintenanceRequest(
      id: now.millisecondsSinceEpoch.toString(),
      buildingId: (BuildingContextService.currentBuilding?.buildingId ?? 'demo_building_1'),
      residentId: 'committee',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      priority: _priority,
      status: MaintenanceStatus.pending,
      reportedAt: now,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );
    // Log activity (best-effort)
    try {
      await FirebaseActivityService.logActivity(
        buildingId: request.buildingId,
        type: 'maintenance_created',
        title: 'בקשת תחזוקה חדשה',
        subtitle: request.title,
        extra: {
          'priority': _priorityLabel(request.priority),
          'category': _categoryLabel(request.category),
        },
      );
    } catch (_) {}

    widget.onSubmit(request);
    Navigator.of(context).pop();
  }
}

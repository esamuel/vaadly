import 'package:flutter/material.dart';
import '../../core/models/maintenance_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/building_context_service.dart';
import '../../services/firebase_activity_service.dart';
import '../../services/firebase_maintenance_service.dart';
import '../resources/resource_management_page.dart';

class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  int _selectedFilterIndex = 0;
  final List<MaintenanceRequest> _requests = [];
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
    // Ensure building context is set to demo building
    try {
      if (!BuildingContextService.hasBuilding) {
        await BuildingContextService.setBuildingContext('demo_building_1');
      }
    } catch (e) {
      print('Warning: Could not set building context: $e');
    }

    // If building context exists, prefer Firestore stream
    final buildingId = BuildingContextService.buildingId ??
                       BuildingContextService.currentBuilding?.buildingId ??
                       'demo_building_1';

    print('🔍 MaintenanceDashboard: Loading requests for building ID: $buildingId');
    print('🔍 MaintenanceDashboard: BuildingContext.buildingId = ${BuildingContextService.buildingId}');
    print('🔍 MaintenanceDashboard: BuildingContext.currentBuilding?.buildingId = ${BuildingContextService.currentBuilding?.buildingId}');

    setState(() {
      _requestStream = _firestoreStream(buildingId);
    });
  }

  Stream<List<MaintenanceRequest>> _firestoreStream(String buildingId) {
    return FirebaseMaintenanceService.streamMaintenanceRequests(buildingId);
  }

  List<MaintenanceRequest> _applyFilterTo(List<MaintenanceRequest> src) {
    if (_selectedFilterIndex == 0) return src; // All

    if (_selectedFilterIndex == 4) {
      // Urgent
      return src
          .where((req) => req.priority == MaintenancePriority.urgent)
          .toList();
    }

    if (_selectedFilterIndex == 1) {
      // Open - includes pending and assigned
      return src
          .where((req) =>
              req.status == MaintenanceStatus.pending ||
              req.status == MaintenanceStatus.assigned)
          .toList();
    }

    final statusMap = {
      2: MaintenanceStatus.inProgress,
      3: MaintenanceStatus.completed,
    };

    final status = statusMap[_selectedFilterIndex];
    return src.where((req) => req.status == status).toList();
  }

  List<MaintenanceRequest> get _filteredRequests {
    if (_selectedFilterIndex == 0) return _requests; // All

    if (_selectedFilterIndex == 4) {
      // Urgent
      return _requests
          .where((req) => req.priority == MaintenancePriority.urgent)
          .toList();
    }

    if (_selectedFilterIndex == 1) {
      // Open - includes pending and assigned
      return _requests
          .where((req) =>
              req.status == MaintenanceStatus.pending ||
              req.status == MaintenanceStatus.assigned)
          .toList();
    }

    final statusMap = {
      2: MaintenanceStatus.inProgress,
      3: MaintenanceStatus.completed,
    };

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
            icon: const Icon(Icons.build),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ResourceManagementPage(
                    buildingId: BuildingContextService.buildingId ?? 'demo_building_1',
                  ),
                ),
              );
            },
            tooltip: 'ניהול ספקים',
          ),
          IconButton(
            onPressed: _loadMaintenanceData,
            icon: const Icon(Icons.refresh),
            tooltip: 'רענן',
          ),
        ],
      ),
      body: _requestStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<MaintenanceRequest>>(
              stream: _requestStream,
              builder: (context, snapshot) {
                // Show loading while waiting for first data
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Use snapshot data if available, otherwise empty list
                final allRequests = snapshot.data ?? [];

                print('🔍 MaintenanceDashboard UI: Rendering with ${allRequests.length} requests');
                return _buildMainContent(allRequests);
              },
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

  Widget _buildMainContent(List<MaintenanceRequest> allRequests) {
    final totalCount = allRequests.length;
    final openCount = allRequests
        .where((r) =>
            r.status == MaintenanceStatus.pending ||
            r.status == MaintenanceStatus.assigned)
        .length;
    final urgentCount = allRequests
        .where((r) => r.priority == MaintenancePriority.urgent)
        .length;

    print('🔍 MaintenanceDashboard _buildMainContent: Total=$totalCount, Open=$openCount, Urgent=$urgentCount');

    return Column(
      children: [
        // Statistics cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                  child: _buildStatCard('סה"כ בקשות',
                      totalCount.toString(), Icons.list, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'פתוחות',
                      openCount.toString(),
                      Icons.pending,
                      Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'דחופות',
                      urgentCount.toString(),
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
          child: Builder(
            builder: (context) {
              final shown = _applyFilterTo(allRequests);
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
          ),
        ),
      ],
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
            if (request.assignedVendorName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text('ספק: ${request.assignedVendorName}',
                      style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500)),
                ],
              ),
            ],
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
      MaintenanceStatus.assigned: {'label': 'מוקצה', 'color': Colors.cyan},
      MaintenanceStatus.inProgress: {'label': 'בטיפול', 'color': Colors.blue},
      MaintenanceStatus.onHold: {'label': 'מושהה', 'color': Colors.amber},
      MaintenanceStatus.completed: {'label': 'הושלם', 'color': Colors.green},
      MaintenanceStatus.cancelled: {'label': 'בוטל', 'color': Colors.grey},
      MaintenanceStatus.rejected: {'label': 'נדחה', 'color': Colors.red},
    };

    final data = statusData[status] ?? {'label': 'לא ידוע', 'color': Colors.grey};
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
    print('🔍 Debug: Showing request details for ${request.title}');
    print('🔍 Debug: Request status: ${request.status}');
    print('🔍 Debug: Request status display: ${request.statusDisplay}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request.title),
        content: SizedBox(
          width: 500,
          child: Column(
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
              const SizedBox(height: 8),
              Text('סטטוס: ${request.statusDisplay}'),
              const SizedBox(height: 8),
              if (request.assignedVendorName != null) ...[
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Text('ספק: ${request.assignedVendorName}',
                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text('🔍 Debug Status: ${request.status.toString()}'),
              if (request.completedAt != null) ...[
                const SizedBox(height: 8),
                Text('הושלם: ${_formatDateTime(request.completedAt!)}'),
              ],
            ],
          ),
        ),
        actions: [
          // Wrap actions in a scrollable container for better mobile support
          SizedBox(
            width: double.maxFinite,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('סגור'),
                ),
                // Always show reject button for testing
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    print('🔍 Debug: Reject button pressed');
                    Navigator.of(context).pop();
                    await FirebaseMaintenanceService.rejectRequest(
                        request.buildingId, request.id, 'נדחה על ידי הוועד');
                    await FirebaseActivityService.logActivity(
                      buildingId: request.buildingId,
                      type: 'maintenance_rejected',
                      title: 'הבקשה נדחתה',
                      subtitle: request.title,
                    );
                    if (mounted) setState(() {});
                  },
                  child: const Text('דחה', style: TextStyle(color: Colors.white)),
                ),
                if (request.status == MaintenanceStatus.pending)
                  ElevatedButton(
                    onPressed: () async {
                      // Put on hold
                      Navigator.of(context).pop();
                      await FirebaseMaintenanceService.putOnHold(
                          request.buildingId, request.id);
                      await FirebaseActivityService.logActivity(
                        buildingId: request.buildingId,
                        type: 'maintenance_on_hold',
                        title: 'הבקשה הושהתה',
                        subtitle: request.title,
                      );
                      if (mounted) setState(() {});
                    },
                    child: const Text('השהה'),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    print('🔍 Debug: Assign vendor button pressed');
                    // Assign to vendor
                    final vendor = await _pickVendor(request.buildingId);
                    if (vendor != null) {
                      print('🔍 Debug: Selected vendor: ${vendor['name']}');
                      await FirebaseMaintenanceService.assignToVendor(
                          request.buildingId,
                          request.id,
                          vendor['id']!,
                          vendor['name']!);
                      await FirebaseActivityService.logActivity(
                        buildingId: request.buildingId,
                        type: 'maintenance_assigned',
                        title: 'הוקצה לספק',
                        subtitle: vendor['name']!,
                      );
                      if (mounted) setState(() {});
                    } else {
                      print('🔍 Debug: No vendor selected');
                    }
                  },
                  child: const Text('שייך לספק'),
                ),
                if (request.status == MaintenanceStatus.pending)
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Start work in Firestore
                      await FirebaseMaintenanceService.startWork(
                          request.buildingId, request.id);
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
                ElevatedButton(
                  onPressed: () async {
                    print('🔍 Debug: Complete button pressed');
                    Navigator.of(context).pop();
                    // Complete in Firestore
                    await FirebaseMaintenanceService.completeWork(
                        request.buildingId, request.id, '');
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
                if (request.status != MaintenanceStatus.completed &&
                    request.status != MaintenanceStatus.cancelled)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await FirebaseMaintenanceService.cancelRequest(
                          request.buildingId, request.id, 'בוטל על ידי הוועד');
                      await FirebaseActivityService.logActivity(
                        buildingId: request.buildingId,
                        type: 'maintenance_cancelled',
                        title: 'בקשה בוטלה',
                        subtitle: request.title,
                      );
                      if (mounted) setState(() {});
                    },
                    child: const Text('בטל', style: TextStyle(color: Colors.white)),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('אישור מחיקה'),
                        content: const Text('האם אתה בטוח שברצונך למחוק את הבקשה לצמיתות?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('ביטול'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('מחק'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      Navigator.of(context).pop();
                      print('🗑️ Deleting maintenance request: ${request.id}');
                      final success = await FirebaseMaintenanceService.deleteMaintenanceRequest(
                          request.buildingId, request.id);
                      if (success) {
                        await FirebaseActivityService.logActivity(
                          buildingId: request.buildingId,
                          type: 'maintenance_deleted',
                          title: 'בקשה נמחקה',
                          subtitle: request.title,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('הבקשה נמחקה בהצלחה'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() {});
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('שגיאה במחיקת הבקשה'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('מחק', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
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
          print('🔍 Dialog onSubmit: Request title = ${request.title}');
          print('🔍 Dialog onSubmit: Request buildingId = ${request.buildingId}');

          // Persist to Firestore
          final buildingId = request.buildingId;
          if (buildingId.isEmpty) {
            print('❌ Error: Building ID is empty, cannot save request');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('שגיאה: לא ניתן לשמור בקשה ללא זיהוי בניין'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          print('🔍 Dialog onSubmit: Saving to Firestore for building: $buildingId');
          final savedId = await FirebaseMaintenanceService.addMaintenanceRequest(
              buildingId, request);
          print('🔍 Dialog onSubmit: Firestore save result: $savedId');

          if (!mounted) return;

          if (savedId != null) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('בקשת תחזוקה נשמרה בהצלחה (ID: $savedId)'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            // Ask if user wants to assign a vendor immediately
            final shouldAssign = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('הקצאת ספק'),
                content: const Text('האם ברצונך להקצות ספק לבקשה זו עכשיו?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('לא כרגע'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('כן, הקצה ספק'),
                  ),
                ],
              ),
            );

            if (shouldAssign == true && mounted) {
              // Show vendor selection
              final vendor = await _pickVendor(buildingId);
              if (vendor != null && mounted) {
                await FirebaseMaintenanceService.assignToVendor(
                  buildingId,
                  savedId,
                  vendor['id']!,
                  vendor['name']!,
                );
                await FirebaseActivityService.logActivity(
                  buildingId: buildingId,
                  type: 'maintenance_assigned',
                  title: 'הוקצה לספק',
                  subtitle: vendor['name']!,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('הבקשה הוקצתה לספק: ${vendor['name']}'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              }
            }
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('שגיאה בשמירת בקשת תחזוקה'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, String>?> _pickVendor(String buildingId) async {
    try {
      print('🔍 Loading vendors for building: $buildingId');
      // Load vendors from flat vendors collection (filtered by buildingId)
      final vendorsQuery = await FirebaseFirestore.instance
          .collection('vendors')
          .where('buildingId', isEqualTo: buildingId)
          .get();

      print('🔍 Total vendors found: ${vendorsQuery.docs.length}');

      // Filter for active vendors, or include all if no status field
      final vendorsSnap = vendorsQuery.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] as String?;
        // Include if status is 'active' or if status field doesn't exist
        return status == null || status == 'active';
      }).toList();

      print('🔍 Available vendors after filtering: ${vendorsSnap.length}');

      final vendors = vendorsSnap
          .map((d) => {
                'id': d.id,
                'name': (d.data()['name'] ?? 'ספק') as String,
                'category': (d.data()['category'] ?? '') as String,
                'services': ((d.data()['services'] as List?)?.cast<String>() ?? const []).join(', '),
              })
          .toList();

      // Sort in memory instead of in query to avoid index requirement
      vendors.sort((a, b) {
        // Sort by name for now
        return (a['name'] ?? '').compareTo(b['name'] ?? '');
      });

      return await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
        title: const Text('בחר ספק'),
        content: SizedBox(
          width: 420,
          height: vendors.isEmpty ? 200 : 360,
          child: vendors.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business_center, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'אין ספקים זמינים',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'נא להוסיף ספקים דרך ניהול הספקים',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ResourceManagementPage(buildingId: buildingId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('נהל ספקים'),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: vendors.length,
                  itemBuilder: (context, index) {
                    final v = vendors[index];
                    final category = v['category'] ?? '';
                    final services = v['services'] ?? '';
                    final subtitle = category.isNotEmpty
                        ? (services.isNotEmpty ? '$category • $services' : category)
                        : services;
                    return ListTile(
                      leading: const Icon(Icons.business),
                      title: Text(v['name'] ?? 'ספק'),
                      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                      onTap: () => Navigator.of(context).pop({'id': v['id']!, 'name': v['name']!}),
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
    } catch (e) {
      print('❌ Error loading vendors: $e');
      return null;
    }
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
  State<_AddMaintenanceRequestDialog> createState() =>
      _AddMaintenanceRequestDialogState();
}

class _AddMaintenanceRequestDialogState
    extends State<_AddMaintenanceRequestDialog> {
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'נדרשת כותרת' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'תיאור *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'נדרש תיאור' : null,
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
                        items: MaintenanceCategory.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(_categoryLabel(c)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _category = v ?? MaintenanceCategory.general),
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
                        items: MaintenancePriority.values
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(_priorityLabel(p)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _priority = v ?? MaintenancePriority.normal),
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

    // Ensure building ID is set - use same logic as loading
    final buildingId = BuildingContextService.buildingId ??
        BuildingContextService.currentBuilding?.buildingId ??
        'demo_building_1';

    print('🔍 Dialog: Creating request for building: $buildingId');
    print('🔍 Dialog: BuildingContext.buildingId = ${BuildingContextService.buildingId}');
    print('🔍 Dialog: BuildingContext.currentBuilding?.buildingId = ${BuildingContextService.currentBuilding?.buildingId}');

    final request = MaintenanceRequest(
      id: now.millisecondsSinceEpoch.toString(),
      buildingId: buildingId,
      residentId: 'committee',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      priority: _priority,
      status: MaintenanceStatus.pending,
      reportedAt: now,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
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

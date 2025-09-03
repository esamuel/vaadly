import 'package:flutter/material.dart';
import '../../core/models/maintenance_request.dart';

class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  int _selectedFilterIndex = 0;
  List<MaintenanceRequest> _requests = [];
  bool _loading = false;

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
                : _filteredRequests.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('אין בקשות תחזוקה',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
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
          if (request.status != MaintenanceStatus.completed)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateRequestStatus(request, MaintenanceStatus.completed);
              },
              child: const Text('סמן כהושלם'),
            ),
        ],
      ),
    );
  }

  void _showAddRequestDialog() {
    // TODO: Implement add request dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('הוספת בקשה חדשה - תכונה זו תהיה זמינה בקרוב')),
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

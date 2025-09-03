import '../models/maintenance_request.dart';

class MaintenanceService {
  // In-memory storage for now (will be replaced with Firebase later)
  static final List<MaintenanceRequest> _requests = [];
  static int _nextRequestId = 1;

  // CRUD operations
  static List<MaintenanceRequest> getAllRequests() {
    return List.from(_requests);
  }

  static List<MaintenanceRequest> getRequestsByBuilding(String buildingId) {
    return _requests
        .where((request) => request.buildingId == buildingId)
        .toList();
  }

  static List<MaintenanceRequest> getRequestsByUnit(String unitId) {
    return _requests.where((request) => request.unitId == unitId).toList();
  }

  static List<MaintenanceRequest> getRequestsByResident(String residentId) {
    return _requests
        .where((request) => request.residentId == residentId)
        .toList();
  }

  static MaintenanceRequest? getRequestById(String id) {
    try {
      return _requests.firstWhere((request) => request.id == id);
    } catch (e) {
      return null;
    }
  }

  static MaintenanceRequest addRequest(MaintenanceRequest request) {
    final newRequest = request.copyWith(
      id: _nextRequestId.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _requests.add(newRequest);
    _nextRequestId++;

    return newRequest;
  }

  static MaintenanceRequest? updateRequest(MaintenanceRequest request) {
    final index = _requests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      final updatedRequest = request.copyWith(
        updatedAt: DateTime.now(),
      );
      _requests[index] = updatedRequest;
      return updatedRequest;
    }
    return null;
  }

  static bool deleteRequest(String id) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _requests.removeAt(index);
      return true;
    }
    return false;
  }

  // Status updates
  static bool assignToVendor(
      String requestId, String vendorId, String vendorName) {
    final request = getRequestById(requestId);
    if (request != null) {
      final updatedRequest = request.copyWith(
        status: MaintenanceStatus.assigned,
        assignedVendorId: vendorId,
        assignedVendorName: vendorName,
        assignedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      updateRequest(updatedRequest);
      return true;
    }
    return false;
  }

  static List<String> getSuggestedVendors(MaintenanceCategory category) {
    // TODO: Implement AI-powered vendor suggestion based on:
    // 1. Category match
    // 2. Rating and success rate
    // 3. Location proximity
    // 4. Availability
    // 5. Previous performance with similar issues

    // For now, return sample vendor IDs based on category
    switch (category) {
      case MaintenanceCategory.plumbing:
        return ['3']; // אינסטלטור משה
      case MaintenanceCategory.electrical:
        return ['1']; // חברת חשמל כהן
      case MaintenanceCategory.elevator:
        return ['2']; // חברת מעליות גולדברג
      case MaintenanceCategory.gardening:
        return ['4']; // גינון ירוק
      case MaintenanceCategory.hvac:
        return ['5']; // מיזוג אוויר קל
      default:
        return ['1', '3', '4']; // General vendors
    }
  }

  static bool startWork(String requestId) {
    final request = getRequestById(requestId);
    if (request != null) {
      final updatedRequest = request.copyWith(
        status: MaintenanceStatus.inProgress,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      updateRequest(updatedRequest);
      return true;
    }
    return false;
  }

  static bool completeWork(String requestId, String actualCost) {
    final request = getRequestById(requestId);
    if (request != null) {
      final updatedRequest = request.copyWith(
        status: MaintenanceStatus.completed,
        completedAt: DateTime.now(),
        actualCost: actualCost,
        updatedAt: DateTime.now(),
      );
      updateRequest(updatedRequest);
      return true;
    }
    return false;
  }

  static bool cancelRequest(String requestId, String reason) {
    final request = getRequestById(requestId);
    if (request != null) {
      final updatedRequest = request.copyWith(
        status: MaintenanceStatus.cancelled,
        cancelledAt: DateTime.now(),
        cancellationReason: reason,
        updatedAt: DateTime.now(),
      );
      updateRequest(updatedRequest);
      return true;
    }
    return false;
  }

  static bool rejectRequest(String requestId, String reason) {
    final request = getRequestById(requestId);
    if (request != null) {
      final updatedRequest = request.copyWith(
        status: MaintenanceStatus.rejected,
        rejectionReason: reason,
        updatedAt: DateTime.now(),
      );
      updateRequest(updatedRequest);
      return true;
    }
    return false;
  }

  static bool putOnHold(String requestId) {
    final request = getRequestById(requestId);
    if (request != null) {
      final updatedRequest = request.copyWith(
        status: MaintenanceStatus.onHold,
        updatedAt: DateTime.now(),
      );
      updateRequest(updatedRequest);
      return true;
    }
    return false;
  }

  // Search and filtering
  static List<MaintenanceRequest> searchRequests(String query) {
    if (query.isEmpty) return getAllRequests();

    final lowercaseQuery = query.toLowerCase();
    return _requests.where((request) {
      return request.title.toLowerCase().contains(lowercaseQuery) ||
          request.description.toLowerCase().contains(lowercaseQuery) ||
          (request.location?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  static List<MaintenanceRequest> filterRequests({
    String? buildingId,
    String? unitId,
    String? residentId,
    MaintenanceCategory? category,
    MaintenancePriority? priority,
    MaintenanceStatus? status,
    bool? isUrgent,
    bool? isOverdue,
  }) {
    return _requests.where((request) {
      if (buildingId != null && request.buildingId != buildingId) return false;
      if (unitId != null && request.unitId != unitId) return false;
      if (residentId != null && request.residentId != residentId) return false;
      if (category != null && request.category != category) return false;
      if (priority != null && request.priority != priority) return false;
      if (status != null && request.status != status) return false;
      if (isUrgent != null && request.isUrgent != isUrgent) return false;
      if (isOverdue != null && request.isOverdue != isOverdue) return false;
      return true;
    }).toList();
  }

  // Statistics
  static Map<String, dynamic> getBuildingStatistics(String buildingId) {
    final buildingRequests = getRequestsByBuilding(buildingId);

    final totalRequests = buildingRequests.length;
    final pendingRequests = buildingRequests
        .where((r) => r.status == MaintenanceStatus.pending)
        .length;
    final inProgressRequests = buildingRequests
        .where((r) => r.status == MaintenanceStatus.inProgress)
        .length;
    final completedRequests = buildingRequests
        .where((r) => r.status == MaintenanceStatus.completed)
        .length;
    final urgentRequests = buildingRequests
        .where((r) => r.priority == MaintenancePriority.urgent)
        .length;
    final overdueRequests = buildingRequests.where((r) => r.isOverdue).length;

    // Category breakdown
    final categoryBreakdown = <String, int>{};
    for (final request in buildingRequests) {
      final category = request.categoryDisplay;
      categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
    }

    // Priority breakdown
    final priorityBreakdown = <String, int>{};
    for (final request in buildingRequests) {
      final priority = request.priorityDisplay;
      priorityBreakdown[priority] = (priorityBreakdown[priority] ?? 0) + 1;
    }

    // Average response time (for completed requests)
    final completedRequestsList = buildingRequests
        .where((r) => r.status == MaintenanceStatus.completed)
        .toList();
    double averageResponseTime = 0;
    if (completedRequestsList.isNotEmpty) {
      final totalTime = completedRequestsList.fold<Duration>(
        Duration.zero,
        (total, request) =>
            total + request.completedAt!.difference(request.reportedAt),
      );
      averageResponseTime = totalTime.inHours / completedRequestsList.length;
    }

    return {
      'totalRequests': totalRequests,
      'pendingRequests': pendingRequests,
      'inProgressRequests': inProgressRequests,
      'completedRequests': completedRequests,
      'urgentRequests': urgentRequests,
      'overdueRequests': overdueRequests,
      'categoryBreakdown': categoryBreakdown,
      'priorityBreakdown': priorityBreakdown,
      'averageResponseTime': averageResponseTime,
      'completionRate': totalRequests > 0
          ? (completedRequests / totalRequests * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  static Map<String, dynamic> getOverallStatistics() {
    final totalRequests = _requests.length;
    final pendingRequests =
        _requests.where((r) => r.status == MaintenanceStatus.pending).length;
    final inProgressRequests =
        _requests.where((r) => r.status == MaintenanceStatus.inProgress).length;
    final completedRequests =
        _requests.where((r) => r.status == MaintenanceStatus.completed).length;
    final urgentRequests =
        _requests.where((r) => r.priority == MaintenancePriority.urgent).length;
    final overdueRequests = _requests.where((r) => r.isOverdue).length;

    // Status breakdown
    final statusBreakdown = <String, int>{};
    for (final request in _requests) {
      final status = request.statusDisplay;
      statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;
    }

    // Category breakdown
    final categoryBreakdown = <String, int>{};
    for (final request in _requests) {
      final category = request.categoryDisplay;
      categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
    }

    return {
      'totalRequests': totalRequests,
      'pendingRequests': pendingRequests,
      'inProgressRequests': inProgressRequests,
      'completedRequests': completedRequests,
      'urgentRequests': urgentRequests,
      'overdueRequests': overdueRequests,
      'statusBreakdown': statusBreakdown,
      'categoryBreakdown': categoryBreakdown,
      'completionRate': totalRequests > 0
          ? (completedRequests / totalRequests * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  // Sample data initialization
  static void initializeSampleData() {
    if (_requests.isNotEmpty) return; // Already initialized

    final sampleRequests = [
      MaintenanceRequest(
        id: '1',
        buildingId: '1', // בניין וודלי
        unitId: '1', // דירה 1
        residentId: '1', // יוסי כהן
        title: 'גינה לא מטופלת',
        description:
            'הגינה סביב הבניין לא מטופלת כראוי, יש עשבים גבוהים ופסולת',
        category: MaintenanceCategory.gardening,
        priority: MaintenancePriority.normal,
        status: MaintenanceStatus.pending,
        reportedAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MaintenanceRequest(
        id: '2',
        buildingId: '1',
        unitId: null, // Building-wide issue
        residentId: '2', // שרה לוי
        title: 'תאורה לא עובדת',
        description: 'התאורה בכניסה לבניין לא פועלת, זה מסוכן בלילה',
        category: MaintenanceCategory.electrical,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.assigned,
        assignedVendorId: 'vendor1',
        assignedVendorName: 'חברת חשמל כהן',
        reportedAt: DateTime.now().subtract(const Duration(hours: 6)),
        assignedAt: DateTime.now().subtract(const Duration(hours: 4)),
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      MaintenanceRequest(
        id: '3',
        buildingId: '1',
        unitId: '3', // דירה 3
        residentId: '3', // דוד רוזן
        title: 'מעלית תקולה',
        description: 'המעלית תקועה בקומה 3, לא עולה ולא יורדת',
        category: MaintenanceCategory.elevator,
        priority: MaintenancePriority.urgent,
        status: MaintenanceStatus.inProgress,
        assignedVendorId: 'vendor2',
        assignedVendorName: 'חברת מעליות גולדברג',
        reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
        assignedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      MaintenanceRequest(
        id: '4',
        buildingId: '1',
        unitId: '5', // דירה 5
        residentId: '5', // אברהם גולדברג
        title: 'דליפת מים',
        description: 'יש דליפת מים מהתקרה בחדר האמבטיה',
        category: MaintenanceCategory.plumbing,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.completed,
        assignedVendorId: 'vendor3',
        assignedVendorName: 'אינסטלטור משה',
        reportedAt: DateTime.now().subtract(const Duration(days: 3)),
        assignedAt: DateTime.now().subtract(const Duration(days: 2)),
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        actualCost: '₪800',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MaintenanceRequest(
        id: '5',
        buildingId: '1',
        unitId: null, // Building-wide issue
        residentId: '4', // רותי כהן
        title: 'ניקיון כניסה',
        description: 'הכניסה לבניין צריכה ניקיון יסודי',
        category: MaintenanceCategory.cleaning,
        priority: MaintenancePriority.low,
        status: MaintenanceStatus.pending,
        reportedAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (final request in sampleRequests) {
      _requests.add(request);
    }
    _nextRequestId = sampleRequests.length + 1;
  }

  // Utility methods
  static List<MaintenanceRequest> getUrgentRequests() {
    return _requests
        .where((r) => r.priority == MaintenancePriority.urgent)
        .toList();
  }

  static List<MaintenanceRequest> getOverdueRequests() {
    return _requests.where((r) => r.isOverdue).toList();
  }

  static List<MaintenanceRequest> getRequestsByStatus(
      MaintenanceStatus status) {
    return _requests.where((r) => r.status == status).toList();
  }

  static List<MaintenanceRequest> getRequestsByCategory(
      MaintenanceCategory category) {
    return _requests.where((r) => r.category == category).toList();
  }

  static List<MaintenanceRequest> getRequestsByPriority(
      MaintenancePriority priority) {
    return _requests.where((r) => r.priority == priority).toList();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/maintenance_request.dart';

class FirebaseMaintenanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream maintenance requests for a building
  static Stream<List<MaintenanceRequest>> streamMaintenanceRequests(String buildingId) {
    return _firestore
        .collection('buildings')
        .doc(buildingId)
        .collection('maintenance_requests')
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MaintenanceRequest.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get all maintenance requests for a building
  static Future<List<MaintenanceRequest>> getMaintenanceRequests(String buildingId) async {
    try {
      final snapshot = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('maintenance_requests')
          .orderBy('reportedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MaintenanceRequest.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('❌ Error getting maintenance requests: $e');
      return [];
    }
  }

  // Add a maintenance request
  static Future<String?> addMaintenanceRequest(String buildingId, MaintenanceRequest request) async {
    try {
      final docRef = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('maintenance_requests')
          .add(request.toMap());
      
      print('✅ Maintenance request added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding maintenance request: $e');
      return null;
    }
  }

  // Update a maintenance request
  static Future<bool> updateMaintenanceRequest(String buildingId, String requestId, MaintenanceRequest request) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('maintenance_requests')
          .doc(requestId)
          .update(request.toMap());
      
      print('✅ Maintenance request updated');
      return true;
    } catch (e) {
      print('❌ Error updating maintenance request: $e');
      return false;
    }
  }

  // Delete a maintenance request
  static Future<bool> deleteMaintenanceRequest(String buildingId, String requestId) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('maintenance_requests')
          .doc(requestId)
          .delete();
      
      print('✅ Maintenance request deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting maintenance request: $e');
      return false;
    }
  }

  // Status update methods
  static Future<bool> assignToVendor(String buildingId, String requestId, String vendorId, String vendorName) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('maintenance_requests')
          .doc(requestId)
          .update({
        'status': MaintenanceStatus.assigned.toString().split('.').last,
        'assignedVendorId': vendorId,
        'assignedVendorName': vendorName,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Request assigned to vendor');
      return true;
    } catch (e) {
      print('❌ Error assigning to vendor: $e');
      return false;
    }
  }

  static Future<bool> startWork(String buildingId, String requestId) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('maintenance_requests')
          .doc(requestId)
          .update({
        'status': MaintenanceStatus.inProgress.toString().split('.').last,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Work started');
      return true;
    } catch (e) {
      print('❌ Error starting work: $e');
      return false;
    }
  }

  static Future<bool> completeWork(String buildingId, String requestId, String actualCost) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('maintenance_requests')
          .doc(requestId)
          .update({
        'status': MaintenanceStatus.completed.toString().split('.').last,
        'completedAt': FieldValue.serverTimestamp(),
        'actualCost': actualCost,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Work completed');
      return true;
    } catch (e) {
      print('❌ Error completing work: $e');
      return false;
    }
  }

  static Future<bool> cancelRequest(String buildingId, String requestId, String reason) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('maintenance_requests')
          .doc(requestId)
          .update({
        'status': MaintenanceStatus.cancelled.toString().split('.').last,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Request cancelled');
      return true;
    } catch (e) {
      print('❌ Error cancelling request: $e');
      return false;
    }
  }

  // Get maintenance statistics for a building
  static Future<Map<String, dynamic>> getMaintenanceStatistics(String buildingId) async {
    try {
      final requests = await getMaintenanceRequests(buildingId);
      
      final totalRequests = requests.length;
      final pendingRequests = requests.where((r) => r.status == MaintenanceStatus.pending).length;
      final inProgressRequests = requests.where((r) => r.status == MaintenanceStatus.inProgress).length;
      final completedRequests = requests.where((r) => r.status == MaintenanceStatus.completed).length;
      final urgentRequests = requests.where((r) => r.priority == MaintenancePriority.urgent).length;
      final overdueRequests = requests.where((r) => r.isOverdue).length;
      
      // Category breakdown
      final categoryBreakdown = <String, int>{};
      for (final request in requests) {
        final category = request.categoryDisplay;
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }
      
      // Priority breakdown
      final priorityBreakdown = <String, int>{};
      for (final request in requests) {
        final priority = request.priorityDisplay;
        priorityBreakdown[priority] = (priorityBreakdown[priority] ?? 0) + 1;
      }
      
      return {
        'total': totalRequests,
        'pending': pendingRequests,
        'inProgress': inProgressRequests,
        'completed': completedRequests,
        'urgent': urgentRequests,
        'overdue': overdueRequests,
        'categoryBreakdown': categoryBreakdown,
        'priorityBreakdown': priorityBreakdown,
        'completionRate': totalRequests > 0 ? (completedRequests / totalRequests * 100).toStringAsFixed(1) : '0.0',
      };
    } catch (e) {
      print('❌ Error getting maintenance statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'inProgress': 0,
        'completed': 0,
        'urgent': 0,
        'overdue': 0,
        'categoryBreakdown': <String, int>{},
        'priorityBreakdown': <String, int>{},
        'completionRate': '0.0',
      };
    }
  }

  // Initialize sample maintenance requests for a building
  static Future<void> initializeSampleMaintenanceRequests(String buildingId) async {
    try {
      // Check if requests already exist
      final existingRequests = await getMaintenanceRequests(buildingId);
      if (existingRequests.isNotEmpty) {
        print('✅ Sample maintenance requests already exist for building $buildingId');
        return;
      }

      final sampleRequests = _generateSampleMaintenanceRequests(buildingId);
      
      for (final request in sampleRequests) {
        await addMaintenanceRequest(buildingId, request);
      }
      
      print('✅ Sample maintenance requests initialized for building $buildingId');
    } catch (e) {
      print('❌ Error initializing sample maintenance requests: $e');
    }
  }

  // Generate sample maintenance request data
  static List<MaintenanceRequest> _generateSampleMaintenanceRequests(String buildingId) {
    final now = DateTime.now();
    
    return [
      // Urgent elevator issue
      MaintenanceRequest(
        id: '',
        buildingId: buildingId,
        unitId: null, // Building-wide issue
        residentId: 'resident_1',
        title: 'מעלית תקועה בקומה 3',
        description: 'המעלית תקועה בקומה השלישית ולא מגיבה ללחיצות. דחוף!',
        category: MaintenanceCategory.elevator,
        priority: MaintenancePriority.urgent,
        status: MaintenanceStatus.assigned,
        assignedVendorId: 'vendor_elevator',
        assignedVendorName: 'חברת מעליות גולדברג',
        reportedAt: now.subtract(const Duration(hours: 2)),
        assignedAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        location: 'כניסה ראשית - מעלית',
        estimatedCost: '₪1,500',
        isUrgent: true,
        requiresImmediateAttention: true,
      ),

      // High priority electrical issue
      MaintenanceRequest(
        id: '',
        buildingId: buildingId,
        unitId: null,
        residentId: 'resident_2',
        title: 'תאורה כבויה בחניון',
        description: 'כל התאורה בחניון התת-קרקעי כבויה. מסוכן לתנועה.',
        category: MaintenanceCategory.electrical,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.inProgress,
        assignedVendorId: 'vendor_electric',
        assignedVendorName: 'חברת חשמל כהן',
        reportedAt: now.subtract(const Duration(hours: 8)),
        assignedAt: now.subtract(const Duration(hours: 6)),
        startedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        location: 'חניון תת-קרקעי',
        estimatedCost: '₪800',
        photoUrls: ['https://example.com/garage_lights.jpg'],
      ),

      // Normal priority plumbing issue
      MaintenanceRequest(
        id: '',
        buildingId: buildingId,
        unitId: 'unit_5',
        residentId: 'resident_3',
        title: 'דליפת מים קטנה',
        description: 'דליפה קטנה מהברז במטבח. לא דחוף אבל צריך תיקון.',
        category: MaintenanceCategory.plumbing,
        priority: MaintenancePriority.normal,
        status: MaintenanceStatus.pending,
        reportedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        location: 'דירה 5 - מטבח',
        estimatedCost: '₪300',
        notes: 'הדליפה קטנה, אבל מפריעה',
      ),

      // Completed gardening work
      MaintenanceRequest(
        id: '',
        buildingId: buildingId,
        unitId: null,
        residentId: 'resident_4',
        title: 'גיזום עצים בגינה',
        description: 'העצים בגינה צריכים גיזום, חלקם חוסמים חלונות.',
        category: MaintenanceCategory.gardening,
        priority: MaintenancePriority.normal,
        status: MaintenanceStatus.completed,
        assignedVendorId: 'vendor_garden',
        assignedVendorName: 'גינון ירוק',
        reportedAt: now.subtract(const Duration(days: 5)),
        assignedAt: now.subtract(const Duration(days: 4)),
        startedAt: now.subtract(const Duration(days: 3)),
        completedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 2)),
        location: 'גינה מרכזית',
        estimatedCost: '₪1,200',
        actualCost: '₪1,000',
        notes: 'העבודה הושלמה בהצלחה, הגינה נראית מעולה',
      ),

      // Low priority cleaning request
      MaintenanceRequest(
        id: '',
        buildingId: buildingId,
        unitId: null,
        residentId: 'resident_5',
        title: 'ניקיון עמוק למדרגות',
        description: 'המדרגות זקוקות לניקיון עמוק וחידוש הציפוי.',
        category: MaintenanceCategory.cleaning,
        priority: MaintenancePriority.low,
        status: MaintenanceStatus.pending,
        reportedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        location: 'בית מדרגות ראשי',
        estimatedCost: '₪600',
        notes: 'לא דחוף, אבל יפה הבניין',
      ),

      // HVAC issue
      MaintenanceRequest(
        id: '',
        buildingId: buildingId,
        unitId: 'unit_8',
        residentId: 'resident_6',
        title: 'מזגן לא מקרר',
        description: 'המזגן בסלון לא מקרר כראוי, צריך בדיקה.',
        category: MaintenanceCategory.hvac,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.assigned,
        assignedVendorId: 'vendor_hvac',
        assignedVendorName: 'מיזוג אוויר קל',
        reportedAt: now.subtract(const Duration(hours: 12)),
        assignedAt: now.subtract(const Duration(hours: 8)),
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 8)),
        location: 'דירה 8 - סלון',
        estimatedCost: '₪500',
      ),
    ];
  }

  // Helper method to parse DateTime from Firestore data
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value.runtimeType.toString().contains('Timestamp')) {
      // Handle Firestore Timestamp
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }
}
import 'package:flutter/material.dart';

enum MaintenancePriority {
  urgent,    // דחוף - Immediate attention required
  high,      // גבוה - Within 24 hours
  normal,    // רגיל - Within 72 hours
  low,       // נמוך - Within 1 week
}

enum MaintenanceStatus {
  pending,       // ממתין - Just submitted
  assigned,      // מוקצה - Assigned to vendor
  inProgress,    // בתהליך - Work in progress
  onHold,        // מושהה - Temporarily stopped
  completed,     // הושלם - Work completed
  cancelled,     // בוטל - Request cancelled
  rejected,      // נדחה - Request rejected
}

enum MaintenanceCategory {
  plumbing,      // אינסטלציה
  electrical,    // חשמל
  hvac,         // מיזוג אוויר
  cleaning,     // ניקיון
  gardening,    // גינון
  elevator,     // מעליות
  security,     // אבטחה
  structural,   // מבני
  sanitation,   // תברואה
  general,      // כללי
}

class MaintenanceRequest {
  final String id;
  final String buildingId;
  final String? unitId; // Optional - if issue is unit-specific
  final String residentId; // Who reported the issue
  final String title;
  final String description;
  final MaintenanceCategory category;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final String? assignedVendorId;
  final String? assignedVendorName;
  final DateTime reportedAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? rejectionReason;
  final List<String> photoUrls;
  final List<String> documentUrls;
  final String? location; // Specific location in building
  final String? estimatedCost;
  final String? actualCost;
  final String? notes;
  final bool isUrgent;
  final bool requiresImmediateAttention;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  MaintenanceRequest({
    required this.id,
    required this.buildingId,
    this.unitId,
    required this.residentId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedVendorId,
    this.assignedVendorName,
    required this.reportedAt,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.rejectionReason,
    this.photoUrls = const [],
    this.documentUrls = const [],
    this.location,
    this.estimatedCost,
    this.actualCost,
    this.notes,
    this.isUrgent = false,
    this.requiresImmediateAttention = false,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Getters for display
  String get priorityDisplay {
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

  String get statusDisplay {
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

  String get categoryDisplay {
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

  Color get priorityColor {
    switch (priority) {
      case MaintenancePriority.urgent:
        return Colors.red;
      case MaintenancePriority.high:
        return Colors.orange;
      case MaintenancePriority.normal:
        return Colors.blue;
      case MaintenancePriority.low:
        return Colors.green;
    }
  }

  Color get statusColor {
    switch (status) {
      case MaintenanceStatus.pending:
        return Colors.grey;
      case MaintenanceStatus.assigned:
        return Colors.blue;
      case MaintenanceStatus.inProgress:
        return Colors.orange;
      case MaintenanceStatus.onHold:
        return Colors.yellow;
      case MaintenanceStatus.completed:
        return Colors.green;
      case MaintenanceStatus.cancelled:
        return Colors.red;
      case MaintenanceStatus.rejected:
        return Colors.red;
    }
  }

  // Duration calculations
  Duration get timeSinceReported => DateTime.now().difference(reportedAt);
  Duration get timeSinceAssigned => assignedAt != null ? DateTime.now().difference(assignedAt!) : Duration.zero;
  Duration get timeSinceStarted => startedAt != null ? DateTime.now().difference(startedAt!) : Duration.zero;

  String get timeSinceReportedDisplay {
    final duration = timeSinceReported;
    if (duration.inDays > 0) {
      return '${duration.inDays} ימים';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} שעות';
    } else {
      return '${duration.inMinutes} דקות';
    }
  }

  // Check if request is overdue
  bool get isOverdue {
    switch (priority) {
      case MaintenancePriority.urgent:
        return timeSinceReported.inHours > 2;
      case MaintenancePriority.high:
        return timeSinceReported.inHours > 24;
      case MaintenancePriority.normal:
        return timeSinceReported.inDays > 3;
      case MaintenancePriority.low:
        return timeSinceReported.inDays > 7;
    }
  }

  // Factory methods
  factory MaintenanceRequest.fromMap(Map<String, dynamic> map) {
    return MaintenanceRequest(
      id: map['id'] ?? '',
      buildingId: map['buildingId'] ?? '',
      unitId: map['unitId'],
      residentId: map['residentId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: MaintenanceCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => MaintenanceCategory.general,
      ),
      priority: MaintenancePriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => MaintenancePriority.normal,
      ),
      status: MaintenanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => MaintenanceStatus.pending,
      ),
      assignedVendorId: map['assignedVendorId'],
      assignedVendorName: map['assignedVendorName'],
      reportedAt: DateTime.parse(map['reportedAt']),
      assignedAt: map['assignedAt'] != null ? DateTime.parse(map['assignedAt']) : null,
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      cancelledAt: map['cancelledAt'] != null ? DateTime.parse(map['cancelledAt']) : null,
      cancellationReason: map['cancellationReason'],
      rejectionReason: map['rejectionReason'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
      location: map['location'],
      estimatedCost: map['estimatedCost'],
      actualCost: map['actualCost'],
      notes: map['notes'],
      isUrgent: map['isUrgent'] ?? false,
      requiresImmediateAttention: map['requiresImmediateAttention'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buildingId': buildingId,
      'unitId': unitId,
      'residentId': residentId,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'assignedVendorId': assignedVendorId,
      'assignedVendorName': assignedVendorName,
      'reportedAt': reportedAt.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'rejectionReason': rejectionReason,
      'photoUrls': photoUrls,
      'documentUrls': documentUrls,
      'location': location,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'notes': notes,
      'isUrgent': isUrgent,
      'requiresImmediateAttention': requiresImmediateAttention,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Copy with method for updates
  MaintenanceRequest copyWith({
    String? id,
    String? buildingId,
    String? unitId,
    String? residentId,
    String? title,
    String? description,
    MaintenanceCategory? category,
    MaintenancePriority? priority,
    MaintenanceStatus? status,
    String? assignedVendorId,
    String? assignedVendorName,
    DateTime? reportedAt,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? rejectionReason,
    List<String>? photoUrls,
    List<String>? documentUrls,
    String? location,
    String? estimatedCost,
    String? actualCost,
    String? notes,
    bool? isUrgent,
    bool? requiresImmediateAttention,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      unitId: unitId ?? this.unitId,
      residentId: residentId ?? this.residentId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedVendorId: assignedVendorId ?? this.assignedVendorId,
      assignedVendorName: assignedVendorName ?? this.assignedVendorName,
      reportedAt: reportedAt ?? this.reportedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      photoUrls: photoUrls ?? this.photoUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      location: location ?? this.location,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      notes: notes ?? this.notes,
      isUrgent: isUrgent ?? this.isUrgent,
      requiresImmediateAttention: requiresImmediateAttention ?? this.requiresImmediateAttention,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

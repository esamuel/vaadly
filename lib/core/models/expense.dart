import 'package:flutter/material.dart';

enum ExpenseCategory {
  maintenance, // תחזוקה
  utilities, // שירותים
  insurance, // ביטוח
  taxes, // מיסים
  management, // ניהול
  cleaning, // ניקיון
  gardening, // גינון
  security, // אבטחה
  legal, // משפטי
  marketing, // שיווק
  other, // אחר
}

enum ExpenseStatus {
  pending, // ממתין לאישור
  approved, // מאושר
  paid, // שולם
  rejected, // נדחה
  cancelled, // בוטל
}

enum ExpensePriority {
  low, // נמוך
  normal, // רגיל
  high, // גבוה
  urgent, // דחוף
}

class Expense {
  final String id;
  final String buildingId;
  final String? unitId; // Optional - if expense is for specific unit
  final String title;
  final String description;
  final ExpenseCategory category;
  final ExpenseStatus status;
  final ExpensePriority priority;
  final double amount;
  final double? approvedAmount;
  final String? vendorId;
  final String? vendorName;
  final String? invoiceNumber;
  final DateTime expenseDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? paymentReference;
  final String? notes;
  final List<String> receipts;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final bool isRecurring;
  final String? recurringSchedule; // Monthly, Quarterly, Yearly
  final DateTime? nextDueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.buildingId,
    this.unitId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.amount,
    this.approvedAmount,
    this.vendorId,
    this.vendorName,
    this.invoiceNumber,
    required this.expenseDate,
    required this.dueDate,
    this.paidDate,
    this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.receipts = const [],
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.isRecurring = false,
    this.recurringSchedule,
    this.nextDueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters for display and calculations
  String get categoryDisplay {
    switch (category) {
      case ExpenseCategory.maintenance:
        return 'תחזוקה';
      case ExpenseCategory.utilities:
        return 'שירותים';
      case ExpenseCategory.insurance:
        return 'ביטוח';
      case ExpenseCategory.taxes:
        return 'מיסים';
      case ExpenseCategory.management:
        return 'ניהול';
      case ExpenseCategory.cleaning:
        return 'ניקיון';
      case ExpenseCategory.gardening:
        return 'גינון';
      case ExpenseCategory.security:
        return 'אבטחה';
      case ExpenseCategory.legal:
        return 'משפטי';
      case ExpenseCategory.marketing:
        return 'שיווק';
      case ExpenseCategory.other:
        return 'אחר';
    }
  }

  Color get categoryColor {
    switch (category) {
      case ExpenseCategory.maintenance:
        return Colors.blue;
      case ExpenseCategory.utilities:
        return Colors.green;
      case ExpenseCategory.insurance:
        return Colors.orange;
      case ExpenseCategory.taxes:
        return Colors.red;
      case ExpenseCategory.management:
        return Colors.purple;
      case ExpenseCategory.cleaning:
        return Colors.teal;
      case ExpenseCategory.gardening:
        return Colors.lightGreen;
      case ExpenseCategory.security:
        return Colors.indigo;
      case ExpenseCategory.legal:
        return Colors.deepPurple;
      case ExpenseCategory.marketing:
        return Colors.pink;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  String get statusDisplay {
    switch (status) {
      case ExpenseStatus.pending:
        return 'ממתין לאישור';
      case ExpenseStatus.approved:
        return 'מאושר';
      case ExpenseStatus.paid:
        return 'שולם';
      case ExpenseStatus.rejected:
        return 'נדחה';
      case ExpenseStatus.cancelled:
        return 'בוטל';
    }
  }

  Color get statusColor {
    switch (status) {
      case ExpenseStatus.pending:
        return Colors.orange;
      case ExpenseStatus.approved:
        return Colors.blue;
      case ExpenseStatus.paid:
        return Colors.green;
      case ExpenseStatus.rejected:
        return Colors.red;
      case ExpenseStatus.cancelled:
        return Colors.grey;
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case ExpensePriority.low:
        return 'נמוך';
      case ExpensePriority.normal:
        return 'רגיל';
      case ExpensePriority.high:
        return 'גבוה';
      case ExpensePriority.urgent:
        return 'דחוף';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case ExpensePriority.low:
        return Colors.green;
      case ExpensePriority.normal:
        return Colors.blue;
      case ExpensePriority.high:
        return Colors.orange;
      case ExpensePriority.urgent:
        return Colors.red;
    }
  }

  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status != ExpenseStatus.paid;

  int get daysOverdue =>
      isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

  String get overdueDisplay => isOverdue ? '$daysOverdue ימים בפיגור' : '';

  bool get isPending => status == ExpenseStatus.pending;

  bool get isApproved => status == ExpenseStatus.approved;

  bool get isPaid => status == ExpenseStatus.paid;

  bool get isRejected => status == ExpenseStatus.rejected;

  double get outstandingAmount => isPaid ? 0.0 : (approvedAmount ?? amount);

  // Factory methods
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      buildingId: map['buildingId'] ?? '',
      unitId: map['unitId'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ExpenseStatus.pending,
      ),
      priority: ExpensePriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => ExpensePriority.normal,
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      approvedAmount: map['approvedAmount']?.toDouble(),
      vendorId: map['vendorId'],
      vendorName: map['vendorName'],
      invoiceNumber: map['invoiceNumber'],
      expenseDate: DateTime.parse(map['expenseDate']),
      dueDate: DateTime.parse(map['dueDate']),
      paidDate:
          map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
      paymentMethod: map['paymentMethod'],
      paymentReference: map['paymentReference'],
      notes: map['notes'],
      receipts: List<String>.from(map['receipts'] ?? []),
      approvedBy: map['approvedBy'],
      approvedAt:
          map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      rejectionReason: map['rejectionReason'],
      isRecurring: map['isRecurring'] ?? false,
      recurringSchedule: map['recurringSchedule'],
      nextDueDate: map['nextDueDate'] != null
          ? DateTime.parse(map['nextDueDate'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buildingId': buildingId,
      'unitId': unitId,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'amount': amount,
      'approvedAmount': approvedAmount,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'invoiceNumber': invoiceNumber,
      'expenseDate': expenseDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'notes': notes,
      'receipts': receipts,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'isRecurring': isRecurring,
      'recurringSchedule': recurringSchedule,
      'nextDueDate': nextDueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  Expense copyWith({
    String? id,
    String? buildingId,
    String? unitId,
    String? title,
    String? description,
    ExpenseCategory? category,
    ExpenseStatus? status,
    ExpensePriority? priority,
    double? amount,
    double? approvedAmount,
    String? vendorId,
    String? vendorName,
    String? invoiceNumber,
    DateTime? expenseDate,
    DateTime? dueDate,
    DateTime? paidDate,
    String? paymentMethod,
    String? paymentReference,
    String? notes,
    List<String>? receipts,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    bool? isRecurring,
    String? recurringSchedule,
    DateTime? nextDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      amount: amount ?? this.amount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      expenseDate: expenseDate ?? this.expenseDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      receipts: receipts ?? this.receipts,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringSchedule: recurringSchedule ?? this.recurringSchedule,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

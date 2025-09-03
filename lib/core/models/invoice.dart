import 'package:flutter/material.dart';

enum InvoiceStatus {
  draft, // טיוטה
  sent, // נשלח
  viewed, // נצפה
  paid, // שולם
  overdue, // בפיגור
  cancelled, // בוטל
  disputed, // במחלוקת
}

enum InvoiceType {
  maintenance, // תחזוקה
  rent, // שכירות
  utilities, // שירותים
  insurance, // ביטוח
  taxes, // מיסים
  management, // ניהול
  other, // אחר
}

enum PaymentMethod {
  bankTransfer, // העברה בנקאית
  check, // צ'ק
  cash, // מזומן
  creditCard, // כרטיס אשראי
  digitalWallet, // ארנק דיגיטלי
}

class InvoiceItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final String? notes;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0.0,
    this.notes,
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'notes': notes,
    };
  }

  InvoiceItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    double? taxRate,
    String? notes,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
    );
  }
}

class Invoice {
  final String id;
  final String buildingId;
  final String? unitId; // Optional - if invoice is for specific unit
  final String? residentId; // Optional - if invoice is for specific resident
  final String invoiceNumber;
  final InvoiceType type;
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String? notes;
  final String? terms;
  final String? paymentInstructions;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paidAt;
  final PaymentMethod? paymentMethod;
  final String? paymentReference;
  final double? amountPaid;
  final String? lateFees;
  final bool isRecurring;
  final String? recurringSchedule; // Monthly, Quarterly, Yearly
  final DateTime? nextDueDate;

  Invoice({
    required this.id,
    required this.buildingId,
    this.unitId,
    this.residentId,
    required this.invoiceNumber,
    required this.type,
    required this.status,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.notes,
    this.terms,
    this.paymentInstructions,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentReference,
    this.amountPaid,
    this.lateFees,
    this.isRecurring = false,
    this.recurringSchedule,
    this.nextDueDate,
  });

  // Getters for display and calculations
  String get statusDisplay {
    switch (status) {
      case InvoiceStatus.draft:
        return 'טיוטה';
      case InvoiceStatus.sent:
        return 'נשלח';
      case InvoiceStatus.viewed:
        return 'נצפה';
      case InvoiceStatus.paid:
        return 'שולם';
      case InvoiceStatus.overdue:
        return 'בפיגור';
      case InvoiceStatus.cancelled:
        return 'בוטל';
      case InvoiceStatus.disputed:
        return 'במחלוקת';
    }
  }

  Color get statusColor {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.viewed:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.red;
      case InvoiceStatus.disputed:
        return Colors.purple;
    }
  }

  String get typeDisplay {
    switch (type) {
      case InvoiceType.maintenance:
        return 'תחזוקה';
      case InvoiceType.rent:
        return 'שכירות';
      case InvoiceType.utilities:
        return 'שירותים';
      case InvoiceType.insurance:
        return 'ביטוח';
      case InvoiceType.taxes:
        return 'מיסים';
      case InvoiceType.management:
        return 'ניהול';
      case InvoiceType.other:
        return 'אחר';
    }
  }

  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status != InvoiceStatus.paid;

  int get daysOverdue =>
      isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

  String get overdueDisplay => isOverdue ? '$daysOverdue ימים בפיגור' : '';

  bool get isPaid => status == InvoiceStatus.paid;

  bool get isPending =>
      status == InvoiceStatus.sent || status == InvoiceStatus.viewed;

  double get outstandingAmount => isPaid ? 0.0 : total;

  double get lateFeeAmount {
    if (!isOverdue || isPaid) return 0.0;
    // Calculate late fee (example: 5% per month)
    final monthsOverdue = daysOverdue / 30;
    return total * (monthsOverdue * 0.05);
  }

  // Factory methods
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      buildingId: map['buildingId'] ?? '',
      unitId: map['unitId'],
      residentId: map['residentId'],
      invoiceNumber: map['invoiceNumber'] ?? '',
      type: InvoiceType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => InvoiceType.other,
      ),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      issueDate: DateTime.parse(map['issueDate']),
      dueDate: DateTime.parse(map['dueDate']),
      items: (map['items'] as List<dynamic>? ?? []).map((item) {
        return InvoiceItem.fromMap(item);
      }).toList(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      notes: map['notes'],
      terms: map['terms'],
      paymentInstructions: map['paymentInstructions'],
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      paidAt: map['paidAt'],
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == map['paymentMethod'],
              orElse: () => PaymentMethod.bankTransfer,
            )
          : null,
      paymentReference: map['paymentReference'],
      amountPaid: map['amountPaid']?.toDouble(),
      lateFees: map['lateFees'],
      isRecurring: map['isRecurring'] ?? false,
      recurringSchedule: map['recurringSchedule'],
      nextDueDate: map['nextDueDate'] != null
          ? DateTime.parse(map['nextDueDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buildingId': buildingId,
      'unitId': unitId,
      'residentId': residentId,
      'invoiceNumber': invoiceNumber,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
      'notes': notes,
      'terms': terms,
      'paymentInstructions': paymentInstructions,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'paidAt': paidAt,
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'paymentReference': paymentReference,
      'amountPaid': amountPaid,
      'lateFees': lateFees,
      'isRecurring': isRecurring,
      'recurringSchedule': recurringSchedule,
      'nextDueDate': nextDueDate?.toIso8601String(),
    };
  }

  // Copy with method for updates
  Invoice copyWith({
    String? id,
    String? buildingId,
    String? unitId,
    String? residentId,
    String? invoiceNumber,
    InvoiceType? type,
    InvoiceStatus? status,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    double? subtotal,
    double? taxAmount,
    double? total,
    String? notes,
    String? terms,
    String? paymentInstructions,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paidAt,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    double? amountPaid,
    String? lateFees,
    bool? isRecurring,
    String? recurringSchedule,
    DateTime? nextDueDate,
  }) {
    return Invoice(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      unitId: unitId ?? this.unitId,
      residentId: residentId ?? this.residentId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      amountPaid: amountPaid ?? this.amountPaid,
      lateFees: lateFees ?? this.lateFees,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringSchedule: recurringSchedule ?? this.recurringSchedule,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }
}

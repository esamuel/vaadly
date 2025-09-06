import 'package:flutter/material.dart';

enum PaymentStatus {
  pending, // ממתין לתשלום
  processing, // בעיבוד
  completed, // הושלם
  failed, // נכשל
  cancelled, // בוטל
  refunded, // הוחזר
}

enum PaymentType {
  rent, // שכירות
  maintenance, // תחזוקה
  utilities, // שירותים
  penalty, // קנס
  deposit, // פיקדון
  other, // אחר
}

enum PaymentMethod {
  creditCard, // כרטיס אשראי
  bankTransfer, // העברה בנקאית
  cash, // מזומן
  check, // צ'ק
  digitalWallet, // ארנק דיגיטלי
}

class Payment {
  final String id;
  final String buildingId;
  final String? unitId;
  final String? residentId;
  final String? invoiceId;
  final String title;
  final String? description;
  final PaymentType type;
  final PaymentStatus status;
  final PaymentMethod paymentMethod;
  final double amount;
  final double? feeAmount;
  final double netAmount;
  final String currency;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? stripePaymentIntentId;
  final String? stripeChargeId;
  final String? paymentReference;
  final Map<String, dynamic> metadata;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.buildingId,
    this.unitId,
    this.residentId,
    this.invoiceId,
    required this.title,
    this.description,
    required this.type,
    required this.status,
    required this.paymentMethod,
    required this.amount,
    this.feeAmount,
    required this.netAmount,
    this.currency = 'ILS',
    required this.dueDate,
    this.paidDate,
    this.stripePaymentIntentId,
    this.stripeChargeId,
    this.paymentReference,
    this.metadata = const {},
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters
  String get statusDisplay {
    switch (status) {
      case PaymentStatus.pending:
        return 'ממתין לתשלום';
      case PaymentStatus.processing:
        return 'בעיבוד';
      case PaymentStatus.completed:
        return 'הושלם';
      case PaymentStatus.failed:
        return 'נכשל';
      case PaymentStatus.cancelled:
        return 'בוטל';
      case PaymentStatus.refunded:
        return 'הוחזר';
    }
  }

  String get typeDisplay {
    switch (type) {
      case PaymentType.rent:
        return 'שכירות';
      case PaymentType.maintenance:
        return 'תחזוקה';
      case PaymentType.utilities:
        return 'שירותים';
      case PaymentType.penalty:
        return 'קנס';
      case PaymentType.deposit:
        return 'פיקדון';
      case PaymentType.other:
        return 'אחר';
    }
  }

  String get methodDisplay {
    switch (paymentMethod) {
      case PaymentMethod.creditCard:
        return 'כרטיס אשראי';
      case PaymentMethod.bankTransfer:
        return 'העברה בנקאית';
      case PaymentMethod.cash:
        return 'מזומן';
      case PaymentMethod.check:
        return 'צ\'ק';
      case PaymentMethod.digitalWallet:
        return 'ארנק דיגיטלי';
    }
  }

  bool get isOverdue {
    return status == PaymentStatus.pending && DateTime.now().isAfter(dueDate);
  }

  Color get statusColor {
    switch (status) {
      case PaymentStatus.pending:
        return isOverdue ? Colors.red : Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  // Helper method to parse DateTime from Firestore data
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }

  // Factory constructor from Map
  factory Payment.fromMap(Map<String, dynamic> data, String id) {
    return Payment(
      id: id,
      buildingId: data['buildingId'] ?? '',
      unitId: data['unitId'],
      residentId: data['residentId'],
      invoiceId: data['invoiceId'],
      title: data['title'] ?? '',
      description: data['description'],
      type: PaymentType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => PaymentType.other,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == data['paymentMethod'],
        orElse: () => PaymentMethod.creditCard,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      feeAmount: data['feeAmount']?.toDouble(),
      netAmount: (data['netAmount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'ILS',
      dueDate: _parseDateTime(data['dueDate']),
      paidDate: data['paidDate'] != null ? _parseDateTime(data['paidDate']) : null,
      stripePaymentIntentId: data['stripePaymentIntentId'],
      stripeChargeId: data['stripeChargeId'],
      paymentReference: data['paymentReference'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      failureReason: data['failureReason'],
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'unitId': unitId,
      'residentId': residentId,
      'invoiceId': invoiceId,
      'title': title,
      'description': description,
      'type': type.toString(),
      'status': status.toString(),
      'paymentMethod': paymentMethod.toString(),
      'amount': amount,
      'feeAmount': feeAmount,
      'netAmount': netAmount,
      'currency': currency,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeChargeId': stripeChargeId,
      'paymentReference': paymentReference,
      'metadata': metadata,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  Payment copyWith({
    String? id,
    String? buildingId,
    String? unitId,
    String? residentId,
    String? invoiceId,
    String? title,
    String? description,
    PaymentType? type,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    double? amount,
    double? feeAmount,
    double? netAmount,
    String? currency,
    DateTime? dueDate,
    DateTime? paidDate,
    String? stripePaymentIntentId,
    String? stripeChargeId,
    String? paymentReference,
    Map<String, dynamic>? metadata,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      unitId: unitId ?? this.unitId,
      residentId: residentId ?? this.residentId,
      invoiceId: invoiceId ?? this.invoiceId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      feeAmount: feeAmount ?? this.feeAmount,
      netAmount: netAmount ?? this.netAmount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeChargeId: stripeChargeId ?? this.stripeChargeId,
      paymentReference: paymentReference ?? this.paymentReference,
      metadata: metadata ?? this.metadata,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Payment(id: $id, title: $title, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
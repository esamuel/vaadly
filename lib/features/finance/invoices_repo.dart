import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final String buildingId;
  final String type; // 'unit' | 'vendor'
  final String? unitId;
  final String? vendorId;
  final double total;
  final String currency;
  final String status; // 'pending' | 'paid' | 'overdue' | 'cancelled'
  final String description;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final String? notes;
  final List<String> attachments;
  final bool needsReview;

  Invoice({
    required this.id,
    required this.buildingId,
    required this.type,
    this.unitId,
    this.vendorId,
    required this.total,
    this.currency = 'ILS',
    required this.status,
    required this.description,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.notes,
    this.attachments = const [],
    this.needsReview = false,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      buildingId: data['buildingId'] ?? '',
      type: data['type'] ?? 'unit',
      unitId: data['unitId'],
      vendorId: data['vendorId'],
      total: (data['total'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'ILS',
      status: data['status'] ?? 'pending',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      attachments: List<String>.from(data['attachments'] ?? []),
      needsReview: data['needsReview'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'type': type,
      'unitId': unitId,
      'vendorId': vendorId,
      'total': total,
      'currency': currency,
      'status': status,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'notes': notes,
      'attachments': attachments,
      'needsReview': needsReview,
    };
  }

  Invoice copyWith({
    String? id,
    String? buildingId,
    String? type,
    String? unitId,
    String? vendorId,
    double? total,
    String? currency,
    String? status,
    String? description,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    String? notes,
    List<String>? attachments,
    bool? needsReview,
  }) {
    return Invoice(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      type: type ?? this.type,
      unitId: unitId ?? this.unitId,
      vendorId: vendorId ?? this.vendorId,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      needsReview: needsReview ?? this.needsReview,
    );
  }

  bool get isOverdue => status == 'pending' && DateTime.now().isAfter(dueDate);

  bool get isAutoApprovable =>
      total <= 2000 && currency == 'ILS'; // Auto-approve if ≤ ₪2,000
}

class Payment {
  final String id;
  final String buildingId;
  final String invoiceId;
  final double amount;
  final String currency;
  final String method; // 'credit_card' | 'bank_transfer' | 'cash' | 'check'
  final String status; // 'pending' | 'completed' | 'failed' | 'refunded'
  final String? transactionId;
  final String? notes;
  final DateTime paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.buildingId,
    required this.invoiceId,
    required this.amount,
    this.currency = 'ILS',
    required this.method,
    required this.status,
    this.transactionId,
    this.notes,
    required this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      buildingId: data['buildingId'] ?? '',
      invoiceId: data['invoiceId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'ILS',
      method: data['method'] ?? 'credit_card',
      status: data['status'] ?? 'pending',
      transactionId: data['transactionId'],
      notes: data['notes'],
      paidAt: (data['paidAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'invoiceId': invoiceId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'notes': notes,
      'paidAt': Timestamp.fromDate(paidAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class FinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all invoices for a building
  Future<List<Invoice>> getInvoices(String buildingId, {String? status}) async {
    try {
      Query query = _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .orderBy('createdAt', descending: true);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch invoices: $e');
    }
  }

  // Get invoices by type
  Future<List<Invoice>> getInvoicesByType(
      String buildingId, String type) async {
    try {
      final query = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch invoices by type: $e');
    }
  }

  // Get overdue invoices
  Future<List<Invoice>> getOverdueInvoices(String buildingId) async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .where('status', isEqualTo: 'pending')
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('dueDate')
          .get();

      return query.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch overdue invoices: $e');
    }
  }

  // Create new invoice
  Future<String> createInvoice(Invoice invoice) async {
    try {
      // Auto-approve if amount is ≤ ₪2,000
      if (invoice.isAutoApprovable) {
        invoice = invoice.copyWith(
          status: 'approved',
          needsReview: false,
        );
      } else {
        invoice = invoice.copyWith(
          needsReview: true,
        );
      }

      final docRef = await _firestore
          .collection('buildings')
          .doc(invoice.buildingId)
          .collection('invoices')
          .add(invoice.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  // Update invoice
  Future<void> updateInvoice(Invoice invoice) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(invoice.buildingId)
          .collection('invoices')
          .doc(invoice.id)
          .update(invoice.toMap());
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  // Mark invoice as paid
  Future<void> markInvoiceAsPaid(
      String buildingId, String invoiceId, Payment payment) async {
    try {
      final batch = _firestore.batch();

      // Add payment record
      final paymentRef = _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('payments')
          .doc();

      batch.set(paymentRef, payment.toMap());

      // Update invoice status
      final invoiceRef = _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .doc(invoiceId);

      batch.update(invoiceRef, {
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark invoice as paid: $e');
    }
  }

  // Get payments for an invoice
  Future<List<Payment>> getPayments(String buildingId, String invoiceId) async {
    try {
      final query = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('payments')
          .where('invoiceId', isEqualTo: invoiceId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  // Get financial summary
  Future<Map<String, dynamic>> getFinancialSummary(String buildingId) async {
    try {
      final invoicesQuery = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .get();

      final invoices =
          invoicesQuery.docs.map((doc) => Invoice.fromFirestore(doc)).toList();

      final totalInvoiced =
          invoices.fold<double>(0, (sum, invoice) => sum + invoice.total);

      final totalPaid = invoices
          .where((invoice) => invoice.status == 'paid')
          .fold<double>(0, (sum, invoice) => sum + invoice.total);

      final totalPending = invoices
          .where((invoice) => invoice.status == 'pending')
          .fold<double>(0, (sum, invoice) => sum + invoice.total);

      final totalOverdue = invoices
          .where((invoice) => invoice.isOverdue)
          .fold<double>(0, (sum, invoice) => sum + invoice.total);

      final pendingCount =
          invoices.where((invoice) => invoice.status == 'pending').length;
      final overdueCount =
          invoices.where((invoice) => invoice.isOverdue).length;
      final needsReviewCount =
          invoices.where((invoice) => invoice.needsReview).length;

      return {
        'totalInvoiced': totalInvoiced,
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'totalOverdue': totalOverdue,
        'pendingCount': pendingCount,
        'overdueCount': overdueCount,
        'needsReviewCount': needsReviewCount,
        'currency': 'ILS',
      };
    } catch (e) {
      throw Exception('Failed to fetch financial summary: $e');
    }
  }

  // Approve invoice (for committee members)
  Future<void> approveInvoice(String buildingId, String invoiceId) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .doc(invoiceId)
          .update({
        'status': 'approved',
        'needsReview': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to approve invoice: $e');
    }
  }

  // Reject invoice
  Future<void> rejectInvoice(
      String buildingId, String invoiceId, String reason) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .doc(invoiceId)
          .update({
        'status': 'rejected',
        'notes': reason,
        'needsReview': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject invoice: $e');
    }
  }
}

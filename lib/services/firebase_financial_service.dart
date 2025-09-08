import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/invoice.dart';
import '../core/models/expense.dart';

class FirebaseFinancialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Invoice operations
  static Future<List<Invoice>> getInvoicesByBuilding(String buildingId) async {
    try {
      final snapshot = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .orderBy('issueDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Invoice.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('❌ Error getting invoices: $e');
      return [];
    }
  }

  static Future<String?> addInvoice(String buildingId, Invoice invoice) async {
    try {
      final idempotencyKey = invoice.invoiceNumber;
      final coll = _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices');
      if (idempotencyKey.isNotEmpty) {
        final existing = await coll
            .where('invoiceNumber', isEqualTo: idempotencyKey)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          return existing.docs.first.id; // already exists
        }
      }
      final docRef = await coll.add(invoice.toMap());

      print('✅ Invoice added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding invoice: $e');
      return null;
    }
  }

  static Future<bool> updateInvoice(
      String buildingId, String invoiceId, Invoice invoice) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .doc(invoiceId)
          .update(invoice.toMap());

      print('✅ Invoice updated');
      return true;
    } catch (e) {
      print('❌ Error updating invoice: $e');
      return false;
    }
  }

  static Future<bool> deleteInvoice(String buildingId, String invoiceId) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .doc(invoiceId)
          .delete();

      print('✅ Invoice deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting invoice: $e');
      return false;
    }
  }

  // Expense operations
  static Future<List<Expense>> getExpensesByBuilding(String buildingId) async {
    try {
      final snapshot = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('expenses')
          .orderBy('expenseDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('❌ Error getting expenses: $e');
      return [];
    }
  }

  static Future<String?> addExpense(String buildingId, Expense expense) async {
    try {
      final key =
          '${expense.title}_${expense.amount}_${expense.expenseDate.toIso8601String()}';
      final coll = _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('expenses');
      final existing = await coll
          .where('title', isEqualTo: expense.title)
          .where('amount', isEqualTo: expense.amount)
          .where('expenseDate',
              isEqualTo: expense.expenseDate.toIso8601String())
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }
      final docRef = await coll.add(expense.toMap());

      print('✅ Expense added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding expense: $e');
      return null;
    }
  }

  static Future<bool> updateExpense(
      String buildingId, String expenseId, Expense expense) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('expenses')
          .doc(expenseId)
          .update(expense.toMap());

      print('✅ Expense updated');
      return true;
    } catch (e) {
      print('❌ Error updating expense: $e');
      return false;
    }
  }

  static Future<bool> deleteExpense(String buildingId, String expenseId) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('expenses')
          .doc(expenseId)
          .delete();

      print('✅ Expense deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting expense: $e');
      return false;
    }
  }

  // Status update methods
  static Future<bool> markInvoiceAsPaid(
      String buildingId,
      String invoiceId,
      PaymentMethod paymentMethod,
      String paymentReference,
      double amountPaid) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('invoices')
          .doc(invoiceId)
          .update({
        'status': InvoiceStatus.paid.toString().split('.').last,
        'paidAt': DateTime.now().toIso8601String(),
        'paymentMethod': paymentMethod.toString().split('.').last,
        'paymentReference': paymentReference,
        'amountPaid': amountPaid,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Invoice marked as paid');
      return true;
    } catch (e) {
      print('❌ Error marking invoice as paid: $e');
      return false;
    }
  }

  static Future<bool> approveExpense(String buildingId, String expenseId,
      String approvedBy, double? approvedAmount) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('expenses')
          .doc(expenseId)
          .update({
        'status': ExpenseStatus.approved.toString().split('.').last,
        'approvedBy': approvedBy,
        'approvedAt': DateTime.now().toIso8601String(),
        'approvedAmount': approvedAmount,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Expense approved');
      return true;
    } catch (e) {
      print('❌ Error approving expense: $e');
      return false;
    }
  }

  static Future<bool> markExpenseAsPaid(String buildingId, String expenseId,
      String paymentMethod, String paymentReference) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('expenses')
          .doc(expenseId)
          .update({
        'status': ExpenseStatus.paid.toString().split('.').last,
        'paidDate': DateTime.now().toIso8601String(),
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Expense marked as paid');
      return true;
    } catch (e) {
      print('❌ Error marking expense as paid: $e');
      return false;
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getFinancialStatistics(
      String buildingId) async {
    try {
      final invoices = await getInvoicesByBuilding(buildingId);
      final expenses = await getExpensesByBuilding(buildingId);

      // Invoice calculations
      final totalInvoiced =
          invoices.fold<double>(0, (sum, invoice) => sum + invoice.total);
      final totalPaid = invoices
          .where((i) => i.isPaid)
          .fold<double>(0, (sum, invoice) => sum + invoice.total);
      final totalOutstanding = invoices
          .where((i) => !i.isPaid)
          .fold<double>(0, (sum, invoice) => sum + invoice.outstandingAmount);
      final overdueAmount = invoices
          .where((i) => i.isOverdue)
          .fold<double>(0, (sum, invoice) => sum + invoice.total);

      // Expense calculations
      final totalExpenses =
          expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
      final totalApprovedExpenses = expenses
          .where((e) => e.isApproved)
          .fold<double>(
              0,
              (sum, expense) =>
                  sum + (expense.approvedAmount ?? expense.amount));
      final totalPaidExpenses = expenses
          .where((e) => e.isPaid)
          .fold<double>(0, (sum, expense) => sum + expense.amount);
      final pendingExpenseAmount = expenses
          .where((e) => e.isPending)
          .fold<double>(0, (sum, expense) => sum + expense.amount);

      // Net income
      final netIncome = totalPaid - totalPaidExpenses;

      // Category breakdowns
      final invoiceTypeBreakdown = <String, int>{};
      for (final invoice in invoices) {
        final type = invoice.typeDisplay;
        invoiceTypeBreakdown[type] = (invoiceTypeBreakdown[type] ?? 0) + 1;
      }

      final expenseCategoryBreakdown = <String, int>{};
      for (final expense in expenses) {
        final category = expense.categoryDisplay;
        expenseCategoryBreakdown[category] =
            (expenseCategoryBreakdown[category] ?? 0) + 1;
      }

      return {
        'totalInvoiced': totalInvoiced,
        'totalPaid': totalPaid,
        'totalOutstanding': totalOutstanding,
        'overdueAmount': overdueAmount,
        'totalExpenses': totalExpenses,
        'totalApprovedExpenses': totalApprovedExpenses,
        'totalPaidExpenses': totalPaidExpenses,
        'pendingExpenses': pendingExpenseAmount,
        'netIncome': netIncome,
        'profitMargin': totalPaid > 0
            ? ((netIncome / totalPaid) * 100).toStringAsFixed(1)
            : '0.0',
        'invoiceCount': invoices.length,
        'expenseCount': expenses.length,
        'overdueInvoices': invoices.where((i) => i.isOverdue).length,
        'pendingExpenseCount': expenses.where((e) => e.isPending).length,
        'invoiceTypeBreakdown': invoiceTypeBreakdown,
        'expenseCategoryBreakdown': expenseCategoryBreakdown,
      };
    } catch (e) {
      print('❌ Error getting financial statistics: $e');
      return {
        'totalInvoiced': 0.0,
        'totalPaid': 0.0,
        'totalOutstanding': 0.0,
        'overdueAmount': 0.0,
        'totalExpenses': 0.0,
        'totalApprovedExpenses': 0.0,
        'totalPaidExpenses': 0.0,
        'pendingExpenses': 0.0,
        'netIncome': 0.0,
        'profitMargin': '0.0',
        'invoiceCount': 0,
        'expenseCount': 0,
        'overdueInvoices': 0,
        'pendingExpenseCount': 0,
        'invoiceTypeBreakdown': <String, int>{},
        'expenseCategoryBreakdown': <String, int>{},
      };
    }
  }

  // Initialize sample financial data for a building
  static Future<void> initializeSampleFinancialData(String buildingId) async {
    try {
      // Check if data already exists
      final existingInvoices = await getInvoicesByBuilding(buildingId);
      if (existingInvoices.isNotEmpty) {
        print(
            '✅ Sample financial data already exists for building $buildingId');
        return;
      }

      final sampleInvoices = _generateSampleInvoices(buildingId);
      final sampleExpenses = _generateSampleExpenses(buildingId);

      for (final invoice in sampleInvoices) {
        await addInvoice(buildingId, invoice);
      }

      for (final expense in sampleExpenses) {
        await addExpense(buildingId, expense);
      }

      print('✅ Sample financial data initialized for building $buildingId');
    } catch (e) {
      print('❌ Error initializing sample financial data: $e');
    }
  }

  // Generate sample invoices
  static List<Invoice> _generateSampleInvoices(String buildingId) {
    final now = DateTime.now();

    return [
      Invoice(
        id: '',
        buildingId: buildingId,
        unitId: 'unit_1',
        residentId: 'resident_1',
        invoiceNumber: 'INV-2024-001',
        type: InvoiceType.maintenance,
        status: InvoiceStatus.sent,
        issueDate: now.subtract(const Duration(days: 10)),
        dueDate: now.add(const Duration(days: 20)),
        items: [
          InvoiceItem(
            id: '1',
            description: 'תחזוקת מעלית חודשית',
            quantity: 1,
            unitPrice: 150.0,
            taxRate: 17.0,
          ),
          InvoiceItem(
            id: '2',
            description: 'ניקיון חדר מדרגות',
            quantity: 1,
            unitPrice: 80.0,
            taxRate: 17.0,
          ),
        ],
        subtotal: 230.0,
        taxAmount: 39.1,
        total: 269.1,
        notes: 'תחזוקה חודשית רגילה',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      Invoice(
        id: '',
        buildingId: buildingId,
        unitId: 'unit_3',
        residentId: 'resident_2',
        invoiceNumber: 'INV-2024-002',
        type: InvoiceType.utilities,
        status: InvoiceStatus.paid,
        issueDate: now.subtract(const Duration(days: 45)),
        dueDate: now.subtract(const Duration(days: 15)),
        items: [
          InvoiceItem(
            id: '3',
            description: 'חשבון חשמל - דצמבר 2024',
            quantity: 1,
            unitPrice: 320.0,
            taxRate: 17.0,
          ),
        ],
        subtotal: 320.0,
        taxAmount: 54.4,
        total: 374.4,
        notes: 'חשבון חשמל חודשי',
        paidAt: now.subtract(const Duration(days: 20)).toIso8601String(),
        paymentMethod: PaymentMethod.bankTransfer,
        paymentReference: 'TRX-001234',
        amountPaid: 374.4,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
      Invoice(
        id: '',
        buildingId: buildingId,
        unitId: 'unit_2',
        residentId: 'resident_3',
        invoiceNumber: 'INV-2024-003',
        type: InvoiceType.management,
        status: InvoiceStatus.overdue,
        issueDate: now.subtract(const Duration(days: 60)),
        dueDate: now.subtract(const Duration(days: 30)),
        items: [
          InvoiceItem(
            id: '4',
            description: 'דמי ניהול חודשיים',
            quantity: 1,
            unitPrice: 450.0,
            taxRate: 0.0,
          ),
        ],
        subtotal: 450.0,
        taxAmount: 0.0,
        total: 450.0,
        notes: 'דמי ניהול לחודש נובמבר',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 60)),
      ),
      Invoice(
        id: '',
        buildingId: buildingId,
        unitId: null, // Building-wide
        residentId: null,
        invoiceNumber: 'INV-2024-004',
        type: InvoiceType.insurance,
        status: InvoiceStatus.viewed,
        issueDate: now.subtract(const Duration(days: 20)),
        dueDate: now.add(const Duration(days: 10)),
        items: [
          InvoiceItem(
            id: '5',
            description: 'ביטוח בניין שנתי',
            quantity: 1,
            unitPrice: 2500.0,
            taxRate: 0.0,
          ),
        ],
        subtotal: 2500.0,
        taxAmount: 0.0,
        total: 2500.0,
        notes: 'ביטוח מקיף לבניין',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
    ];
  }

  // Generate sample expenses
  static List<Expense> _generateSampleExpenses(String buildingId) {
    final now = DateTime.now();

    return [
      Expense(
        id: '',
        buildingId: buildingId,
        title: 'תיקון מעלית דחוף',
        description: 'תיקון תקלה במעלית - החלפת חלקים',
        category: ExpenseCategory.maintenance,
        status: ExpenseStatus.approved,
        priority: ExpensePriority.high,
        amount: 850.0,
        approvedAmount: 850.0,
        vendorId: 'vendor_elevator',
        vendorName: 'חברת מעליות גולדברג',
        invoiceNumber: 'MAINT-2024-001',
        expenseDate: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 25)),
        approvedBy: 'committee_chair',
        approvedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Expense(
        id: '',
        buildingId: buildingId,
        title: 'חומרי ניקיון חודשיים',
        description: 'רכישת חומרי ניקיון לבניין',
        category: ExpenseCategory.cleaning,
        status: ExpenseStatus.paid,
        priority: ExpensePriority.normal,
        amount: 280.0,
        approvedAmount: 280.0,
        vendorId: 'vendor_cleaning',
        vendorName: 'חברת ניקיון מקצועי',
        invoiceNumber: 'CLEAN-2024-001',
        expenseDate: now.subtract(const Duration(days: 20)),
        dueDate: now.subtract(const Duration(days: 5)),
        paidDate: now.subtract(const Duration(days: 8)),
        paymentMethod: 'creditCard',
        paymentReference: 'CC-5678',
        approvedBy: 'committee_chair',
        approvedAt: now.subtract(const Duration(days: 18)),
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      Expense(
        id: '',
        buildingId: buildingId,
        title: 'גיזום עצים בגינה',
        description: 'שירותי גינון וגיזום עצים',
        category: ExpenseCategory.gardening,
        status: ExpenseStatus.pending,
        priority: ExpensePriority.low,
        amount: 600.0,
        vendorId: 'vendor_garden',
        vendorName: 'גינון ירוק',
        invoiceNumber: 'GARDEN-2024-001',
        expenseDate: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 28)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Expense(
        id: '',
        buildingId: buildingId,
        title: 'תיקון מערכת חימום',
        description: 'תיקון תקלה במערכת החימום המרכזית',
        category: ExpenseCategory.maintenance,
        status: ExpenseStatus.rejected,
        priority: ExpensePriority.high,
        amount: 1200.0,
        vendorId: 'vendor_heating',
        vendorName: 'מערכות חימום מתקדמות',
        invoiceNumber: 'HEAT-2024-001',
        expenseDate: now.subtract(const Duration(days: 15)),
        dueDate: now.add(const Duration(days: 15)),
        rejectionReason: 'מחיר גבוה מדי - נדרש הצעת מחיר נוספת',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 12)),
      ),
    ];
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }
}

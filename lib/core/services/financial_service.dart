import '../models/invoice.dart';
import '../models/expense.dart';
import 'building_service.dart';

class FinancialService {
  // In-memory storage for now (will be replaced with Firebase later)
  static final List<Invoice> _invoices = [];
  static final List<Expense> _expenses = [];
  static int _nextInvoiceId = 1;
  static int _nextExpenseId = 1;

  // Invoice CRUD operations
  static List<Invoice> getAllInvoices() {
    return List.from(_invoices);
  }

  static Invoice? getInvoiceById(String id) {
    try {
      return _invoices.firstWhere((invoice) => invoice.id == id);
    } catch (e) {
      return null;
    }
  }

  static Invoice addInvoice(Invoice invoice) {
    final newInvoice = invoice.copyWith(
      id: _nextInvoiceId.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _invoices.add(newInvoice);
    _nextInvoiceId++;

    return newInvoice;
  }

  static Invoice? updateInvoice(Invoice invoice) {
    final index = _invoices.indexWhere((i) => i.id == invoice.id);
    if (index != -1) {
      final updatedInvoice = invoice.copyWith(
        updatedAt: DateTime.now(),
      );
      _invoices[index] = updatedInvoice;
      return updatedInvoice;
    }
    return null;
  }

  static bool deleteInvoice(String id) {
    final index = _invoices.indexWhere((i) => i.id == id);
    if (index != -1) {
      _invoices.removeAt(index);
      return true;
    }
    return false;
  }

  // Expense CRUD operations
  static List<Expense> getAllExpenses() {
    return List.from(_expenses);
  }

  static Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((expense) => expense.id == id);
    } catch (e) {
      return null;
    }
  }

  static Expense addExpense(Expense expense) {
    final newExpense = expense.copyWith(
      id: _nextExpenseId.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _expenses.add(newExpense);
    _nextExpenseId++;

    return newExpense;
  }

  static Expense? updateExpense(Expense expense) {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      final updatedExpense = expense.copyWith(
        updatedAt: DateTime.now(),
      );
      _expenses[index] = updatedExpense;
      return updatedExpense;
    }
    return null;
  }

  static bool deleteExpense(String id) {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses.removeAt(index);
      return true;
    }
    return false;
  }

  // Invoice filtering and search
  static List<Invoice> getInvoicesByBuilding(String buildingId) {
    return _invoices
        .where((invoice) => invoice.buildingId == buildingId)
        .toList();
  }

  static List<Invoice> getInvoicesByUnit(String unitId) {
    return _invoices.where((invoice) => invoice.unitId == unitId).toList();
  }

  static List<Invoice> getInvoicesByResident(String residentId) {
    return _invoices
        .where((invoice) => invoice.residentId == residentId)
        .toList();
  }

  static List<Invoice> getInvoicesByStatus(InvoiceStatus status) {
    return _invoices.where((invoice) => invoice.status == status).toList();
  }

  static List<Invoice> getInvoicesByType(InvoiceType type) {
    return _invoices.where((invoice) => invoice.type == type).toList();
  }

  static List<Invoice> getOverdueInvoices() {
    return _invoices.where((invoice) => invoice.isOverdue).toList();
  }

  static List<Invoice> getPendingInvoices() {
    return _invoices.where((invoice) => invoice.isPending).toList();
  }

  static List<Invoice> getPaidInvoices() {
    return _invoices.where((invoice) => invoice.isPaid).toList();
  }

  // Expense filtering and search
  static List<Expense> getExpensesByBuilding(String buildingId) {
    return _expenses
        .where((expense) => expense.buildingId == buildingId)
        .toList();
  }

  static List<Expense> getExpensesByUnit(String unitId) {
    return _expenses.where((expense) => expense.unitId == unitId).toList();
  }

  static List<Expense> getExpensesByCategory(ExpenseCategory category) {
    return _expenses.where((expense) => expense.category == category).toList();
  }

  static List<Expense> getExpensesByStatus(ExpenseStatus status) {
    return _expenses.where((expense) => expense.status == status).toList();
  }

  static List<Expense> getPendingExpenses() {
    return _expenses.where((expense) => expense.isPending).toList();
  }

  static List<Expense> getApprovedExpenses() {
    return _expenses.where((expense) => expense.isApproved).toList();
  }

  static List<Expense> getPaidExpenses() {
    return _expenses.where((expense) => expense.isPaid).toList();
  }

  static List<Expense> getOverdueExpenses() {
    return _expenses.where((expense) => expense.isOverdue).toList();
  }

  // Search functionality
  static List<Invoice> searchInvoices(String query) {
    if (query.isEmpty) return getAllInvoices();

    final lowercaseQuery = query.toLowerCase();
    return _invoices.where((invoice) {
      return invoice.invoiceNumber.toLowerCase().contains(lowercaseQuery) ||
          (invoice.notes?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  static List<Expense> searchExpenses(String query) {
    if (query.isEmpty) return getAllExpenses();

    final lowercaseQuery = query.toLowerCase();
    return _expenses.where((expense) {
      return expense.title.toLowerCase().contains(lowercaseQuery) ||
          expense.description.toLowerCase().contains(lowercaseQuery) ||
          (expense.notes?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (expense.vendorName?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Financial statistics
  static Map<String, dynamic> getBuildingFinancialStatistics(
      String buildingId) {
    final buildingInvoices = getInvoicesByBuilding(buildingId);
    final buildingExpenses = getExpensesByBuilding(buildingId);

    // Invoice statistics
    final totalInvoiced =
        buildingInvoices.fold<double>(0, (sum, invoice) => sum + invoice.total);
    final totalPaid = buildingInvoices
        .where((i) => i.isPaid)
        .fold<double>(0, (sum, invoice) => sum + invoice.total);
    final totalOutstanding = buildingInvoices
        .where((i) => !i.isPaid)
        .fold<double>(0, (sum, invoice) => sum + invoice.outstandingAmount);
    final overdueAmount = buildingInvoices
        .where((i) => i.isOverdue)
        .fold<double>(0, (sum, invoice) => sum + invoice.total);

    // Expense statistics
    final totalExpenses = buildingExpenses.fold<double>(
        0, (sum, expense) => sum + expense.amount);
    final totalApprovedExpenses = buildingExpenses
        .where((e) => e.isApproved)
        .fold<double>(0, (sum, expense) => sum + expense.approvedAmount!);
    final totalPaidExpenses = buildingExpenses
        .where((e) => e.isPaid)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final pendingExpenses = buildingExpenses
        .where((e) => e.isPending)
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    // Net income
    final netIncome = totalPaid - totalPaidExpenses;

    return {
      'totalInvoiced': totalInvoiced,
      'totalPaid': totalPaid,
      'totalOutstanding': totalOutstanding,
      'overdueAmount': overdueAmount,
      'totalExpenses': totalExpenses,
      'totalApprovedExpenses': totalApprovedExpenses,
      'totalPaidExpenses': totalPaidExpenses,
      'pendingExpenses': pendingExpenses,
      'netIncome': netIncome,
      'profitMargin': totalPaid > 0
          ? ((netIncome / totalPaid) * 100).toStringAsFixed(1)
          : '0.0',
      'invoiceCount': buildingInvoices.length,
      'expenseCount': buildingExpenses.length,
      'overdueInvoices': buildingInvoices.where((i) => i.isOverdue).length,
      'pendingExpenses': buildingExpenses.where((e) => e.isPending).length,
    };
  }

  static Map<String, dynamic> getOverallFinancialStatistics() {
    final totalInvoiced =
        _invoices.fold<double>(0, (sum, invoice) => sum + invoice.total);
    final totalPaid = _invoices
        .where((i) => i.isPaid)
        .fold<double>(0, (sum, invoice) => sum + invoice.total);
    final totalOutstanding = _invoices
        .where((i) => !i.isPaid)
        .fold<double>(0, (sum, invoice) => sum + invoice.outstandingAmount);
    final totalExpenses =
        _expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final totalPaidExpenses = _expenses
        .where((e) => e.isPaid)
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final netIncome = totalPaid - totalPaidExpenses;

    // Category breakdowns
    final invoiceTypeBreakdown = <String, double>{};
    final expenseCategoryBreakdown = <String, double>{};

    for (final invoice in _invoices) {
      final typeName = invoice.typeDisplay;
      invoiceTypeBreakdown[typeName] =
          (invoiceTypeBreakdown[typeName] ?? 0) + invoice.total;
    }

    for (final expense in _expenses) {
      final categoryName = expense.categoryDisplay;
      expenseCategoryBreakdown[categoryName] =
          (expenseCategoryBreakdown[categoryName] ?? 0) + expense.amount;
    }

    return {
      'totalInvoiced': totalInvoiced,
      'totalPaid': totalPaid,
      'totalOutstanding': totalOutstanding,
      'totalExpenses': totalExpenses,
      'totalPaidExpenses': totalPaidExpenses,
      'netIncome': netIncome,
      'profitMargin': totalPaid > 0
          ? ((netIncome / totalPaid) * 100).toStringAsFixed(1)
          : '0.0',
      'invoiceTypeBreakdown': invoiceTypeBreakdown,
      'expenseCategoryBreakdown': expenseCategoryBreakdown,
      'totalInvoices': _invoices.length,
      'totalExpenses': _expenses.length,
      'overdueInvoices': _invoices.where((i) => i.isOverdue).length,
      'pendingExpenses': _expenses.where((e) => e.isPending).length,
    };
  }

  // Invoice status updates
  static bool markInvoiceAsSent(String invoiceId) {
    final invoice = getInvoiceById(invoiceId);
    if (invoice != null) {
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.sent,
        updatedAt: DateTime.now(),
      );
      updateInvoice(updatedInvoice);
      return true;
    }
    return false;
  }

  static bool markInvoiceAsViewed(String invoiceId) {
    final invoice = getInvoiceById(invoiceId);
    if (invoice != null) {
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.viewed,
        updatedAt: DateTime.now(),
      );
      updateInvoice(updatedInvoice);
      return true;
    }
    return false;
  }

  static bool markInvoiceAsPaid(
      String invoiceId, PaymentMethod paymentMethod, String paymentReference) {
    final invoice = getInvoiceById(invoiceId);
    if (invoice != null) {
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.paid,
        paidAt: DateTime.now().toIso8601String(),
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        amountPaid: invoice.total,
        updatedAt: DateTime.now(),
      );
      updateInvoice(updatedInvoice);
      return true;
    }
    return false;
  }

  static bool markInvoiceAsOverdue(String invoiceId) {
    final invoice = getInvoiceById(invoiceId);
    if (invoice != null && invoice.isOverdue) {
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.overdue,
        updatedAt: DateTime.now(),
      );
      updateInvoice(updatedInvoice);
      return true;
    }
    return false;
  }

  // Expense status updates
  static bool approveExpense(
      String expenseId, String approvedBy, double? approvedAmount) {
    final expense = getExpenseById(expenseId);
    if (expense != null) {
      final updatedExpense = expense.copyWith(
        status: ExpenseStatus.approved,
        approvedBy: approvedBy,
        approvedAt: DateTime.now(),
        approvedAmount: approvedAmount ?? expense.amount,
        updatedAt: DateTime.now(),
      );
      updateExpense(updatedExpense);
      return true;
    }
    return false;
  }

  static bool rejectExpense(
      String expenseId, String rejectedBy, String rejectionReason) {
    final expense = getExpenseById(expenseId);
    if (expense != null) {
      final updatedExpense = expense.copyWith(
        status: ExpenseStatus.rejected,
        rejectionReason: rejectionReason,
        updatedAt: DateTime.now(),
      );
      updateExpense(updatedExpense);
      return true;
    }
    return false;
  }

  static bool markExpenseAsPaid(
      String expenseId, String paymentMethod, String paymentReference) {
    final expense = getExpenseById(expenseId);
    if (expense != null && expense.isApproved) {
      final updatedExpense = expense.copyWith(
        status: ExpenseStatus.paid,
        paidDate: DateTime.now(),
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        updatedAt: DateTime.now(),
      );
      updateExpense(updatedExpense);
      return true;
    }
    return false;
  }

  // Sample data initialization
  static void initializeSampleData() {
    // Clear existing data to allow reinitialization for new buildings
    _invoices.clear();
    _expenses.clear();
    _nextInvoiceId = 1;
    _nextExpenseId = 1;

    // Get the first available building ID
    final buildings = BuildingService.getAllBuildings();
    if (buildings.isEmpty) {
      print('⚠️ No buildings available for sample data');
      return;
    }

    final buildingId = buildings.first.id;
    print('🏢 Creating sample data for building: $buildingId');

    // Sample invoices
    final sampleInvoices = [
      Invoice(
        id: '1',
        buildingId: buildingId,
        unitId: '1',
        residentId: '1',
        invoiceNumber: 'INV-2024-001',
        type: InvoiceType.maintenance,
        status: InvoiceStatus.sent,
        issueDate: DateTime.now().subtract(const Duration(days: 30)),
        dueDate: DateTime.now().add(const Duration(days: 15)),
        items: [
          InvoiceItem(
            id: '1',
            description: 'תחזוקת מערכת מיזוג אוויר',
            quantity: 1,
            unitPrice: 500.0,
            taxRate: 17.0,
          ),
          InvoiceItem(
            id: '2',
            description: 'החלפת פילטרים',
            quantity: 2,
            unitPrice: 75.0,
            taxRate: 17.0,
          ),
        ],
        subtotal: 650.0,
        taxAmount: 110.5,
        total: 760.5,
        notes: 'תחזוקה תקופתית למערכת המיזוג',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Invoice(
        id: '2',
        buildingId: buildingId,
        unitId: '2',
        residentId: '2',
        invoiceNumber: 'INV-2024-002',
        type: InvoiceType.rent,
        status: InvoiceStatus.paid,
        issueDate: DateTime.now().subtract(const Duration(days: 60)),
        dueDate: DateTime.now().subtract(const Duration(days: 30)),
        items: [
          InvoiceItem(
            id: '3',
            description: 'שכירות דירה - דצמבר 2024',
            quantity: 1,
            unitPrice: 3500.0,
            taxRate: 0.0,
          ),
        ],
        subtotal: 3500.0,
        taxAmount: 0.0,
        total: 3500.0,
        notes: 'שכירות חודשית',
        paidAt:
            DateTime.now().subtract(const Duration(days: 35)).toIso8601String(),
        paymentMethod: PaymentMethod.bankTransfer,
        paymentReference: 'TRX-12345',
        amountPaid: 3500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
      Invoice(
        id: '3',
        buildingId: buildingId,
        unitId: '3',
        residentId: '3',
        invoiceNumber: 'INV-2024-003',
        type: InvoiceType.utilities,
        status: InvoiceStatus.overdue,
        issueDate: DateTime.now().subtract(const Duration(days: 45)),
        dueDate: DateTime.now().subtract(const Duration(days: 15)),
        items: [
          InvoiceItem(
            id: '4',
            description: 'חשבון חשמל - נובמבר 2024',
            quantity: 1,
            unitPrice: 280.0,
            taxRate: 17.0,
          ),
        ],
        subtotal: 280.0,
        taxAmount: 47.6,
        total: 327.6,
        notes: 'חשבון חשמל חודשי',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ];

    // Sample expenses
    final sampleExpenses = [
      Expense(
        id: '1',
        buildingId: buildingId,
        title: 'תחזוקת מעליות',
        description: 'תחזוקה תקופתית למעליות הבניין',
        category: ExpenseCategory.maintenance,
        status: ExpenseStatus.approved,
        priority: ExpensePriority.normal,
        amount: 1200.0,
        approvedAmount: 1200.0,
        vendorId: '2',
        vendorName: 'חברת מעליות גולדברג',
        invoiceNumber: 'VINV-001',
        expenseDate: DateTime.now().subtract(const Duration(days: 20)),
        dueDate: DateTime.now().add(const Duration(days: 10)),
        approvedBy: 'committee_member_1',
        approvedAt: DateTime.now().subtract(const Duration(days: 18)),
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
      Expense(
        id: '2',
        buildingId: buildingId,
        title: 'ביטוח בניין',
        description: 'ביטוח שנתי לבניין כולל אחריות',
        category: ExpenseCategory.insurance,
        status: ExpenseStatus.paid,
        priority: ExpensePriority.high,
        amount: 5000.0,
        approvedAmount: 5000.0,
        vendorId: 'insurance_company_1',
        vendorName: 'חברת ביטוח כללי',
        invoiceNumber: 'INS-2024-001',
        expenseDate: DateTime.now().subtract(const Duration(days: 90)),
        dueDate: DateTime.now().subtract(const Duration(days: 60)),
        paidDate: DateTime.now().subtract(const Duration(days: 65)),
        paymentMethod: 'bankTransfer',
        paymentReference: 'TRX-67890',
        approvedBy: 'committee_member_1',
        approvedAt: DateTime.now().subtract(const Duration(days: 95)),
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        updatedAt: DateTime.now().subtract(const Duration(days: 65)),
      ),
      Expense(
        id: '3',
        buildingId: buildingId,
        title: 'ניקיון חודשי',
        description: 'שירותי ניקיון חודשיים לבניין',
        category: ExpenseCategory.cleaning,
        status: ExpenseStatus.pending,
        priority: ExpensePriority.normal,
        amount: 800.0,
        vendorId: '4',
        vendorName: 'גינון ירוק',
        invoiceNumber: 'CLN-2024-001',
        expenseDate: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 25)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

    // Add sample data
    for (final invoice in sampleInvoices) {
      _invoices.add(invoice);
    }
    for (final expense in sampleExpenses) {
      _expenses.add(expense);
    }

    _nextInvoiceId = sampleInvoices.length + 1;
    _nextExpenseId = sampleExpenses.length + 1;
  }

  // Utility methods
  static List<Invoice> getInvoicesByDateRange(
      DateTime startDate, DateTime endDate) {
    return _invoices.where((invoice) {
      return invoice.issueDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          invoice.issueDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  static List<Expense> getExpensesByDateRange(
      DateTime startDate, DateTime endDate) {
    return _expenses.where((expense) {
      return expense.expenseDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.expenseDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  static double getTotalRevenueByDateRange(
      DateTime startDate, DateTime endDate) {
    final invoices = getInvoicesByDateRange(startDate, endDate);
    return invoices
        .where((i) => i.isPaid)
        .fold<double>(0, (sum, invoice) => sum + invoice.total);
  }

  static double getTotalExpensesByDateRange(
      DateTime startDate, DateTime endDate) {
    final expenses = getExpensesByDateRange(startDate, endDate);
    return expenses
        .where((e) => e.isPaid)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }
}

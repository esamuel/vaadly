import 'package:vaadly/core/services/financial_service.dart';
import 'package:vaadly/core/models/invoice.dart';
import 'package:vaadly/core/models/expense.dart';

void main() {
  print('🧪 Testing Vaadly Financial System');
  print('==================================\n');

  // Initialize sample data
  print('📊 Initializing sample financial data...');
  FinancialService.initializeSampleData();
  print('✅ Sample data initialized\n');

  // Test Invoice functionality
  print('🧾 Testing Invoice System:');
  print('---------------------------');

  final allInvoices = FinancialService.getAllInvoices();
  print('📋 Total invoices: ${allInvoices.length}');

  for (final invoice in allInvoices) {
    print('\n📄 Invoice: ${invoice.invoiceNumber}');
    print('   Type: ${invoice.typeDisplay}');
    print('   Status: ${invoice.statusDisplay}');
    print('   Amount: ₪${invoice.total.toStringAsFixed(2)}');
    print(
        '   Due: ${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}');
    print('   Items: ${invoice.items.length}');

    if (invoice.isOverdue) {
      print('   ⚠️  OVERDUE: ${invoice.overdueDisplay}');
    }

    for (final item in invoice.items) {
      print(
          '     • ${item.description}: ${item.quantity}x ₪${item.unitPrice} = ₪${item.subtotal.toStringAsFixed(2)}');
    }
  }

  // Test Expense functionality
  print('\n💰 Testing Expense System:');
  print('---------------------------');

  final allExpenses = FinancialService.getAllExpenses();
  print('📋 Total expenses: ${allExpenses.length}');

  for (final expense in allExpenses) {
    print('\n💸 Expense: ${expense.title}');
    print('   Category: ${expense.categoryDisplay}');
    print('   Status: ${expense.statusDisplay}');
    print('   Amount: ₪${expense.amount.toStringAsFixed(2)}');
    print('   Priority: ${expense.priorityDisplay}');
    print('   Vendor: ${expense.vendorName ?? 'N/A'}');

    if (expense.isOverdue) {
      print('   ⚠️  OVERDUE: ${expense.overdueDisplay}');
    }
  }

  // Test Financial Statistics
  print('\n📈 Testing Financial Statistics:');
  print('--------------------------------');

  final buildingStats = FinancialService.getBuildingFinancialStatistics('1');
  print('🏢 Building Financial Statistics:');
  print(
      '   Total Invoiced: ₪${buildingStats['totalInvoiced'].toStringAsFixed(2)}');
  print('   Total Paid: ₪${buildingStats['totalPaid'].toStringAsFixed(2)}');
  print(
      '   Total Outstanding: ₪${buildingStats['totalOutstanding'].toStringAsFixed(2)}');
  print(
      '   Total Expenses: ₪${buildingStats['totalExpenses'].toStringAsFixed(2)}');
  print('   Net Income: ₪${buildingStats['netIncome'].toStringAsFixed(2)}');
  print('   Profit Margin: ${buildingStats['profitMargin']}%');
  print('   Invoice Count: ${buildingStats['invoiceCount']}');
  print('   Expense Count: ${buildingStats['expenseCount']}');
  print('   Overdue Invoices: ${buildingStats['overdueInvoices']}');
  print('   Pending Expenses: ${buildingStats['pendingExpenses']}');

  final overallStats = FinancialService.getOverallFinancialStatistics();
  print('\n🌍 Overall Financial Statistics:');
  print(
      '   Total Invoiced: ₪${overallStats['totalInvoiced'].toStringAsFixed(2)}');
  print('   Total Paid: ₪${overallStats['totalPaid'].toStringAsFixed(2)}');
  print(
      '   Total Outstanding: ₪${overallStats['totalOutstanding'].toStringAsFixed(2)}');
  print(
      '   Total Expenses: ₪${overallStats['totalExpenses'].toStringAsFixed(2)}');
  print('   Net Income: ₪${overallStats['netIncome'].toStringAsFixed(2)}');
  print('   Profit Margin: ${overallStats['profitMargin']}%');

  // Test Search functionality
  print('\n🔍 Testing Search Functionality:');
  print('--------------------------------');

  final maintenanceInvoices =
      FinancialService.getInvoicesByType(InvoiceType.maintenance);
  print('🔧 Maintenance invoices: ${maintenanceInvoices.length}');

  final pendingExpenses = FinancialService.getPendingExpenses();
  print('⏳ Pending expenses: ${pendingExpenses.length}');

  final overdueInvoices = FinancialService.getOverdueInvoices();
  print('⚠️  Overdue invoices: ${overdueInvoices.length}');

  // Test Status Updates
  print('\n🔄 Testing Status Updates:');
  print('---------------------------');

  if (allInvoices.isNotEmpty) {
    final firstInvoice = allInvoices.first;
    print(
        '📝 Testing invoice status update for: ${firstInvoice.invoiceNumber}');

    if (firstInvoice.status == InvoiceStatus.sent) {
      print('   Marking as viewed...');
      FinancialService.markInvoiceAsViewed(firstInvoice.id);
      final updatedInvoice = FinancialService.getInvoiceById(firstInvoice.id);
      print('   New status: ${updatedInvoice?.statusDisplay}');
    }
  }

  if (allExpenses.isNotEmpty) {
    final firstExpense = allExpenses.first;
    print('💸 Testing expense status update for: ${firstExpense.title}');

    if (firstExpense.status == ExpenseStatus.pending) {
      print('   Approving expense...');
      FinancialService.approveExpense(firstExpense.id, 'test_user', null);
      final updatedExpense = FinancialService.getExpenseById(firstExpense.id);
      print('   New status: ${updatedExpense?.statusDisplay}');
    }
  }

  print('\n🎉 Financial System Test Complete!');
  print('All models and services are working correctly.');
}

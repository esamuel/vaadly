import 'package:flutter/material.dart';
import 'package:vaadly/core/services/financial_service.dart';
import 'package:vaadly/services/firebase_building_service.dart';
import 'package:vaadly/core/models/invoice.dart';
import 'package:vaadly/core/models/expense.dart';
import 'package:vaadly/core/models/building.dart';

class FinancialManagementPage extends StatefulWidget {
  const FinancialManagementPage({super.key});

  @override
  State<FinancialManagementPage> createState() =>
      _FinancialManagementPageState();
}

class _FinancialManagementPageState extends State<FinancialManagementPage> {
  String? _selectedBuildingId;
  List<Building> _buildings = [];
  List<Invoice> _invoices = [];
  List<Expense> _expenses = [];
  Map<String, dynamic> _buildingStats = {};
  Map<String, dynamic> _overallStats = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load buildings from Firebase
      _buildings = await FirebaseBuildingService.getAllBuildings();
      print('🏢 Buildings loaded from Firebase: ${_buildings.length}');

      // Test FinancialService directly
      final allInvoices = FinancialService.getAllInvoices();
      final allExpenses = FinancialService.getAllExpenses();
      print('🧾 All invoices: ${allInvoices.length}');
      print('💸 All expenses: ${allExpenses.length}');

      if (_buildings.isNotEmpty) {
        _selectedBuildingId = _buildings.first.id;
        print(
            '🏢 Selected building: ${_buildings.first.name} (ID: $_selectedBuildingId)');
        _loadFinancialData();
      }
    } catch (e) {
      print('❌ Error loading buildings: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _loadFinancialData() {
    if (_selectedBuildingId != null) {
      setState(() {
        _invoices =
            FinancialService.getInvoicesByBuilding(_selectedBuildingId!);
        _expenses =
            FinancialService.getExpensesByBuilding(_selectedBuildingId!);
        _buildingStats = FinancialService.getBuildingFinancialStatistics(
            _selectedBuildingId!);
        _overallStats = FinancialService.getOverallFinancialStatistics();
      });
    }
  }

  void _onBuildingChanged(String? buildingId) {
    setState(() {
      _selectedBuildingId = buildingId;
      _loadFinancialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('💰 ניהול פיננסי'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'סטטיסטיקות', icon: Icon(Icons.analytics)),
              Tab(text: 'חשבוניות', icon: Icon(Icons.receipt)),
              Tab(text: 'הוצאות', icon: Icon(Icons.payments)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Debug info display
            Container(
              width: double.infinity,
              color: Colors.yellow[100],
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🐛 Debug Info:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Buildings: ${_buildings.length}'),
                  Text('Invoices: ${_invoices.length}'),
                  Text('Expenses: ${_expenses.length}'),
                  Text('Building Stats: ${_buildingStats.length}'),
                  Text('Overall Stats: ${_overallStats.length}'),
                ],
              ),
            ),
            // Building selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildings.isNotEmpty
                  ? DropdownButtonFormField<String>(
                      initialValue: _selectedBuildingId,
                      decoration: const InputDecoration(
                        labelText: 'בחר בניין',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: _buildings.map((building) {
                        return DropdownMenuItem(
                          value: building.id,
                          child: Text(building.name),
                        );
                      }).toList(),
                      onChanged: _onBuildingChanged,
                    )
                  : const Text('אין בניינים זמינים'),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildStatisticsTab(),
                  _buildInvoicesTab(),
                  _buildExpensesTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddFinancialItem(context),
          label: const Text('הוסף פריט פיננסי'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    // Debug info
    print('📊 Building stats: $_buildingStats');
    print('📊 Overall stats: $_overallStats');

    if (_buildingStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('אין נתונים פיננסיים זמינים'),
            const SizedBox(height: 16),
            Text('בניינים: ${_buildings.length}'),
            Text('חשבוניות: ${_invoices.length}'),
            Text('הוצאות: ${_expenses.length}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('טען נתונים מחדש'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Building financial overview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'סקירה פיננסית - ${_buildings.firstWhere((b) => b.id == _selectedBuildingId).name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'סך הכל חויב',
                        '₪${_buildingStats['totalInvoiced'].toStringAsFixed(0)}',
                        Colors.blue,
                        Icons.receipt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'סך הכל שולם',
                        '₪${_buildingStats['totalPaid'].toStringAsFixed(0)}',
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'סכום בפיגור',
                        '₪${_buildingStats['totalOutstanding'].toStringAsFixed(0)}',
                        Colors.orange,
                        Icons.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'סך הכל הוצאות',
                        '₪${_buildingStats['totalExpenses'].toStringAsFixed(0)}',
                        Colors.red,
                        Icons.payments,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Net income and profit margin
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'הכנסה נטו',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '₪${_buildingStats['netIncome'].toStringAsFixed(0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: _buildingStats['netIncome'] >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'רווחיות',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${_buildingStats['profitMargin']}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: double.parse(_buildingStats[
                                                'profitMargin']) >=
                                            0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Overall platform statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'סטטיסטיקות כלליות',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'חשבוניות',
                        '${_overallStats['totalInvoices']}',
                        Colors.blue,
                        Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'הוצאות',
                        '${_overallStats['totalExpenses']}',
                        Colors.red,
                        Icons.payments,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'בפיגור',
                        '${_overallStats['overdueInvoices']}',
                        Colors.orange,
                        Icons.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'ממתין אישור',
                        '${_overallStats['pendingExpenses']}',
                        Colors.yellow,
                        Icons.pending,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) {
      return const Center(
        child: Text('אין חשבוניות זמינות'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: invoice.statusColor,
              child: const Icon(
                Icons.receipt,
                color: Colors.white,
              ),
            ),
            title: Text(
              invoice.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${invoice.typeDisplay} - ${invoice.statusDisplay}'),
                if (invoice.isOverdue)
                  Text(
                    invoice.overdueDisplay,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                Text('תאריך יעד: ${_formatDate(invoice.dueDate)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₪${invoice.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${invoice.items.length} פריטים',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            onTap: () => _showInvoiceDetails(invoice),
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Text('אין הוצאות זמינות'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: expense.statusColor,
              child: const Icon(
                Icons.payments,
                color: Colors.white,
              ),
            ),
            title: Text(
              expense.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${expense.categoryDisplay} - ${expense.statusDisplay}'),
                Text('עדיפות: ${expense.priorityDisplay}'),
                if (expense.isOverdue)
                  Text(
                    expense.overdueDisplay,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                if (expense.vendorName != null)
                  Text('ספק: ${expense.vendorName}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₪${expense.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  expense.statusDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: expense.statusColor,
                  ),
                ),
              ],
            ),
            onTap: () => _showExpenseDetails(expense),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showInvoiceDetails(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('חשבונית: ${invoice.invoiceNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('סוג: ${invoice.typeDisplay}'),
              Text('סטטוס: ${invoice.statusDisplay}'),
              Text('סכום: ₪${invoice.total.toStringAsFixed(2)}'),
              Text('תאריך יעד: ${_formatDate(invoice.dueDate)}'),
              if (invoice.notes != null) Text('הערות: ${invoice.notes}'),
              const SizedBox(height: 16),
              const Text('פריטים:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...invoice.items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                        '• ${item.description}: ${item.quantity}x ₪${item.unitPrice}'),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('הוצאה: ${expense.title}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('קטגוריה: ${expense.categoryDisplay}'),
              Text('סטטוס: ${expense.statusDisplay}'),
              Text('עדיפות: ${expense.priorityDisplay}'),
              Text('סכום: ₪${expense.amount.toStringAsFixed(2)}'),
              Text('תאריך: ${_formatDate(expense.expenseDate)}'),
              if (expense.vendorName != null)
                Text('ספק: ${expense.vendorName}'),
              if (expense.notes != null) Text('הערות: ${expense.notes}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _showAddFinancialItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הוסף פריט פיננסי'),
        content: const Text('פונקציונליות זו תתווסף בשלב הבא'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }
}

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('בחר את סוג הפריט הפיננסי:'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAddInvoiceDialog(context);
                  },
                  icon: const Icon(Icons.receipt),
                  label: const Text('חשבונית'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAddExpenseDialog(context);
                  },
                  icon: const Icon(Icons.money_off),
                  label: const Text('הוצאה'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  void _showAddInvoiceDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final recipientController = TextEditingController();
    InvoiceType selectedType = InvoiceType.maintenance;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('הוסף חשבונית חדשה'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<InvoiceType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'סוג חשבונית',
                        border: OutlineInputBorder(),
                      ),
                      items: InvoiceType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getInvoiceTypeText(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'סכום (₪)',
                        border: OutlineInputBorder(),
                        prefixText: '₪ ',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'נא להזין סכום';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'נא להזין סכום תקין';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'תיאור',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'נא להזין תיאור';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: recipientController,
                      decoration: const InputDecoration(
                        labelText: 'נמען',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'נא להזין נמען';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('תאריך'),
                      subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _createInvoice(
                    type: selectedType,
                    amount: double.parse(amountController.text),
                    description: descriptionController.text,
                    recipient: recipientController.text,
                    date: selectedDate,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('צור חשבונית'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final vendorController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.maintenance;
    ExpensePriority selectedPriority = ExpensePriority.normal;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('הוסף הוצאה חדשה'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ExpenseCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'קטגורית הוצאה',
                        border: OutlineInputBorder(),
                      ),
                      items: ExpenseCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(_getExpenseCategoryText(category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'סכום (₪)',
                        border: OutlineInputBorder(),
                        prefixText: '₪ ',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'נא להזין סכום';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'נא להזין סכום תקין';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'תיאור',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'נא להזין תיאור';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: vendorController,
                      decoration: const InputDecoration(
                        labelText: 'ספק/נותן שירות',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ExpensePriority>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'עדיפות',
                        border: OutlineInputBorder(),
                      ),
                      items: ExpensePriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(_getExpensePriorityText(priority)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('תאריך'),
                      subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _createExpense(
                    category: selectedCategory,
                    amount: double.parse(amountController.text),
                    description: descriptionController.text,
                    vendor: vendorController.text.isEmpty ? null : vendorController.text,
                    priority: selectedPriority,
                    date: selectedDate,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('צור הוצאה'),
            ),
          ],
        ),
      ),
    );
  }

  void _createInvoice({
    required InvoiceType type,
    required double amount,
    required String description,
    required String recipient,
    required DateTime date,
  }) {
    if (_selectedBuildingId == null) return;

    final invoiceItem = InvoiceItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      quantity: 1,
      unitPrice: amount,
    );

    final invoice = Invoice(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      buildingId: _selectedBuildingId!,
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      status: InvoiceStatus.draft,
      issueDate: date,
      dueDate: date.add(const Duration(days: 30)),
      items: [invoiceItem],
      subtotal: invoiceItem.subtotal,
      taxAmount: invoiceItem.taxAmount,
      total: invoiceItem.subtotal + invoiceItem.taxAmount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // TODO: Save to Firebase instead of just local service
    FinancialService.addInvoice(invoice);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('חשבונית נוצרה בהצלחה'),
        backgroundColor: Colors.green,
      ),
    );

    _loadFinancialData(); // Refresh data
  }

  void _createExpense({
    required ExpenseCategory category,
    required double amount,
    required String description,
    String? vendor,
    required ExpensePriority priority,
    required DateTime date,
  }) {
    if (_selectedBuildingId == null) return;

    final expense = Expense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      buildingId: _selectedBuildingId!,
      title: description,
      description: description,
      category: category,
      status: amount <= 2000 ? ExpenseStatus.approved : ExpenseStatus.pending, // Auto-approve small expenses
      priority: priority,
      amount: amount,
      vendorName: vendor,
      expenseDate: date,
      dueDate: date.add(const Duration(days: 30)),
      approvedBy: amount <= 2000 ? 'system' : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // TODO: Save to Firebase instead of just local service
    FinancialService.addExpense(expense);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(amount <= 2000 ? 'הוצאה נוצרה ואושרה אוטומטית' : 'הוצאה נוצרה ומחכה לאישור'),
        backgroundColor: Colors.green,
      ),
    );

    _loadFinancialData(); // Refresh data
  }

  String _getInvoiceTypeText(InvoiceType type) {
    switch (type) {
      case InvoiceType.maintenance:
        return 'תחזוקה';
      case InvoiceType.rent:
        return 'שכר דירה';
      case InvoiceType.utilities:
        return 'שירותים';
      case InvoiceType.insurance:
        return 'ביטוח';
      case InvoiceType.taxes:
        return 'מסים';
      case InvoiceType.management:
        return 'ניהול';
      case InvoiceType.other:
        return 'אחר';
    }
  }

  String _getExpenseCategoryText(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return 'תחזוקה';
      case ExpenseCategory.utilities:
        return 'שירותים';
      case ExpenseCategory.insurance:
        return 'ביטוח';
      case ExpenseCategory.taxes:
        return 'מסים';
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

  String _getExpensePriorityText(ExpensePriority priority) {
    switch (priority) {
      case ExpensePriority.low:
        return 'נמוכה';
      case ExpensePriority.normal:
        return 'רגילה';
      case ExpensePriority.high:
        return 'גבוהה';
      case ExpensePriority.urgent:
        return 'דחוף';
    }
  }
}

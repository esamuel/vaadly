import 'package:flutter/material.dart';
import '../core/models/building.dart';
import '../core/models/invoice.dart';
import '../core/models/expense.dart';
import '../services/firebase_financial_service.dart';

class FirebaseFinancialPage extends StatefulWidget {
  final List<Building> buildings;

  const FirebaseFinancialPage({
    super.key,
    required this.buildings,
  });

  @override
  State<FirebaseFinancialPage> createState() => _FirebaseFinancialPageState();
}

class _FirebaseFinancialPageState extends State<FirebaseFinancialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBuildingId;
  List<Invoice> _invoices = [];
  List<Expense> _expenses = [];
  Map<String, dynamic> _statistics = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.buildings.isNotEmpty) {
      _selectedBuildingId = widget.buildings.first.id;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_selectedBuildingId == null) return;

    setState(() => _loading = true);

    try {
      // Initialize sample data if needed
      await FirebaseFinancialService.initializeSampleFinancialData(_selectedBuildingId!);

      // Load data
      final invoices = await FirebaseFinancialService.getInvoicesByBuilding(_selectedBuildingId!);
      final expenses = await FirebaseFinancialService.getExpensesByBuilding(_selectedBuildingId!);
      final statistics = await FirebaseFinancialService.getFinancialStatistics(_selectedBuildingId!);

      setState(() {
        _invoices = invoices;
        _expenses = expenses;
        _statistics = statistics;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading financial data: $e');
      setState(() => _loading = false);
    }
  }

  void _onBuildingChanged(String? buildingId) {
    setState(() {
      _selectedBuildingId = buildingId;
      _invoices = [];
      _expenses = [];
      _statistics = {};
    });
    if (buildingId != null) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 ניהול פיננסי'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'סטטיסטיקות', icon: Icon(Icons.analytics)),
            Tab(text: 'חשבוניות', icon: Icon(Icons.receipt)),
            Tab(text: 'הוצאות', icon: Icon(Icons.payments)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Building selector
          if (widget.buildings.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBuildingId,
                decoration: const InputDecoration(
                  labelText: 'בחר בניין',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                items: widget.buildings.map((building) {
                  return DropdownMenuItem(
                    value: building.id,
                    child: Text(building.name),
                  );
                }).toList(),
                onChanged: _onBuildingChanged,
              ),
            ),
          
          // Loading indicator
          if (_loading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('טוען נתונים פיננסיים...'),
                  ],
                ),
              ),
            )
          else if (_selectedBuildingId == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('בחר בניין כדי לראות נתונים פיננסיים'),
                  ],
                ),
              ),
            )
          else
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStatisticsTab(),
                  _buildInvoicesTab(),
                  _buildExpensesTab(),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedBuildingId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddFinancialItem(context),
              icon: const Icon(Icons.add),
              label: const Text('הוסף פריט פיננסי'),
            )
          : null,
    );
  }

  Widget _buildStatisticsTab() {
    if (_statistics.isEmpty) {
      return const Center(
        child: Text('אין נתונים סטטיסטיים זמינים'),
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
                  'סקירה פיננסית - ${widget.buildings.firstWhere((b) => b.id == _selectedBuildingId).name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                // Income and expenses overview
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'סך הכל חויב',
                        '₪${_statistics['totalInvoiced'].toStringAsFixed(0)}',
                        Colors.blue,
                        Icons.receipt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'סך הכל שולם',
                        '₪${_statistics['totalPaid'].toStringAsFixed(0)}',
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
                        'בפיגור',
                        '₪${_statistics['totalOutstanding'].toStringAsFixed(0)}',
                        Colors.orange,
                        Icons.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'סך הוצאות',
                        '₪${_statistics['totalExpenses'].toStringAsFixed(0)}',
                        Colors.red,
                        Icons.payments,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Net income summary
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
                              '₪${_statistics['netIncome'].toStringAsFixed(0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: _statistics['netIncome'] >= 0
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
                              '${_statistics['profitMargin']}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: double.parse(
                                                _statistics['profitMargin']) >=
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
        
        // Counts overview
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
                        '${_statistics['invoiceCount']}',
                        Colors.blue,
                        Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'הוצאות',
                        '${_statistics['expenseCount']}',
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
                        '${_statistics['overdueInvoices']}',
                        Colors.orange,
                        Icons.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'ממתין אישור',
                        '${_statistics['pendingExpenseCount']}',
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('אין חשבוניות זמינות'),
          ],
        ),
      );
    }

    return ListView.builder(
      // Extra bottom padding so the last item doesn't get overlapped by FAB
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: invoice.statusColor,
              child: const Icon(
                Icons.receipt,
                color: Colors.white,
                size: 20,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₪${invoice.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
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
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (invoice.notes != null) ...[
                      const Text(
                        'הערות:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(invoice.notes!),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'פריטים:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...invoice.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('• ${item.description}')),
                              Text(
                                '${item.quantity}x ₪${item.unitPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (invoice.status != InvoiceStatus.paid)
                          ElevatedButton.icon(
                            onPressed: () => _markInvoiceAsPaid(invoice),
                            icon: const Icon(Icons.payment),
                            label: const Text('סמן כשולם'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _editInvoice(invoice),
                          icon: const Icon(Icons.edit),
                          label: const Text('ערוך'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('אין הוצאות זמינות'),
          ],
        ),
      );
    }

    return ListView.builder(
      // Extra bottom padding so the last item doesn't get overlapped by FAB
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: expense.statusColor,
              child: const Icon(
                Icons.payments,
                color: Colors.white,
                size: 20,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₪${expense.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: expense.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    expense.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: expense.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'תיאור:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(expense.description),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('תאריך הוצאה: '),
                        Text(
                          _formatDate(expense.expenseDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('תאריך יעד: '),
                        Text(
                          _formatDate(expense.dueDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (expense.notes != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'הערות:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(expense.notes!),
                    ],
                    if (expense.rejectionReason != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'סיבת דחייה:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        expense.rejectionReason!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (expense.status == ExpenseStatus.pending)
                          ElevatedButton.icon(
                            onPressed: () => _approveExpense(expense),
                            icon: const Icon(Icons.check),
                            label: const Text('אשר'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (expense.status == ExpenseStatus.approved)
                          ElevatedButton.icon(
                            onPressed: () => _markExpenseAsPaid(expense),
                            icon: const Icon(Icons.payment),
                            label: const Text('סמן כשולם'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _editExpense(expense),
                          icon: const Icon(Icons.edit),
                          label: const Text('ערוך'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Future<void> _markInvoiceAsPaid(Invoice invoice) async {
    final success = await FirebaseFinancialService.markInvoiceAsPaid(
      _selectedBuildingId!,
      invoice.id,
      PaymentMethod.bankTransfer,
      'Manual-${DateTime.now().millisecondsSinceEpoch}',
      invoice.total,
    );

    if (success) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('החשבונית סומנה כשולמה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בעדכון החשבונית'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveExpense(Expense expense) async {
    final success = await FirebaseFinancialService.approveExpense(
      _selectedBuildingId!,
      expense.id,
      'committee_chair',
      expense.amount,
    );

    if (success) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ההוצאה אושרה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה באישור ההוצאה'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markExpenseAsPaid(Expense expense) async {
    final success = await FirebaseFinancialService.markExpenseAsPaid(
      _selectedBuildingId!,
      expense.id,
      'bankTransfer',
      'Manual-${DateTime.now().millisecondsSinceEpoch}',
    );

    if (success) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ההוצאה סומנה כשולמה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בעדכון ההוצאה'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ערוך חשבונית: ${invoice.invoiceNumber}'),
        content: const Text('פונקציית עריכה תתווסף בגרסה הבאה'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _editExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ערוך הוצאה: ${expense.title}'),
        content: const Text('פונקציית עריכה תתווסף בגרסה הבאה'),
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.receipt),
              title: Text('הוסף חשבונית'),
              subtitle: Text('יצירת חשבונית חדשה'),
            ),
            ListTile(
              leading: Icon(Icons.payments),
              title: Text('הוסף הוצאה'),
              subtitle: Text('רישום הוצאה חדשה'),
            ),
            SizedBox(height: 16),
            Text('פונקציונליות זו תתווסף בגרסה הבאה'),
          ],
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
}
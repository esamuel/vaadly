import 'package:flutter/material.dart';

class FinancialDashboard extends StatefulWidget {
  const FinancialDashboard({super.key});

  @override
  State<FinancialDashboard> createState() => _FinancialDashboardState();
}

class _FinancialDashboardState extends State<FinancialDashboard> {
  int _selectedTabIndex = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _loading = true);

    // Simulate loading financial data
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 ניהול כספים'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadFinancialData,
            icon: const Icon(Icons.refresh),
            tooltip: 'רענן',
          ),
        ],
      ),
      body: Column(
        children: [
          // Financial summary cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                    child: _buildStatCard('סה"כ הכנסות', '₪4,500',
                        Icons.attach_money, Colors.green)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'סה"כ הוצאות', '₪2,300', Icons.payments, Colors.red)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'רווח נקי', '₪2,200', Icons.trending_up, Colors.blue)),
              ],
            ),
          ),

          // Tab bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('חשבוניות', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('הוצאות', 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('דוחות', 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildInvoicesTab(),
                _buildExpensesTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddInvoiceDialog(),
              icon: const Icon(Icons.add),
              label: const Text('חשבונית חדשה'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            )
          : _selectedTabIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddExpenseDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('הוצאה חדשה'),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                )
              : null,
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return _buildInvoiceCard(index);
            },
          );
  }

  Widget _buildExpensesTab() {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return _buildExpenseCard(index);
            },
          );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'דוחות כספיים',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Monthly summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'סיכום חודשי - ינואר 2024',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildReportRow('הכנסות', '₪4,500', Colors.green),
                  _buildReportRow('הוצאות', '₪2,300', Colors.red),
                  _buildReportRow('רווח נקי', '₪2,200', Colors.blue),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick actions
          const Text(
            'פעולות מהירות',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'ייצא דוח',
                  Icons.download,
                  Colors.blue,
                  () => _exportReport(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'דוח שנתי',
                  Icons.analytics,
                  Colors.green,
                  () => _showAnnualReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(int index) {
    final invoices = [
      {
        'number': 'INV-2024-001',
        'description': 'דמי ועד בית - ינואר 2024',
        'amount': '₪1,500',
        'status': 'ממתין'
      },
      {
        'number': 'INV-2024-002',
        'description': 'דמי ועד בית - ינואר 2024',
        'amount': '₪1,800',
        'status': 'שולם'
      },
      {
        'number': 'INV-2024-003',
        'description': 'דמי ועד בית - ינואר 2024',
        'amount': '₪1,200',
        'status': 'באיחור'
      },
    ];

    final invoice = invoices[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: const Icon(Icons.receipt, color: Colors.blue),
        ),
        title: Text(
          invoice['number']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice['description']!),
            const SizedBox(height: 4),
            Text(
              'תאריך יעד: 15/01/2024',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              invoice['amount']!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildStatusChip(invoice['status']!),
          ],
        ),
        onTap: () => _showInvoiceDetails(invoice),
      ),
    );
  }

  Widget _buildExpenseCard(int index) {
    final expenses = [
      {
        'title': 'תחזוקת מעלית',
        'vendor': 'חברת מעליות כהן',
        'amount': '₪2,500',
        'status': 'אושר'
      },
      {
        'title': 'ניקיון בניין',
        'vendor': 'חברת ניקיון לוי',
        'amount': '₪800',
        'status': 'ממתין'
      },
      {
        'title': 'חשמל בניין',
        'vendor': 'חברת החשמל',
        'amount': '₪1,200',
        'status': 'אושר'
      },
    ];

    final expense = expenses[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: const Icon(Icons.build, color: Colors.green),
        ),
        title: Text(
          expense['title']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense['vendor']!),
            const SizedBox(height: 4),
            Text(
              'תאריך: 10/01/2024',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              expense['amount']!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildStatusChip(expense['status']!),
          ],
        ),
        onTap: () => _showExpenseDetails(expense),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'ממתין':
        color = Colors.orange;
        break;
      case 'שולם':
      case 'אושר':
        color = Colors.green;
        break;
      case 'באיחור':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showInvoiceDetails(Map<String, String> invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(invoice['number']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('תיאור: ${invoice['description']}'),
            const SizedBox(height: 8),
            Text('סכום: ${invoice['amount']}'),
            const SizedBox(height: 8),
            const Text('תאריך יעד: 15/01/2024'),
            const SizedBox(height: 8),
            Text('סטטוס: ${invoice['status']}'),
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

  void _showExpenseDetails(Map<String, String> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense['title']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ספק: ${expense['vendor']}'),
            const SizedBox(height: 8),
            Text('סכום: ${expense['amount']}'),
            const SizedBox(height: 8),
            const Text('תאריך: 10/01/2024'),
            const SizedBox(height: 8),
            Text('סטטוס: ${expense['status']}'),
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

  void _showAddInvoiceDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('הוספת חשבונית חדשה - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _showAddExpenseDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('הוספת הוצאה חדשה - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ייצוא דוח - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _showAnnualReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('דוח שנתי - תכונה זו תהיה זמינה בקרוב')),
    );
  }
}

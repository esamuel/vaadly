import 'package:flutter/material.dart';
import '../../../core/models/building.dart';
import '../../../services/firebase_building_service.dart';
import 'package:intl/intl.dart';

class PaymentsDemoPage extends StatefulWidget {
  const PaymentsDemoPage({super.key});

  @override
  State<PaymentsDemoPage> createState() => _PaymentsDemoPageState();
}

class _PaymentsDemoPageState extends State<PaymentsDemoPage> with TickerProviderStateMixin {
  List<Building> _buildings = [];
  String? _selectedBuildingId;
  bool _loading = false;
  TabController? _tabController;

  final _currencyFormatter = NumberFormat.currency(locale: 'he_IL', symbol: '₪');

  // Demo data
  final List<Map<String, dynamic>> _demoPayments = [
    {
      'id': '1',
      'title': 'שכירות דצמבר 2024',
      'amount': 4500.0,
      'dueDate': DateTime(2024, 12, 1),
      'paidDate': DateTime(2024, 11, 28),
      'status': 'completed',
      'unitId': '101',
      'type': 'rent',
    },
    {
      'id': '2',
      'title': 'שכירות ינואר 2025',
      'amount': 4500.0,
      'dueDate': DateTime(2025, 1, 1),
      'paidDate': null,
      'status': 'pending',
      'unitId': '101',
      'type': 'rent',
    },
    {
      'id': '3',
      'title': 'תחזוקה נובמבר 2024',
      'amount': 800.0,
      'dueDate': DateTime(2024, 11, 15),
      'paidDate': null,
      'status': 'overdue',
      'unitId': '102',
      'type': 'maintenance',
    },
    {
      'id': '4',
      'title': 'שכירות דצמבר 2024',
      'amount': 3800.0,
      'dueDate': DateTime(2024, 12, 1),
      'paidDate': DateTime(2024, 12, 2),
      'status': 'completed',
      'unitId': '203',
      'type': 'rent',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBuildings();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() => _loading = true);
    try {
      _buildings = await FirebaseBuildingService.getAllBuildings();
      if (_buildings.isNotEmpty) {
        _selectedBuildingId = _buildings.first.id;
      }
    } catch (e) {
      print('❌ Error loading buildings: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('ניהול תשלומים'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.list_alt), text: 'כל התשלומים'),
                  Tab(icon: Icon(Icons.warning), text: 'באיחור'),
                  Tab(icon: Icon(Icons.analytics), text: 'סטטיסטיקות'),
                ],
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePaymentDialog,
            tooltip: 'צור תשלום חדש',
          ),
        ],
      ),
      body: Column(
        children: [
          // Building selector
          if (_buildings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('בניין:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedBuildingId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _buildings.map((building) {
                        return DropdownMenuItem<String>(
                          value: building.id,
                          child: Text(building.name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBuildingId = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tab content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tabController != null
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllPaymentsTab(),
                          _buildOverduePaymentsTab(),
                          _buildStatisticsTab(),
                        ],
                      )
                    : const Center(child: Text('טוען...')),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPaymentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _demoPayments.length,
      itemBuilder: (context, index) {
        return _buildPaymentCard(_demoPayments[index]);
      },
    );
  }

  Widget _buildOverduePaymentsTab() {
    final overduePayments = _demoPayments
        .where((payment) => payment['status'] == 'overdue')
        .toList();

    if (overduePayments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'אין תשלומים באיחור',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Warning banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'תשלומים באיחור',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '${overduePayments.length} תשלומים ממתינים',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Overdue payments list
        Expanded(
          child: ListView.builder(
            itemCount: overduePayments.length,
            itemBuilder: (context, index) {
              return _buildPaymentCard(overduePayments[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    final totalPayments = _demoPayments.length;
    final completedPayments = _demoPayments.where((p) => p['status'] == 'completed').length;
    final pendingPayments = _demoPayments.where((p) => p['status'] == 'pending').length;
    final overduePayments = _demoPayments.where((p) => p['status'] == 'overdue').length;

    final totalAmount = _demoPayments.fold<double>(0.0, (sum, payment) => sum + payment['amount']);
    final collectedAmount = _demoPayments
        .where((p) => p['status'] == 'completed')
        .fold<double>(0.0, (sum, payment) => sum + payment['amount']);
    final pendingAmount = _demoPayments
        .where((p) => p['status'] != 'completed')
        .fold<double>(0.0, (sum, payment) => sum + payment['amount']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overview cards
          Row(
            children: [
              Expanded(child: _buildStatCard('כל התשלומים', totalPayments.toString(), Icons.list_alt, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('הושלמו', completedPayments.toString(), Icons.check_circle, Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStatCard('ממתינים', pendingPayments.toString(), Icons.pending, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('באיחור', overduePayments.toString(), Icons.error, Colors.red)),
            ],
          ),
          
          const SizedBox(height: 24),

          // Amount statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'סטטיסטיקות כספיות',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAmountRow('סך הכל', totalAmount, Colors.blue),
                  const SizedBox(height: 8),
                  _buildAmountRow('נגבה', collectedAmount, Colors.green),
                  const SizedBox(height: 8),
                  _buildAmountRow('ממתין לגבייה', pendingAmount, Colors.orange),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: totalAmount > 0 ? collectedAmount / totalAmount : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'אחוז גבייה: ${totalAmount > 0 ? (collectedAmount / totalAmount * 100).toStringAsFixed(1) : '0.0'}%',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'פעולות זמינות',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    'שלח תזכורת לתשלומים באיחור',
                    Icons.email,
                    Colors.orange,
                    () => _showFeatureDialog('תזכורות אימייל'),
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'ייצר חוזה שכירות',
                    Icons.description,
                    Colors.blue,
                    () => _showFeatureDialog('מערכת חוזים'),
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'בדיקת מועמד לדירה',
                    Icons.person_search,
                    Colors.purple,
                    () => _showFeatureDialog('מערכת סקר מועמדים'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'];
    final amount = payment['amount'];
    final dueDate = payment['dueDate'] as DateTime;
    final paidDate = payment['paidDate'] as DateTime?;
    
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'הושלם';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'ממתין';
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusText = 'באיחור';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'לא ידוע';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    payment['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'סכום:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _currencyFormatter.format(amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'תאריך יעד:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: status == 'overdue' ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Payment info
            if (paidDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'שולם ב-${paidDate.day}/${paidDate.month}/${paidDate.year}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Action button
            if (status != 'completed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(payment),
                  icon: const Icon(Icons.payment),
                  label: Text(status == 'overdue' ? 'שלם עכשיו' : 'שלם'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'overdue' ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          _currencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(title),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('תשלום ${payment['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('סכום: ${_currencyFormatter.format(payment['amount'])}'),
              const SizedBox(height: 8),
              Text('יחידה: ${payment['unitId']}'),
              const SizedBox(height: 16),
              const Text(
                'במערכת המלאה, כאן יופיע ממשק תשלום מאובטח עם Stripe לעיבוד תשלומים.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessMessage('תשלום הושלם בהצלחה (דמו)');
              },
              child: const Text('שלם עכשיו (דמו)'),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('צור תשלום חדש'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('במערכת המלאה, כאן יופיע טופס ליצירת תשלום חדש עם:'),
              SizedBox(height: 8),
              Text('• בחירת שוכר/יחידה'),
              Text('• סוג תשלום (שכירות, תחזוקה, וכו\')'),
              Text('• סכום ותאריך יעד'),
              Text('• הערות נוספות'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('סגור'),
            ),
          ],
        );
      },
    );
  }

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(feature),
          content: Text('$feature כבר מוכן במערכת!\n\nהפיצ\'רים שיושמו:\n• מערכת תשלומים מלאה\n• אוטומציית אימיילים\n• ניהול חוזי שכירות\n• בדיקת מועמדים'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('מעולה!'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/building.dart';
import '../../../services/stripe_payment_service.dart';
import '../../../services/firebase_building_service.dart';
import '../widgets/payment_card.dart';
import 'package:intl/intl.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> with TickerProviderStateMixin {
  List<Building> _buildings = [];
  String? _selectedBuildingId;
  List<Payment> _payments = [];
  List<Payment> _overduePayments = [];
  bool _loading = false;
  TabController? _tabController;

  final _currencyFormatter = NumberFormat.currency(locale: 'he_IL', symbol: '₪');

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
        await _loadPayments();
      }
    } catch (e) {
      print('❌ Error loading buildings: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPayments() async {
    if (_selectedBuildingId == null) return;

    setState(() => _loading = true);
    try {
      _payments = await StripePaymentService.getPaymentsByBuilding(_selectedBuildingId!);
      _overduePayments = await StripePaymentService.getOverduePayments(_selectedBuildingId!);
    } catch (e) {
      print('❌ Error loading payments: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createSamplePayment() async {
    if (_selectedBuildingId == null) return;

    setState(() => _loading = true);
    try {
      await StripePaymentService.createPaymentRecord(
        buildingId: _selectedBuildingId!,
        unitId: '101',
        residentId: 'demo_resident',
        title: 'שכירות חודש ${DateFormat('MM/yyyy').format(DateTime.now())}',
        description: 'תשלום שכירות חודשי',
        type: PaymentType.rent,
        amount: 4500.0,
        dueDate: DateTime.now().add(const Duration(days: 30)),
      );

      await _loadPayments();
      _showSuccessMessage('תשלום דמו נוצר בהצלחה');
    } catch (e) {
      _showErrorMessage('שגיאה ביצירת תשלום: ${e.toString()}');
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
          if (_selectedBuildingId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createSamplePayment,
              tooltip: 'צור תשלום דמו',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
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
                        _loadPayments();
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
    if (_payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'אין תשלומים להצגה',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'לחץ על + ליצירת תשלום דמו',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        return PaymentCard(
          payment: _payments[index],
          onPaymentCompleted: _loadPayments,
        );
      },
    );
  }

  Widget _buildOverduePaymentsTab() {
    if (_overduePayments.isEmpty) {
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
                      '${_overduePayments.length} תשלומים ממתינים',
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
            itemCount: _overduePayments.length,
            itemBuilder: (context, index) {
              return PaymentCard(
                payment: _overduePayments[index],
                onPaymentCompleted: _loadPayments,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    final totalPayments = _payments.length;
    final completedPayments = _payments.where((p) => p.status == PaymentStatus.completed).length;
    final pendingPayments = _payments.where((p) => p.status == PaymentStatus.pending).length;
    final failedPayments = _payments.where((p) => p.status == PaymentStatus.failed).length;

    final totalAmount = _payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
    final collectedAmount = _payments
        .where((p) => p.status == PaymentStatus.completed)
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);
    final pendingAmount = _payments
        .where((p) => p.status == PaymentStatus.pending)
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);

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
              Expanded(child: _buildStatCard('נכשלו', failedPayments.toString(), Icons.error, Colors.red)),
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
        ],
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
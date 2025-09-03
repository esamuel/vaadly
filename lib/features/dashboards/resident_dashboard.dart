import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';
import '../auth/auth_screen.dart';
import '../maintenance/report_issue_screen.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  int _selectedIndex = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget _buildMessageItem(String title, String preview, String time, bool unread) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.teal, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.w500),
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
        ],
      ),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {
        // Open message thread - to be implemented
      },
    );
  }

  Widget _buildDocumentItem(String name, String type, String size) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.folder_open, color: Colors.indigo, size: 20),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('$type • $size'),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        onPressed: () {
          // Download/view document - to be implemented
        },
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load resident-specific data
      // This will be implemented with your existing services
    } catch (e) {
      print('❌ Error loading data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;
    final buildingId = BuildingContextService.buildingId ?? user.accessibleBuildings.first;
    final unitId = user.getResidentUnit(buildingId) ?? 'Unknown';
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.home, color: Colors.teal),
            SizedBox(width: 8),
            Text('הבית שלי'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.teal.withOpacity(0.2),
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                _showUserProfile();
              } else if (value == 'signOut') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(user.name),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'signOut',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('התנתק', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(),
                _buildPaymentsTab(),
                _buildMaintenanceTab(),
                _buildMessagesTab(),
                _buildDocumentsTab(),
                _buildBuildingInfoTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'בית',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'תשלומים',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'תחזוקה',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'הודעות',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'מסמכים',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'בניין',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final user = AuthService.currentUser!;
    final buildingId = BuildingContextService.buildingId ?? user.accessibleBuildings.first;
    final unitId = user.getResidentUnit(buildingId) ?? 'Unknown';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home, color: Colors.teal, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ברוכ הבא הביתה, ${user.name.split(' ').first}!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unit $unitId - מגדל השלום',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'בניין מגדל שלום',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
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

          // Account status
          Text(
            'סטטוס חשבון',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatusCard('Balance', '₪-450', Icons.account_balance_wallet, Colors.red)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusCard('Last Payment', 'Nov 15', Icons.payment, Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatusCard('Open Requests', '1', Icons.build, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusCard('Messages', '2', Icons.mail, Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),

          // Recent activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _buildActivityItem(
                  'Payment due',
                  'Monthly maintenance fee - ₪1,200',
                  Icons.payment,
                  Colors.red,
                  'Due in 3 days',
                ),
                const Divider(),
                _buildActivityItem(
                  'Maintenance update',
                  'Elevator repair completed',
                  Icons.build,
                  Colors.green,
                  '2 days ago',
                ),
                const Divider(),
                _buildActivityItem(
                  'Building announcement',
                  'Water system maintenance scheduled',
                  Icons.campaign,
                  Colors.blue,
                  '1 week ago',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard('Pay Now', Icons.payment, Colors.green, () {
                setState(() => _selectedIndex = 1);
              }),
              _buildActionCard('Report Issue', Icons.report_problem, Colors.orange, () {
                setState(() => _selectedIndex = 2);
              }),
              _buildActionCard('View Payments', Icons.receipt_long, Colors.blue, () {
                setState(() => _selectedIndex = 1);
              }),
              _buildActionCard('Contact Management', Icons.phone, Colors.purple, () {
                setState(() => _selectedIndex = 3); // open Messages tab
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    final user = AuthService.currentUser!;
    final buildingId = BuildingContextService.buildingId ?? user.accessibleBuildings.first;
    final messagesRef = FirebaseFirestore.instance
        .collection('buildings')
        .doc(buildingId)
        .collection('messages');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'הודעות',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.orderBy('createdAt', descending: true).limit(50).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('שגיאה בטעינת הודעות'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('אין הודעות'),
                      ],
                    ),
                  );
                }
                return Card(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>? ?? {};
                      final title = (data['title'] ?? data['subject'] ?? 'הודעה') as String;
                      final preview = (data['body'] ?? data['message'] ?? '') as String;
                      final ts = data['createdAt'];
                      String time = '';
                      if (ts is Timestamp) {
                        final dt = ts.toDate();
                        time = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
                      }
                      final recipients = data['recipients'];
                      bool unread = false;
                      if (recipients is Map) {
                        final entry = recipients[user.id];
                        if (entry is Map) {
                          unread = !(entry['read'] == true);
                        }
                      }
                      return _buildMessageItem(title, preview, time, unread);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final user = AuthService.currentUser!;
    final buildingId = BuildingContextService.buildingId ?? user.accessibleBuildings.first;
    final docsRef = FirebaseFirestore.instance
        .collection('buildings')
        .doc(buildingId)
        .collection('documents');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'מסמכים',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: docsRef.orderBy('updatedAt', descending: true).limit(100).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('שגיאה בטעינת מסמכים'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.folder_open, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('אין מסמכים'),
                      ],
                    ),
                  );
                }
                return Card(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>? ?? {};
                      final name = (data['name'] ?? data['title'] ?? 'מסמך') as String;
                      final type = (data['type'] ?? 'FILE') as String;
                      final size = (data['sizeLabel'] ?? '') as String;
                      return _buildDocumentItem(name, type, size);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance overview
          Card(
            color: Colors.red.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Balance',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const Text(
                          '₪-450',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        Text(
                          'Outstanding payment due',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Pay now functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Pay Now'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Payment History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Payment history
          Card(
            child: Column(
              children: [
                _buildPaymentItem('Monthly Fee', '₪1,200', 'Nov 2025', 'Pending', Colors.orange),
                const Divider(),
                _buildPaymentItem('Monthly Fee', '₪1,200', 'Oct 2025', 'Paid', Colors.green),
                const Divider(),
                _buildPaymentItem('Monthly Fee', '₪1,200', 'Sep 2025', 'Paid', Colors.green),
                const Divider(),
                _buildPaymentItem('Special Assessment', '₪500', 'Aug 2025', 'Paid', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create request button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('דווח על תקלה חדשה'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'הבקשות שלי',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Maintenance requests
          Card(
            child: Column(
              children: [
                _buildMaintenanceItem(
                  'ברז נוטף במטבח',
                  'נשלח לפני 3 ימים',
                  'בתהליך',
                  Colors.orange,
                  Icons.water_drop,
                ),
                const Divider(),
                _buildMaintenanceItem(
                  'ידית דלת שבורה',
                  'נשלח לפני שבוע',
                  'הושלם',
                  Colors.green,
                  Icons.door_front_door,
                ),
                const Divider(),
                _buildMaintenanceItem(
                  'מזגן לא עובד',
                  'נשלח לפני שבועיים',
                  'הושלם',
                  Colors.green,
                  Icons.ac_unit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Building info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'מגדל השלום',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Address', 'רחוב הרצל 123, תל אביב'),
                  _buildInfoRow('Building Manager', 'יוסי כהן'),
                  _buildInfoRow('Phone', '050-1234567'),
                  _buildInfoRow('Email', 'committee@shalom-tower.co.il'),
                  _buildInfoRow('Emergency', '100'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'הודעות אחרונות',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Announcements
          Card(
            child: Column(
              children: [
                _buildAnnouncementItem(
                  'תחזוקת מערכת מים',
                  'תחזוקה מתוכננת ב-5 בדצמבר מ-9:00-12:00',
                  'לפני יומיים',
                  Icons.water,
                ),
                const Divider(),
                _buildAnnouncementItem(
                  'שעות חג',
                  'משרד הבניין סגור בחגים',
                  'לפני שבוע',
                  Icons.celebration,
                ),
                const Divider(),
                _buildAnnouncementItem(
                  'כללי חניה חדשים',
                  'הקצאת חניה מעודכנת חל מ-1 בינואר',
                  'לפני שבועיים',
                  Icons.local_parking,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
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
              style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, String time) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildPaymentItem(String description, String amount, String date, String status, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.payment, color: color, size: 20),
      ),
      title: Text(description, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(date),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(status, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem(String title, String subtitle, String status, Color color, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: Chip(
        label: Text(status, style: const TextStyle(fontSize: 12)),
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String title, String content, String time, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(content),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
      ),
    );
  }

  void _showUserProfile() {
    final user = AuthService.currentUser!;
    final buildingId = user.accessibleBuildings.first;
    final unitId = user.getResidentUnit(buildingId) ?? 'Unknown';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resident Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
            const Text('Role: Resident'),
            Text('Unit: $unitId'),
            const Text('Building: Shalom Tower'),
            const Text('Status: Active'),
            Text('Moved in: ${user.createdAt.toLocal().toString().split(' ')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
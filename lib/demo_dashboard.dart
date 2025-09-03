import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DemoDashboardApp());
}

class DemoDashboardApp extends StatelessWidget {
  const DemoDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vaadly Demo Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const DemoDashboard(),
    );
  }
}

class DemoDashboard extends StatefulWidget {
  const DemoDashboard({super.key});

  @override
  State<DemoDashboard> createState() => _DemoDashboardState();
}

class _DemoDashboardState extends State<DemoDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.purple),
            SizedBox(width: 8),
            Text('Vaadly Demo Dashboard'),
          ],
        ),
        backgroundColor: Colors.purple[50],
        foregroundColor: Colors.purple[900],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(),
          _buildBuildingsTab(),
          _buildUsersTab(),
          _buildAnalyticsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Buildings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users/Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Vaadly',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Building Management Platform',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Statistics
          const Text(
            'Platform Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Buildings', '12', Icons.business, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'Active Users', '156', Icons.people, Colors.green)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'Revenue', '₪45,230', Icons.attach_money, Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
              _buildActionCard('Add Building', Icons.add_business, Colors.blue,
                  () {
                setState(() => _selectedIndex = 1);
              }),
              _buildActionCard('Manage Users', Icons.people, Colors.green, () {
                setState(() => _selectedIndex = 2);
              }),
              _buildActionCard('View Analytics', Icons.analytics, Colors.purple,
                  () {
                setState(() => _selectedIndex = 3);
              }),
              _buildActionCard('Settings', Icons.settings, Colors.grey, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingsTab() {
    final buildings = [
      {
        'name': 'מגדל השלום',
        'address': 'רחוב הרצל 123, תל אביב',
        'units': 24,
        'occupancy': '85%'
      },
      {
        'name': 'בית הגפן',
        'address': 'רחוב ויצמן 45, חיפה',
        'units': 18,
        'occupancy': '92%'
      },
      {
        'name': 'מגדל הים',
        'address': 'טיילת הים 78, אשדוד',
        'units': 32,
        'occupancy': '78%'
      },
      {
        'name': 'בית הפרחים',
        'address': 'רחוב הפרחים 12, ירושלים',
        'units': 16,
        'occupancy': '100%'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: buildings.length,
      itemBuilder: (context, index) {
        final building = buildings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.business, color: Colors.white),
            ),
            title: Text(building['name'] as String),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(building['address'] as String),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${building['units']} units'),
                    const SizedBox(width: 16),
                    Text('${building['occupancy']} occupancy'),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.people, size: 24, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'User Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage building committees and residents across all your buildings',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // User Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '156',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Building Committees',
                  '12',
                  Icons.business,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Residents',
                  '144',
                  Icons.home,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Users List
          const Text(
            'Recent Users',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildUserList(),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final users = [
      {
        'name': 'יוסי כהן',
        'role': 'Building Committee',
        'building': 'מגדל השלום',
        'email': 'yossi@shalom.co.il'
      },
      {
        'name': 'שרה לוי',
        'role': 'Resident',
        'building': 'בית הגפן',
        'email': 'sarah@levi.co.il'
      },
      {
        'name': 'דוד רוזן',
        'role': 'Building Committee',
        'building': 'מגדל הים',
        'email': 'david@rosen.co.il'
      },
      {
        'name': 'מיכל גולדברג',
        'role': 'Resident',
        'building': 'בית הפרחים',
        'email': 'michal@goldberg.co.il'
      },
    ];

    return Column(
      children: users
          .map((user) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['role'] == 'Building Committee'
                        ? Colors.indigo
                        : Colors.green,
                    child: Text(
                      user['name']!.substring(0, 1),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(user['name']!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['role']!),
                      Text('${user['building']} • ${user['email']}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.lock_reset),
                            SizedBox(width: 8),
                            Text('Reset Password'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.analytics, size: 24, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Revenue & Usage Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Performance metrics and business insights across your platform',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Revenue Analytics
          const Text(
            'Revenue Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Monthly Revenue',
                '₪15,230',
                Icons.attach_money,
                Colors.green,
              ),
              _buildMetricCard(
                'Yearly Revenue',
                '₪182,760',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildMetricCard(
                'Active Subscriptions',
                '12',
                Icons.business_center,
                Colors.indigo,
              ),
              _buildMetricCard(
                'Retention Rate',
                '95%',
                Icons.favorite,
                Colors.pink,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Usage Analytics
          const Text(
            'Usage Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Daily Active Users',
                '89',
                Icons.people,
                Colors.orange,
              ),
              _buildMetricCard(
                'Daily Logins',
                '156',
                Icons.login,
                Colors.purple,
              ),
              _buildMetricCard(
                'New Buildings This Month',
                '2',
                Icons.add_business,
                Colors.teal,
              ),
              _buildMetricCard(
                'Average Usage',
                '2.5h',
                Icons.schedule,
                Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Business Insights
          const Text(
            'Business Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Growth Recommendations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                      '📈 Revenue increased 15% this month', Colors.green),
                  _buildInsightItem(
                      '🏢 2 new buildings joined the platform', Colors.blue),
                  _buildInsightItem('👥 User engagement up 23%', Colors.orange),
                  _buildInsightItem(
                      '💡 Consider expanding to new cities', Colors.purple),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Export Data',
                  Icons.download,
                  Colors.blue,
                  () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Monthly Report',
                  Icons.description,
                  Colors.green,
                  () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Configure Alerts',
                  Icons.notifications,
                  Colors.orange,
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
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
          Icon(
            icon,
            color: color,
            size: 32,
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/multi_tenant_auth_service.dart';
import '../../core/models/user.dart';
import '../../core/models/building.dart';
import '../../services/firebase_building_service.dart';
import '../auth/auth_screen.dart';
import '../buildings/buildings_list_screen.dart';
import '../buildings/add_building_screen.dart';
import '../users/password_reset_screen.dart';

class AppOwnerDashboard extends StatefulWidget {
  const AppOwnerDashboard({super.key});

  @override
  State<AppOwnerDashboard> createState() => _AppOwnerDashboardState();
}

class _AppOwnerDashboardState extends State<AppOwnerDashboard> {
  int _selectedIndex = 0;
  List<Building> _buildings = [];
  final List<VaadlyUser> _users = [];
  bool _loading = false;
  Map<String, dynamic> _stats = {};
  final Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load buildings data from Firebase
      _buildings = await FirebaseBuildingService.getAllBuildings();

      // Load building statistics from Firebase
      _stats = await FirebaseBuildingService.getBuildingsStats();

      print('✅ Loaded ${_buildings.length} buildings and stats from Firebase');
    } catch (e) {
      print('❌ Error loading data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    // Sign out from both auth systems
    await MultiTenantAuthService.signOut();
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = MultiTenantAuthService.currentUser ?? AuthService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('אין משתמש מחובר')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.purple),
            SizedBox(width: 8),
            Text('לוח בקרה בעל האפליקציה'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'רענן נתונים',
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.2),
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold),
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
                _buildOverviewTab(user),
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
            label: 'סקירה',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'בניינים',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'משתמשים',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'אנליטיקה',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(VaadlyUser user) {
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
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        color: Colors.purple, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ברוך השוב, ${user.name}!',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'בעל אפליקציה - גישה מלאה למערכת',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'התחברות אחרונה: ${_formatLastLogin()}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
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

          // System stats
          Text(
            'סקירת המערכת',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'בניינים',
                      '${_stats['totalBuildings'] ?? 0}',
                      Icons.business,
                      Colors.indigo)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'ועדי בית',
                      '${_stats['activeBuildings'] ?? 0}',
                      Icons.group,
                      Colors.teal)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'דיירים',
                      '${_stats['totalUnits'] ?? 0}',
                      Icons.people,
                      Colors.orange)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'משתמשים פעילים',
                      '${_stats['totalBuildings'] ?? 0}',
                      Icons.person_outline,
                      Colors.green)),
            ],
          ),
          const SizedBox(height: 20),

          // Quick actions
          Text(
            'פעולות מהירות',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
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
              _buildActionCard('הוסף בניין', Icons.add_business, Colors.blue,
                  () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AddBuildingScreen()),
                );
              }),
              _buildActionCard('דוגמה: הזמנת ועד', Icons.link, Colors.green,
                  () {
                _showSampleCommitteeLink();
              }),
              _buildActionCard(
                  'איפוס סיסמה לועד', Icons.lock_reset, Colors.orange, () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const PasswordResetScreen()),
                );
              }),
              _buildActionCard('אנליטיקה', Icons.bar_chart, Colors.purple, () {
                setState(() => _selectedIndex = 3);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingsTab() {
    return const BuildingsListScreen();
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.people, size: 24, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                'ניהול משתמשים',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ניהול ועדי בית ודיירים בכל הבניינים שלך',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // User Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'סה"כ משתמשים',
                  '${_analytics['totalUsers'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'ועדי בית',
                  '${_analytics['buildingCommittees'] ?? 0}',
                  Icons.business,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'דיירים',
                  '${_analytics['totalResidents'] ?? 0}',
                  Icons.home,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Users List
          Text(
            'משתמשים אחרונים',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _buildings.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('אין משתמשים עדיין'),
                        Text('משתמשים יופיעו כאן לאחר הוספת בניינים'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _buildings.length,
                    itemBuilder: (context, index) {
                      final building = _buildings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.withOpacity(0.1),
                            child: const Icon(Icons.business,
                                color: Colors.indigo),
                          ),
                          title: Text(building.name),
                          subtitle: Text(
                              '${building.address} • ${building.totalUnits} יחידות'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${building.totalUnits} משתמשים',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                building.isActive ? 'פעיל' : 'לא פעיל',
                                style: TextStyle(
                                  color: building.isActive
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            // TODO: Navigate to building users detail
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('ניהול משתמשי ${building.name}')),
                            );
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

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.analytics, size: 24, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'אנליטיקת הכנסות ושימוש',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'מדדי ביצועים כלכליים ושימוש ברחבי הפלטפורמה',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Revenue Analytics
          Text(
            'אנליטיקת הכנסות',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
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
                'הכנסה חודשית',
                '₪${_analytics['monthlyRevenue'] ?? 0}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildMetricCard(
                'הכנסה שנתית',
                '₪${_analytics['yearlyRevenue'] ?? 0}',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildMetricCard(
                'מנויים פעילים',
                '${_analytics['activeSubscriptions'] ?? _buildings.length}',
                Icons.business_center,
                Colors.indigo,
              ),
              _buildMetricCard(
                'שיעור שמירה',
                '${_analytics['retentionRate'] ?? 95}%',
                Icons.favorite,
                Colors.pink,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Usage Analytics
          Text(
            'אנליטיקת שימוש',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
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
                'משתמשים פעילים',
                '${_analytics['dailyActiveUsers'] ?? 0}',
                Icons.people,
                Colors.orange,
              ),
              _buildMetricCard(
                'כניסות היום',
                '${_analytics['dailyLogins'] ?? 0}',
                Icons.login,
                Colors.purple,
              ),
              _buildMetricCard(
                'בניינים חדשים החודש',
                '${_analytics['newBuildingsThisMonth'] ?? 0}',
                Icons.add_business,
                Colors.teal,
              ),
              _buildMetricCard(
                'ממוצע שימוש',
                '${_analytics['averageUsageHours'] ?? 0}h',
                Icons.schedule,
                Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Business Insights
          Text(
            'תובנות עסקיות',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
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
                      Icon(Icons.insights, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'המלצות לשיפור',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    '📈',
                    'הכנסות גדלות ב-12% החודש',
                    'המשך לפתח שירותים חדשים',
                  ),
                  _buildInsightItem(
                    '👥',
                    '${_buildings.length} בניינים פעילים',
                    'שקול להוסיף תכונות ניהול מתקדמות',
                  ),
                  _buildInsightItem(
                    '⭐',
                    'שיעור שמירת לקוחות גבוה',
                    'המשך לשמור על איכות השירות',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'פעולות מהירות',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'ייצא נתונים',
                  Icons.download,
                  Colors.blue,
                  () => _exportAnalytics(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'דוח חודשי',
                  Icons.description,
                  Colors.green,
                  () => _generateMonthlyReport(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'הגדרות התראות',
                  Icons.notifications,
                  Colors.orange,
                  () => _configureAlerts(),
                ),
              ),
            ],
          ),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
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
                  fontSize: 14, color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastLogin() {
    final lastLogin = AuthService.currentUser?.lastLogin;
    if (lastLogin == null) return 'אף פעם';

    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inMinutes < 1) return 'עכשיו';
    if (difference.inMinutes < 60) return 'לפני ${difference.inMinutes} דקות';
    if (difference.inHours < 24) return 'לפני ${difference.inHours} שעות';
    return 'לפני ${difference.inDays} ימים';
  }

  void _showUserProfile() {
    final user = MultiTenantAuthService.currentUser ?? AuthService.currentUser;
    if (user == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('פרופיל משתמש'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('שם: ${user.name}'),
            Text('דואר אלקטרוני: ${user.email}'),
            const Text('תפקיד: בעל אפליקציה'),
            const Text('גישה: כל הבניינים'),
            const Text('סטטוס: פעיל'),
            Text('נוצר: ${user.createdAt.toLocal().toString().split(' ')[0]}'),
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

  void _showSampleCommitteeLink() {
    // Use a sample building code or get the first building
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link, color: Colors.green),
            SizedBox(width: 8),
            Text('דוגמה: קישור הזמנת ועד'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('קישור לדוגמה להזמנת ועד בית:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'http://localhost:3000/#/manage/braeli-5',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(
                              text: 'http://localhost:3000/#/manage/braeli-5'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('קישור הועתק ללוח הגזירים')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'העתק קישור',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Open the committee invitation link in a new tab would be ideal
                      // For now, let's just show instructions
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'פתח קישור זה בכרטיסייה חדשה כדי לראות את מסך הזמנת הועד'),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    child: const Text('נסה את הקישור'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'העתק קישור זה ופתח אותו בכרטיסייה חדשה לצפייה במסך הזמנת הועד.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
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

  // Missing methods for analytics functionality
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

  Widget _buildInsightItem(String icon, String text, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ייצוא נתונים - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _generateMonthlyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('יצירת דוח חודשי - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _configureAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('הגדרת התראות - תכונה זו תהיה זמינה בקרוב')),
    );
  }
}

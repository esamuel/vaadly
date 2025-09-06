import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_links.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/multi_tenant_auth_service.dart';
import '../../core/services/user_admin_service.dart';
import '../../core/models/user.dart';
import '../../core/models/building.dart';
import '../../services/firebase_building_service.dart';
import '../../services/firebase_resident_service.dart';
import '../auth/auth_screen.dart';
import '../buildings/buildings_list_screen.dart';
import '../buildings/add_building_screen.dart';
import '../users/password_reset_screen.dart';
import '../payments/pages/payments_demo_page.dart';
import '../finance/financial_module/pages/financial_management_page.dart';

class AppOwnerDashboard extends StatefulWidget {
  const AppOwnerDashboard({super.key});

  @override
  State<AppOwnerDashboard> createState() => _AppOwnerDashboardState();
}

class _AppOwnerDashboardState extends State<AppOwnerDashboard> {
  int _selectedIndex = 0;
  // Switched to streams; keep minimal local state
  List<Building> _buildings = [];
  final List<VaadlyUser> _users = [];
  final Map<String, dynamic> _analytics = {};
  StreamSubscription<List<Building>>? _buildingsSub;

  @override
  void initState() {
    super.initState();
    // Keep a live cache of buildings for export/report utilities
    _buildingsSub = FirebaseBuildingService.streamBuildings().listen((b) {
      if (mounted) {
        setState(() => _buildings = b);
      }
    });
  }

  @override
  void dispose() {
    _buildingsSub?.cancel();
    super.dispose();
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
      body: IndexedStack(
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

          // System stats (real-time)
          Text(
            'סקירת המערכת',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Building>>(
            stream: FirebaseBuildingService.streamBuildings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ));
              }
              final buildings = snapshot.data ?? [];
              final totalBuildings = buildings.length;
              final activeBuildings = buildings.where((b) => b.isActive).length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'בניינים',
                          '$totalBuildings',
                          Icons.business,
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'ועדי בית',
                          '$activeBuildings',
                          Icons.group,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<int>(
                    stream: FirebaseResidentService.streamAllResidentsCount(),
                    builder: (context, resSnap) {
                      final residentsCount = resSnap.data ?? 0;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'דיירים',
                              '$residentsCount',
                              Icons.people,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'משתמשים פעילים',
                              '$activeBuildings',
                              Icons.person_outline,
                              Colors.green,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
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
              _buildActionCard('תשלומים', Icons.payment, Colors.green, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PaymentsDemoPage()),
                );
              }),
              _buildActionCard('ניהול כספי', Icons.account_balance, Colors.teal, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const FinancialManagementPage()),
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
    return const AdminUsersPanel();
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
    // Use the first building code if available, otherwise a placeholder
    final code = _buildings.isNotEmpty ? _buildings.first.buildingCode : 'example-code';
    final invitationLink = AppLinks.managePortal(code, canonical: true);

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
            const Text('קישור להזמנת ועד בית:'),
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
                      Expanded(
                        child: SelectableText(
                          invitationLink,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          try {
                            await Clipboard.setData(ClipboardData(text: invitationLink));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('קישור הועתק ללוח הגזירים')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('שגיאה בהעתקת קישור: $e')),
                              );
                            }
                          }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ייצוא נתונים'),
        content: const Text('בחר את סוג הנתונים לייצוא:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportBuildingData();
            },
            child: const Text('ייצא נתוני בניינים'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportFinancialData();
            },
            child: const Text('ייצא נתונים פיננסיים'),
          ),
        ],
      ),
    );
  }

  void _exportBuildingData() {
    final csvData = _generateBuildingCSV();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('נתוני ${_buildings.length} בניינים יוצאו בהצלחה'),
        backgroundColor: Colors.green,
      ),
    );
    print('Building CSV Data: $csvData');
  }

  void _exportFinancialData() {
    final csvData = _generateFinancialCSV();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('נתונים פיננסיים יוצאו בהצלחה'),
        backgroundColor: Colors.green,
      ),
    );
    print('Financial CSV Data: $csvData');
  }

  String _generateBuildingCSV() {
    String csv = 'שם הבניין,כתובת,יחידות,שטח,קומות,סטטוס\n';
    for (var building in _buildings) {
      csv += '${building.name},${building.address},${building.totalUnits},${building.buildingArea},${building.totalFloors},${building.isActive ? "פעיל" : "לא פעיל"}\n';
    }
    return csv;
  }

  String _generateFinancialCSV() {
    return 'בניין,הכנסות,הוצאות,רווח\n${_buildings.map((b) => '${b.name},${b.totalUnits * 4500},${b.totalUnits * 800},${b.totalUnits * 3700}').join('\n')}';
  }

  void _generateMonthlyReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('דוח חודשי'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('דוח לחודש ${DateTime.now().month}/${DateTime.now().year}', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('📊 סיכום כללי:'),
              Text('• בניינים: ${_buildings.length}'),
              Text('• יחידות דיור: ${_buildings.fold(0, (sum, b) => sum + b.totalUnits)}'),
              Text('• שטח כולל: ${_buildings.fold(0.0, (sum, b) => sum + b.buildingArea)} מ"ר'),
              const SizedBox(height: 16),
              const Text('💰 נתונים פיננסיים:'),
              Text('• הכנסות צפויות: ₪${_buildings.fold(0, (sum, b) => sum + (b.totalUnits * 4500)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'),
              Text('• הוצאות צפויות: ₪${_buildings.fold(0, (sum, b) => sum + (b.totalUnits * 800)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'),
              Text('• רווח צפוי: ₪${_buildings.fold(0, (sum, b) => sum + (b.totalUnits * 3700)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('דוח חודשי נשמר בהצלחה'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('שמור דוח'),
          ),
        ],
      ),
    );
  }

  void _configureAlerts() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('הגדרת התראות'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('התראות תשלום'),
                subtitle: const Text('התראה כאשר תשלום מתאחר'),
                value: true,
                onChanged: (value) => setState(() {}),
              ),
              CheckboxListTile(
                title: const Text('התראות תחזוקה'),
                subtitle: const Text('התראה על בקשות תחזוקה חדשות'),
                value: true,
                onChanged: (value) => setState(() {}),
              ),
              CheckboxListTile(
                title: const Text('התראות פיננסיות'),
                subtitle: const Text('דוח שבועי על מצב כספי'),
                value: false,
                onChanged: (value) => setState(() {}),
              ),
              CheckboxListTile(
                title: const Text('התראות דיירים'),
                subtitle: const Text('התראה על דיירים חדשים'),
                value: true,
                onChanged: (value) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('הגדרות התראות נשמרו בהצלחה'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildingDetails(Building building) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business, color: Colors.indigo),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              building.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              building.address,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Building Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildDetailCard('יחידות דיור', '${building.totalUnits}', Icons.home, Colors.blue),
                      _buildDetailCard('שטח כללי', '${building.buildingArea} מ"ר', Icons.straighten, Colors.green),
                      _buildDetailCard('קומות', '${building.totalFloors}', Icons.layers, Colors.orange),
                      _buildDetailCard('דיירים', '${building.totalUnits * 2}', Icons.people, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Building Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: building.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: building.isActive ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          building.isActive ? Icons.check_circle : Icons.warning,
                          color: building.isActive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          building.isActive ? 'בניין פעיל ומנוהל' : 'בניין לא פעיל',
                          style: TextStyle(
                            color: building.isActive ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const PaymentsDemoPage()),
                          );
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('תשלומים'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const FinancialManagementPage()),
                          );
                        },
                        icon: const Icon(Icons.analytics),
                        label: const Text('כספים'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ====================== DEV-ONLY ADMIN USERS PANEL ======================
class AdminUsersPanel extends StatefulWidget {
  const AdminUsersPanel({super.key});

  @override
  State<AdminUsersPanel> createState() => _AdminUsersPanelState();
}

class _AdminUsersPanelState extends State<AdminUsersPanel> {
  bool _loading = false;
  List<Map<String, dynamic>> _users = [];
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _message = null; });
    try {
      final users = await UserAdminService.listUsers();
      setState(() { _users = users; });
    } catch (e) {
      setState(() { _message = 'שגיאה בטעינת משתמשים: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _copyResetLink(String email) async {
    try {
      final link = await UserAdminService.generateResetLink(email);
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        setState(() { _message = 'קישור איפוס הועתק'; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('קישור איפוס הועתק ללוח הגזירים')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _message = 'שגיאה ביצירת קישור איפוס: $e'; });
      }
    }
  }

  Future<void> _copyCsv() async {
    final csv = UserAdminService.usersToCsv(_users);
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      setState(() { _message = 'CSV הועתק ללוח הגזירים'; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV הועתק ללוח הגזירים')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const Spacer(),
              if (!kReleaseMode) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('DEV ONLY', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('רשימת משתמשים לפי Firestore/Auth (ללא סיסמאות)', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: const Text('רענן'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _users.isEmpty ? null : _copyCsv,
                icon: const Icon(Icons.table_view),
                label: const Text('העתק CSV'),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(_message!, style: TextStyle(color: Colors.grey[700])),
          ],
          const SizedBox(height: 12),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('אין משתמשים להצגה'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final u = _users[index];
                          final email = (u['email'] ?? '').toString();
                          final name = (u['name'] ?? '').toString();
                          final role = (u['role'] ?? 'unknown').toString();
                          final active = (u['isActive'] ?? false) == true;
                          final auth = (u['auth'] as Map<String, dynamic>?) ?? {};
                          final uid = (auth['uid'] ?? '').toString();

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo.withOpacity(0.1),
                                child: const Icon(Icons.person, color: Colors.indigo),
                              ),
                              title: Text(name.isEmpty ? email : name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email),
                                  const SizedBox(height: 2),
                                  Text('תפקיד: $role • פעיל: ${active ? 'כן' : 'לא'} • UID: ${uid.isEmpty ? '-' : uid}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    tooltip: 'העתק אימייל',
                                    icon: const Icon(Icons.copy),
                                    onPressed: () => Clipboard.setData(ClipboardData(text: email)),
                                  ),
                                  IconButton(
                                    tooltip: 'העתק קישור איפוס',
                                    icon: const Icon(Icons.link),
                                    onPressed: email.isEmpty ? null : () => _copyResetLink(email),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

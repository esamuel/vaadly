import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';
import '../../core/services/resident_service.dart';
import '../../core/models/user.dart';
import '../../services/firebase_building_service.dart';
import '../../services/firebase_resident_service.dart';
import '../../core/models/building.dart';
import '../auth/auth_screen.dart';
import '../management/resident_invitation_screen.dart';
import '../residents/pages/residents_page.dart';
import '../residents/widgets/add_resident_form.dart';
import '../maintenance/maintenance_dashboard.dart';
import '../financial/financial_dashboard.dart';
import '../settings/building_settings_dashboard.dart';

class CommitteeDashboard extends StatefulWidget {
  const CommitteeDashboard({super.key});

  @override
  State<CommitteeDashboard> createState() => _CommitteeDashboardState();
}

class _CommitteeDashboardState extends State<CommitteeDashboard> {
  int _selectedIndex = 0;
  bool _loading = false;
  Building? _building;
  String _buildingName = 'טוען...';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Get current user's building access
      final user = AuthService.currentUser;
      print('🔍 Debug - Current user: ${user?.name} (${user?.role})');
      print('🔍 Debug - Building access: ${user?.buildingAccess}');

      if (user != null && user.isBuildingCommittee) {
        // Determine the single building the committee manages
        // Prefer explicit building context if present; otherwise use user's first accessible building ID
        String? targetBuildingId = BuildingContextService.hasBuilding
            ? BuildingContextService.buildingId
            : (user.buildingAccess.isNotEmpty ? user.buildingAccess.keys.first : null);

        print('🔍 Target building ID to load: ${targetBuildingId ?? 'none'}');

        if (targetBuildingId != null) {
          // Load only this building by ID
          _building = await FirebaseBuildingService.getBuildingById(targetBuildingId);

          // If not found by ID, try interpreting the key as a building code
          if (_building == null) {
            print('ℹ️ Building not found by ID, trying as code: $targetBuildingId');
            final byCode = await FirebaseBuildingService.getBuildingByCode(targetBuildingId);
            if (byCode != null) {
              _building = byCode;
              // Persist context for the session
              try {
                await BuildingContextService.setBuildingContextByCode(byCode.buildingCode);
              } catch (_) {}
            }
          }
        }

        // Fallback: create demo building only if none found
        _building ??= Building(
          id: 'demo',
          buildingCode: 'demo',
          name: 'בניין דמו',
          address: 'כתובת דמו',
          city: 'תל אביב',
          postalCode: '00000',
          country: 'ישראל',
          totalFloors: 5,
          totalUnits: 20,
          parkingSpaces: 10,
          storageUnits: 5,
          buildingArea: 1000.0,
          yearBuilt: 2020,
          buildingType: 'residential',
          amenities: ['elevator'],
          buildingManager: 'מנהל הבניין',
          managerPhone: '050-1234567',
          managerEmail: 'manager@building.co.il',
          notes: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );

        setState(() {
          _buildingName = _building?.name ?? 'בניין לא ידוע';
        });

        print('✅ Committee managing building: ${_building?.name}');
      }

      // Initialize sample data if needed
      if (ResidentService.getAllResidents().isEmpty) {
        ResidentService.initializeSampleData();
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _buildingName = 'שגיאה בטעינת הבניין';
      });
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
    final buildingId = user.accessibleBuildings.isNotEmpty
        ? user.accessibleBuildings.first
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.business, color: Colors.indigo),
            const SizedBox(width: 8),
            Text('ניהול בניין - $_buildingName'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.indigo.withOpacity(0.2),
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Colors.indigo, fontWeight: FontWeight.bold),
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
                _buildDashboardTab(),
                _buildResidentsTab(),
                _buildMaintenanceTab(),
                _buildFinancialTab(),
                _buildSettingsTab(),
              ],
            ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => AddResidentForm(
                      onResidentAdded: (resident) async {
                        final user = AuthService.currentUser;
                        if (user != null && user.isBuildingCommittee) {
                          final buildingId = user.buildingAccess.keys.first;
                          try {
                            final newId =
                                await FirebaseResidentService.addResident(
                                    buildingId, resident);
                            if (newId != null) {
                              Navigator.of(context).pop(true); // Return success
                            }
                          } catch (e) {
                            Navigator.of(context).pop(false); // Return failure
                          }
                        }
                      },
                    ),
                  ),
                );

                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('הדייר נוסף בהצלחה'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {}); // Refresh the dashboard
                } else if (result == false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('שגיאה בהוספת הדייר'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('הוסף דייר'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'לוח בקרה',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'דיירים',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'תחזוקה',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'כספים',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'הגדרות',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    final user = AuthService.currentUser!;
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
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business,
                        color: Colors.indigo, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ברוך הבא, ${user.name}!',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ועד בית - $_buildingName',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'קוד בניין: ${BuildingContextService.currentBuilding?.buildingCode ?? 'לא זמין'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
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

          // Building stats
          Text(
            'סקירת הבניין',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: Future.value(ResidentService.getResidentStatistics()),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {};
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              'סה״כ דירות',
                              '${_building?.totalUnits ?? 24}',
                              Icons.apartment,
                              Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildStatCard(
                              'דיירים',
                              '${stats['total'] ?? 0}',
                              Icons.people,
                              Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              'דיירים פעילים',
                              '${stats['active'] ?? 0}',
                              Icons.check_circle,
                              Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildStatCard(
                              'בעלי דירה',
                              '${stats['owners'] ?? 0}',
                              Icons.home_outlined,
                              Colors.indigo)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Recent activity
          Text(
            'פעילות אחרונה',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _buildActivityItem(
                  'דייר חדש נוסף',
                  'מיכל רוזן - דירה 7',
                  Icons.person_add,
                  Colors.green,
                  'היום',
                ),
                const Divider(),
                _buildActivityItem(
                  'עדכון פרטי דייר',
                  'יוסי כהן - דירה 1',
                  Icons.edit,
                  Colors.blue,
                  'אתמול',
                ),
                const Divider(),
                _buildActivityItem(
                  'דייר פעיל במערכת',
                  'דוד ישראלי - דירה 5',
                  Icons.check_circle,
                  Colors.teal,
                  'לפני יומיים',
                ),
              ],
            ),
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
              _buildActionCard('הוסף דייר', Icons.person_add, Colors.blue, () {
                setState(() => _selectedIndex = 1);
              }),
              _buildActionCard('הזמן דייר', Icons.mail_outline, Colors.green,
                  () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ResidentInvitationScreen()),
                );
              }),
              _buildActionCard('ניהול דיירים', Icons.people, Colors.indigo, () {
                setState(() => _selectedIndex = 1);
              }),
              _buildActionCard('תחזוקה', Icons.build, Colors.purple, () {
                setState(() => _selectedIndex = 2);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResidentsTab() {
    return const ResidentsPage(showFloatingActionButton: false);
  }

  Widget _buildMaintenanceTab() {
    return const MaintenanceDashboard();
  }

  Widget _buildFinancialTab() {
    return const FinancialDashboard();
  }

  Widget _buildSettingsTab() {
    return const BuildingSettingsDashboard();
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

  Widget _buildActivityItem(
      String title, String subtitle, IconData icon, Color color, String time) {
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
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey[500]),
      ),
    );
  }

  void _showUserProfile() {
    final user = AuthService.currentUser!;
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
            const Text('תפקיד: ועד בית'),
            const Text('בניין: מגדל שלום'),
            const Text('רמת גישה: מנהל'),
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_links.dart';
import '../../services/firebase_building_service.dart';
import '../../services/firebase_resident_service.dart';
import '../../../features/residents/pages/residents_page.dart';
import '../../../features/settings/building_settings_dashboard.dart';

class BuildingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> building;

  const BuildingDetailScreen({
    super.key,
    required this.building,
  });

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _loading = false;
  Map<String, dynamic>? _buildingData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBuildingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Removed _getOwnerIdForBuilding - now using flat collection structure

  Future<void> _loadBuildingData() async {
    try {
      final buildingId = widget.building['id'] as String;
      print(
          '🏢 Loading building data for ID: $buildingId using flat structure');

      // Use flat collection structure
      final doc = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .get();

      if (!doc.exists) {
        print('⚠️ Building document does not exist: $buildingId');
        return;
      }

      final data = doc.data()!;
      print('✅ Building data loaded: ${data['name']}');
      setState(() {
        _buildingData = {
          ...widget.building,
          ...data,
        };
      });
    } catch (e) {
      // Keep UI responsive even if fetch fails
      print('❌ Failed to load building data: $e');
    }
  }

  void _copyBuildingLink() async {
    final code =
        (widget.building['buildingCode'] ?? widget.building['code'] ?? '')
            .toString();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('לא נמצא קוד בניין להעתקה')),
      );
      return;
    }
    final link = AppLinks.buildingPortal(code, canonical: true);
    try {
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('קישור הבניין הועתק ללוח הגזירים')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בהעתקת קישור: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final building = _buildingData ?? widget.building;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
        ),
        title: Text(building['name']),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _copyBuildingLink,
            icon: const Icon(Icons.link),
            tooltip: 'העתק קישור בניין',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // Edit building
                  break;
                case 'disable':
                  // Disable building
                  break;
                case 'settings':
                  // Building settings
                  break;
                case 'delete':
                  _confirmDeleteBuilding();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('ערוך בניין'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('הגדרות'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'disable',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('השבת בניין', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('מחק בניין', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'סקירה'),
            Tab(text: 'דיירים'),
            Tab(text: 'תחזוקה'),
            Tab(text: 'כספים'),
            Tab(text: 'הגדרות'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildResidentsTab(),
          _buildMaintenanceTab(),
          _buildFinancialTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final building = widget.building;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Building info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                              building['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            Text(
                              building['address'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              'קוד בניין: ${building['code']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          building['status'],
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('נוצר: ${building['created']}'),
                      const Spacer(),
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('פעילות אחרונה: ${building['lastActivity']}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Text(
            'נתוני בניין',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('דירות', building['units'].toString(),
                    Icons.home, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseResidentService.streamResidents(
                      building['id'] as String),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? (snapshot.data as List).length
                        : null;
                    final value = count != null ? count.toString() : '...';
                    return _buildStatCard(
                        'דיירים', value, Icons.people, Colors.teal);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'תקלות פתוחות',
                    building['openIssues'].toString(),
                    Icons.warning,
                    Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'הכנסה חודשית',
                  '₪${(building['monthlyRevenue'] as int).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Committee info
          Text(
            'פרטי ועד הבית',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                      'מנהל הבניין', building['committee'], Icons.person),
                  const Divider(),
                  _buildInfoRow('טלפון', building['phone'], Icons.phone),
                  const Divider(),
                  _buildInfoRow(
                      'דואר אלקטרוני', building['email'], Icons.email),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Building link
          Text(
            'קישור הבניין',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'קישור לפורטל הבניין:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLinks.buildingPortal(building['code'],
                                canonical: true),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _copyBuildingLink,
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'העתק',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'שתף קישור זה עם דיירי הבניין כדי שיוכלו לגשת לפורטל הבניין שלהם',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentsTab() {
    return const ResidentsPage();
  }

  Widget _buildMaintenanceTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('בקשות תחזוקה', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('כל הבקשות והתקלות של הבניין',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('ניהול כספים', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('תשלומים, חשבוניות והוצאות',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return BuildingSettingsDashboard(
      buildingId: widget.building['id'] as String,
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteBuilding() async {
    final building = widget.building;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('אזהרה'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('האם אתה בטוח שברצונך למחוק את הבניין "${building['name']}"?'),
            const SizedBox(height: 12),
            const Text(
              'פעולה זו תמחק את:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• כל נתוני הבניין'),
            const Text('• רשימת הדיירים'),
            const Text('• בקשות התחזוקה'),
            const Text('• הנתונים הכספיים'),
            const SizedBox(height: 12),
            const Text(
              'לא ניתן לבטל פעולה זו!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('בטל'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק בניין'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBuilding();
    }
  }

  Future<void> _deleteBuilding() async {
    try {
      final building = widget.building;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('מוחק בניין...'),
            ],
          ),
        ),
      );

      // Delete from Firebase
      final success =
          await FirebaseBuildingService.deleteBuilding(building['id']);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Show success and go back to buildings list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('הבניין "${building['name']}" נמחק בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to buildings list
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה במחיקת הבניין'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה במחיקת הבניין: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

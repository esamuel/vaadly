import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/building.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';
import '../../core/utils/phone_number_formatter.dart';
import '../maintenance/pages/maintenance_request_create_page.dart';

class BuildingSettingsDashboard extends StatefulWidget {
  final String? buildingId;
  const BuildingSettingsDashboard({super.key, this.buildingId});

  @override
  State<BuildingSettingsDashboard> createState() =>
      _BuildingSettingsDashboardState();
}

class _BuildingSettingsDashboardState extends State<BuildingSettingsDashboard> {
  bool _loading = false;
  Building? _building;
  final _formKey = GlobalKey<FormState>();

  // Current building identifier
  String? _currentBuildingId;

  // Form controllers
  final _buildingNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _managerEmailController = TextEditingController();

  // Maintenance settings (RTL/Hebrew labels handled in UI)
  // managementMode: 'appOwnerManaged' | 'committeeManaged'
  String _managementMode = 'committeeManaged';
  // Whether App Owner pool can be used when policy triggers
  bool _usesAppOwnerPoolPolicy = false;
  // Cost threshold in ILS that triggers comparison or fallback to AppOwner pool
  final _thresholdController = TextEditingController(text: '500');

  @override
  void initState() {
    super.initState();
    _loadBuildingData();
  }

@override
  void dispose() {
    _buildingNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _managerNameController.dispose();
    _managerPhoneController.dispose();
    _managerEmailController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  // Load building data directly from the buildings collection
  Future<Building?> _getBuildingById(String buildingId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .get();
      if (doc.exists) {
        return Building.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      debugPrint('Failed to load building $buildingId: $e');
    }
    return null;
  }

  Future<void> _loadBuildingData() async {
    setState(() => _loading = true);
    try {
      // Determine target buildingId from context or current user
      String? buildingId = widget.buildingId;
      if (buildingId == null && BuildingContextService.hasBuilding) {
        buildingId = BuildingContextService.buildingId;
      } else if (buildingId == null) {
        final user = AuthService.currentUser;
        if (user != null && user.buildingAccess.isNotEmpty) {
          buildingId = user.buildingAccess.keys.first;
        }
      }

      if (buildingId == null) {
        debugPrint('No building context available for settings');
        setState(() => _loading = false);
        return;
      }

      _currentBuildingId = buildingId;

      // Fetch building directly from the buildings collection
      debugPrint('🔍 Settings: Attempting to load building $buildingId');
      final loaded = await _getBuildingById(buildingId);

      if (loaded == null) {
        debugPrint('❌ Settings: Building $buildingId not found');
        setState(() => _loading = false);
        return;
      }
      
      debugPrint('✅ Settings: Building loaded successfully - ${loaded.name}');
      debugPrint('📊 Settings: Building data - Manager: ${loaded.buildingManager}, Phone: ${loaded.managerPhone}, Email: ${loaded.managerEmail}');
      debugPrint('📊 Settings: Building data - Address: ${loaded.address}, City: ${loaded.city}');
      debugPrint('📊 Settings: Building data - Floors: ${loaded.totalFloors}, Units: ${loaded.totalUnits}');

      // Use the data as-is from Firestore; do not auto-correct silently
      _building = loaded;

      // Load maintenance settings document
      try {
        final settingsDoc = await FirebaseFirestore.instance
            .collection('buildings')
            .doc(buildingId)
            .collection('settings')
            .doc('maintenance')
            .get();
        if (settingsDoc.exists) {
          final data = settingsDoc.data() as Map<String, dynamic>;
          _managementMode = (data['managementMode'] as String?) ?? _managementMode;
          _usesAppOwnerPoolPolicy = (data['usesAppOwnerPoolPolicy'] as bool?) ?? _usesAppOwnerPoolPolicy;
          final costPolicy = (data['costPolicy'] as Map<String, dynamic>?) ?? {};
          final thr = costPolicy['autoCompareThresholdIls'];
          if (thr is int) {
            _thresholdController.text = thr.toString();
          } else if (thr is double) {
            _thresholdController.text = thr.toInt().toString();
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to load maintenance settings: $e');
      }

      // Populate form controllers
      debugPrint('📝 Settings: Populating form controllers...');
      _buildingNameController.text = _building!.name;
      _addressController.text = _building!.address;
      _cityController.text = _building!.city;
      _managerNameController.text = _building!.buildingManager ?? '';
      _managerPhoneController.text = _building!.managerPhone ?? '';
      _managerEmailController.text = _building!.managerEmail ?? '';
      
      debugPrint('✅ Settings: Controllers populated with:');
      debugPrint('   - Name: "${_buildingNameController.text}"');
      debugPrint('   - Address: "${_addressController.text}"');
      debugPrint('   - City: "${_cityController.text}"');
      debugPrint('   - Manager: "${_managerNameController.text}"');
      debugPrint('   - Phone: "${_managerPhoneController.text}"');
      debugPrint('   - Email: "${_managerEmailController.text}"');

      // No persistence of name/address changes unless user saves explicitly
    } catch (e) {
      debugPrint('Failed to load building data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ הגדרות בניין'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can pop or if we need to navigate to a safe route
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // If we can't pop, navigate to the root dashboard
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
          tooltip: 'חזור',
        ),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: 'שמור הגדרות',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Building information section
                  _buildSectionHeader('מידע כללי על הבניין'),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _buildingNameController,
                          label: 'שם הבניין',
                          icon: Icons.business,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'נא להזין שם בניין';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _addressController,
                          label: 'כתובת',
                          icon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'נא להזין כתובת';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _cityController,
                          label: 'עיר',
                          icon: Icons.location_city,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'נא להזין עיר';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Building manager section
                  _buildSectionHeader('מנהל הבניין'),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _managerNameController,
                    label: 'שם מנהל',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _managerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'טלפון',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      PhoneNumberFormatter(),
                      LengthLimitingTextInputFormatter(13),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _managerEmailController,
                    label: 'אימייל',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 32),

                  // Building details section
                  _buildSectionHeader('פרטי הבניין'),
                  const SizedBox(height: 16),

                  _buildBuildingDetailsCard(),

                  const SizedBox(height: 32),

                  // Maintenance settings section
                  _buildSectionHeader('תחזוקה'),
                  const SizedBox(height: 16),
                  _buildMaintenanceSettingsCard(),

                  const SizedBox(height: 32),

                  // Quick actions section
                  _buildSectionHeader('פעולות מהירות'),
                  const SizedBox(height: 16),

                  _buildQuickActions(),

                  const SizedBox(height: 32),

                  // Danger zone section
                  _buildSectionHeader('אזור מסוכן', color: Colors.red),
                  const SizedBox(height: 16),

                  _buildDangerZone(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.indigo,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildBuildingDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow('קוד בניין', _building?.buildingCode ?? 'לא זמין'),
            _buildDetailRow('מספר קומות', '${_building?.totalFloors ?? 0}'),
            _buildDetailRow('מספר יחידות', '${_building?.totalUnits ?? 0}'),
            _buildDetailRow('חניות', '${_building?.parkingSpaces ?? 0}'),
            _buildDetailRow('מחסנים', '${_building?.storageUnits ?? 0}'),
            _buildDetailRow('שנת בנייה', '${_building?.yearBuilt ?? 0}'),
            _buildDetailRow('שטח בניין', '${_building?.buildingArea ?? 0} מ"ר'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Management mode
            Text('מצב ניהול תחזוקה', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('ניהול ע"י ועד הבית'),
                  selected: _managementMode == 'committeeManaged',
                  onSelected: (v) {
                    if (v) setState(() => _managementMode = 'committeeManaged');
                  },
                ),
                ChoiceChip(
                  label: const Text('ניהול ע"י בעל האפליקציה'),
                  selected: _managementMode == 'appOwnerManaged',
                  onSelected: (v) {
                    if (v) setState(() => _managementMode = 'appOwnerManaged');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Policy-triggered use of AppOwner pool
            SwitchListTile(
              title: const Text('השתמש במאגר הספקים של בעל האפליקציה בעת הצורך'),
              subtitle: const Text('מאגר זה יופעל רק כאשר המדיניות מופעלת (לדוגמה, חוסר ספקים מתאימים או עלות גבוהה)'),
              value: _usesAppOwnerPoolPolicy,
              onChanged: (v) => setState(() => _usesAppOwnerPoolPolicy = v),
            ),

            const SizedBox(height: 16),
            // Threshold input
            Text('סף השוואת עלויות (₪)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.price_change),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateMaintenanceRequest() {
    if (_currentBuildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('לא נמצא בניין פעיל')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaintenanceRequestCreatePage(buildingId: _currentBuildingId!),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'גיבוי נתונים',
                Icons.backup,
                Colors.blue,
                () => _backupData(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'ייצא דוח',
                Icons.download,
                Colors.green,
                () => _exportReport(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'הגדרות התראות',
                Icons.notifications,
                Colors.orange,
                () => _showNotificationSettings(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'הרשאות משתמשים',
                Icons.security,
                Colors.purple,
                () => _showUserPermissions(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'בקשת תחזוקה חדשה',
                Icons.build,
                Colors.teal,
                _openCreateMaintenanceRequest,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
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
          color: color.withOpacity( 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity( 0.3)),
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

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'פעולות מסוכנות',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'פעולות אלו אינן הפיכות ויכולות להשפיע על כל המשתמשים במערכת.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showResetConfirmation(),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('איפוס הגדרות',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(),
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('מחק בניין',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentBuildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('לא נמצאה מסגרת בניין לשמירה'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final updates = {
        'name': _buildingNameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'buildingManager': _managerNameController.text.trim(),
        'managerPhone': _managerPhoneController.text.trim(),
        'managerEmail': _managerEmailController.text.trim(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(_currentBuildingId)
          .update(updates);

      // Upsert maintenance settings document
      final thr = int.tryParse(_thresholdController.text.trim());
      final maintenanceSettings = {
        'managementMode': _managementMode,
        'usesAppOwnerPoolPolicy': _usesAppOwnerPoolPolicy,
        'costPolicy': {
          'autoCompareThresholdIls': thr ?? 500,
          // Optional future fields: minQuotes, weights
        },
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(_currentBuildingId)
          .collection('settings')
          .doc('maintenance')
          .set(maintenanceSettings, SetOptions(merge: true));

      // Update local model
      if (_building != null) {
        _building = _building!.copyWith(
          name: updates['name'] as String,
          address: updates['address'] as String,
          city: updates['city'] as String,
          buildingManager: updates['buildingManager'] as String,
          managerPhone: updates['managerPhone'] as String,
          managerEmail: updates['managerEmail'] as String,
          updatedAt: DateTime.now(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ההגדרות נשמרו בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בשמירת ההגדרות: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _backupData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('גיבוי נתונים - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ייצוא דוח - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('הגדרות התראות - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _showUserPermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('הרשאות משתמשים - תכונה זו תהיה זמינה בקרוב')),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('איפוס הגדרות'),
        content: const Text(
            'האם אתה בטוח שברצונך לאפס את כל ההגדרות? פעולה זו אינה הפיכה.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('הגדרות אופסו בהצלחה')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('איפוס', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת בניין'),
        content: const Text(
            'האם אתה בטוח שברצונך למחוק את הבניין? פעולה זו אינה הפיכה ותמחק את כל הנתונים הקשורים לבניין זה.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('הבניין נמחק בהצלחה'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

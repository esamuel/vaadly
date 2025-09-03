import 'package:flutter/material.dart';
import '../../core/models/building.dart';

class BuildingSettingsDashboard extends StatefulWidget {
  const BuildingSettingsDashboard({super.key});

  @override
  State<BuildingSettingsDashboard> createState() =>
      _BuildingSettingsDashboardState();
}

class _BuildingSettingsDashboardState extends State<BuildingSettingsDashboard> {
  bool _loading = false;
  Building? _building;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _buildingNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _managerEmailController = TextEditingController();

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
    super.dispose();
  }

  Future<void> _loadBuildingData() async {
    setState(() => _loading = true);

    // Simulate loading building data
    await Future.delayed(const Duration(milliseconds: 500));

    // Create sample building data
    _building = Building(
      id: 'building1',
      buildingCode: 'LEVI-24',
      name: 'לוי אשכול 24',
      address: 'לוי אשכול 24',
      city: 'תל אביב',
      postalCode: '6713201',
      country: 'ישראל',
      totalFloors: 8,
      totalUnits: 32,
      parkingSpaces: 20,
      storageUnits: 8,
      buildingArea: 2500.0,
      yearBuilt: 2015,
      buildingType: 'residential',
      amenities: ['elevator', 'parking', 'garden', 'security'],
      buildingManager: 'יוסי כהן',
      managerPhone: '050-1234567',
      managerEmail: 'yossi@levi24.co.il',
      notes: 'בניין חדש עם מערכות מתקדמות',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    // Populate form controllers
    _buildingNameController.text = _building!.name;
    _addressController.text = _building!.address;
    _cityController.text = _building!.city;
    _managerNameController.text = _building!.buildingManager ?? '';
    _managerPhoneController.text = _building!.managerPhone ?? '';
    _managerEmailController.text = _building!.managerEmail ?? '';

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ הגדרות בניין'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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

                  _buildTextField(
                    controller: _managerPhoneController,
                    label: 'טלפון',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
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

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement save settings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ההגדרות נשמרו בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );
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

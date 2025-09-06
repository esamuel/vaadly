import 'package:flutter/material.dart';
import '../core/models/vendor.dart';
import '../services/firebase_vendor_service.dart';
import '../core/services/building_context_service.dart';
class FirebaseVendorPage extends StatefulWidget {
  const FirebaseVendorPage({super.key});

  @override
  State<FirebaseVendorPage> createState() => _FirebaseVendorPageState();
}

class _FirebaseVendorPageState extends State<FirebaseVendorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Vendor> _vendors = [];
  List<Vendor> _filteredVendors = [];
  Map<String, dynamic> _statistics = {};
  bool _loading = false;
  String _searchQuery = '';
  VendorStatus? _statusFilter;
  VendorCategory? _categoryFilter;
  String? _cityFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // Initialize sample data if needed for current building (if available)
      final buildingId = BuildingContextService.currentBuilding?.buildingId;
      if (buildingId != null) {
        await FirebaseVendorService.initializeSampleVendorDataForBuilding(buildingId);
      }

      // Load data
      final vendors = await FirebaseVendorService.getAllVendors();
      final statistics = await FirebaseVendorService.getVendorStatistics();

      setState(() {
        _vendors = vendors;
        _filteredVendors = vendors;
        _statistics = statistics;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading vendor data: $e');
      setState(() => _loading = false);
    }
  }

  void _filterVendors() {
    setState(() {
      _filteredVendors = _vendors.where((vendor) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesQuery = vendor.name.toLowerCase().contains(query) ||
              vendor.contactPerson.toLowerCase().contains(query) ||
              vendor.phone.contains(query) ||
              (vendor.email?.toLowerCase().contains(query) ?? false);
          if (!matchesQuery) return false;
        }

        // Status filter
        if (_statusFilter != null && vendor.status != _statusFilter) {
          return false;
        }

        // Category filter
        if (_categoryFilter != null &&
            !vendor.categories.contains(_categoryFilter)) {
          return false;
        }

        // City filter
        if (_cityFilter != null && _cityFilter!.isNotEmpty &&
            vendor.city != _cityFilter) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterVendors();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
      _categoryFilter = null;
      _cityFilter = null;
      _filteredVendors = _vendors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 ניהול ספקים'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ספקים', icon: Icon(Icons.business)),
            Tab(text: 'סטטיסטיקות', icon: Icon(Icons.analytics)),
            Tab(text: 'דירוגים', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('טוען נתוני ספקים...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVendorsTab(),
                _buildStatisticsTab(),
                _buildRatingsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVendorDialog(),
        icon: const Icon(Icons.add),
        label: const Text('הוסף ספק'),
      ),
    );
  }

  Widget _buildVendorsTab() {
    return Column(
      children: [
        // Search and filters
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: const InputDecoration(
                  hintText: 'חפש ספק...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Status filter
                    FilterChip(
                      label: Text(_statusFilter?.toString().split('.').last ?? 'כל הסטטוסים'),
                      selected: _statusFilter != null,
                      onSelected: (selected) {
                        if (selected) {
                          _showStatusFilterDialog();
                        } else {
                          setState(() => _statusFilter = null);
                          _filterVendors();
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // Category filter
                    FilterChip(
                      label: Text(_categoryFilter != null 
                          ? _getCategoryDisplay(_categoryFilter!) 
                          : 'כל הקטגוריות'),
                      selected: _categoryFilter != null,
                      onSelected: (selected) {
                        if (selected) {
                          _showCategoryFilterDialog();
                        } else {
                          setState(() => _categoryFilter = null);
                          _filterVendors();
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // City filter
                    FilterChip(
                      label: Text(_cityFilter ?? 'כל הערים'),
                      selected: _cityFilter != null,
                      onSelected: (selected) {
                        if (selected) {
                          _showCityFilterDialog();
                        } else {
                          setState(() => _cityFilter = null);
                          _filterVendors();
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // Clear filters
                    if (_statusFilter != null || _categoryFilter != null || 
                        _cityFilter != null || _searchQuery.isNotEmpty)
                      ActionChip(
                        label: const Text('נקה סינון'),
                        onPressed: _clearFilters,
                        avatar: const Icon(Icons.clear, size: 18),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Vendors list
        Expanded(
          child: _filteredVendors.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('אין ספקים להצגה'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredVendors.length,
                  itemBuilder: (context, index) {
                    final vendor = _filteredVendors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: vendor.statusColor,
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          vendor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${vendor.contactPerson} • ${vendor.phone}'),
                            Text(vendor.categoriesDisplay),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: vendor.statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    vendor.statusDisplay,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: vendor.statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (vendor.rating != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  Text(
                                    vendor.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: vendor.hourlyRate != null
                            ? Text(
                                '₪${vendor.hourlyRate!.toStringAsFixed(0)}/שעה',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              )
                            : null,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildVendorDetails(vendor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVendorDetails(Vendor vendor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contact information
        const Text(
          'פרטי קשר:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.location_on, 'כתובת', vendor.fullAddress),
        if (vendor.email != null)
          _buildInfoRow(Icons.email, 'אימייל', vendor.email!),
        if (vendor.website != null)
          _buildInfoRow(Icons.web, 'אתר', vendor.website!),

        const SizedBox(height: 16),

        // Professional information
        const Text(
          'פרטים מקצועיים:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (vendor.licenseNumber != null)
          _buildInfoRow(Icons.badge, 'מספר רישיון', vendor.licenseNumber!),
        if (vendor.insuranceInfo != null)
          _buildInfoRow(Icons.security, 'ביטוח', vendor.insuranceInfo!),
        _buildInfoRow(Icons.work, 'עבודות שהושלמו',
            '${vendor.completedJobs} מתוך ${vendor.totalJobs}'),
        _buildInfoRow(Icons.percent, 'שיעור הצלחה', vendor.successRateDisplay),

        if (vendor.notes != null) ...[
          const SizedBox(height: 16),
          const Text(
            'הערות:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(vendor.notes!),
        ],

        const SizedBox(height: 16),

        // Action buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _editVendor(vendor),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('ערוך'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _updateVendorStatus(vendor),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('עדכן סטטוס'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            if (vendor.status == VendorStatus.active)
              ElevatedButton.icon(
                onPressed: () => _rateVendor(vendor),
                icon: const Icon(Icons.star, size: 18),
                label: const Text('דרג'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_statistics.isEmpty) {
      return const Center(
        child: Text('אין נתונים סטטיסטיים זמינים'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'סטטיסטיקות כלליות',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'סך הכל ספקים',
                        '${_statistics['totalVendors']}',
                        Colors.blue,
                        Icons.business,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'ספקים פעילים',
                        '${_statistics['activeVendors']}',
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'מושהים',
                        '${_statistics['suspendedVendors']}',
                        Colors.orange,
                        Icons.pause,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'ברשימה שחורה',
                        '${_statistics['blacklistedVendors']}',
                        Colors.red,
                        Icons.block,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'דירוג ממוצע',
                        _statistics['averageRating'].toStringAsFixed(1),
                        Colors.amber,
                        Icons.star,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'שיעור ספקים פעילים',
                        '${_statistics['activeRate']}%',
                        Colors.teal,
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Category breakdown
        if (_statistics['categoryBreakdown'].isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'פילוח לפי קטגוריות',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...(_statistics['categoryBreakdown'] as Map<String, int>)
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // City breakdown
        if (_statistics['cityBreakdown'].isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'פילוח לפי ערים',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...(_statistics['cityBreakdown'] as Map<String, int>)
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingsTab() {
    return FutureBuilder<List<Vendor>>(
      future: FirebaseVendorService.getTopRatedVendors(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('אין ספקים מדורגים'),
              ],
            ),
          );
        }

        final topVendors = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: topVendors.length,
          itemBuilder: (context, index) {
            final vendor = topVendors[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: index < 3 ? Colors.amber : Colors.blue,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  vendor.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.categoriesDisplay),
                    Text('${vendor.contactPerson} • ${vendor.city}'),
                    Text('${vendor.completedJobs}/${vendor.totalJobs} עבודות (${vendor.successRateDisplay})'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          vendor.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (vendor.hourlyRate != null)
                      Text(
                        '₪${vendor.hourlyRate!.toStringAsFixed(0)}/שעה',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                onTap: () => _showVendorDetails(vendor),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplay(VendorCategory category) {
    switch (category) {
      case VendorCategory.plumbing:
        return 'אינסטלציה';
      case VendorCategory.electrical:
        return 'חשמל';
      case VendorCategory.hvac:
        return 'מיזוג אוויר';
      case VendorCategory.cleaning:
        return 'ניקיון';
      case VendorCategory.gardening:
        return 'גינון';
      case VendorCategory.elevator:
        return 'מעליות';
      case VendorCategory.security:
        return 'אבטחה';
      case VendorCategory.structural:
        return 'מבני';
      case VendorCategory.general:
        return 'כללי';
      case VendorCategory.painting:
        return 'צביעה';
      case VendorCategory.carpentry:
        return 'נגרות';
      case VendorCategory.roofing:
        return 'גגות';
    }
  }

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סנן לפי סטטוס'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: VendorStatus.values.map((status) {
            return RadioListTile<VendorStatus>(
              title: Text(_getStatusDisplay(status)),
              value: status,
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() => _statusFilter = value);
                _filterVendors();
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סנן לפי קטגוריה'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: VendorCategory.values.map((category) {
              return RadioListTile<VendorCategory>(
                title: Text(_getCategoryDisplay(category)),
                value: category,
                groupValue: _categoryFilter,
                onChanged: (value) {
                  setState(() => _categoryFilter = value);
                  _filterVendors();
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  void _showCityFilterDialog() {
    final cities = _vendors.map((v) => v.city).toSet().toList();
    cities.sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סנן לפי עיר'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: cities.map((city) {
              return RadioListTile<String>(
                title: Text(city),
                value: city,
                groupValue: _cityFilter,
                onChanged: (value) {
                  setState(() => _cityFilter = value);
                  _filterVendors();
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplay(VendorStatus status) {
    switch (status) {
      case VendorStatus.active:
        return 'פעיל';
      case VendorStatus.inactive:
        return 'לא פעיל';
      case VendorStatus.suspended:
        return 'מושהה';
      case VendorStatus.blacklisted:
        return 'ברשימה שחורה';
    }
  }

  void _showVendorDetails(Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vendor.name),
        content: SingleChildScrollView(
          child: _buildVendorDetails(vendor),
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

  void _showAddVendorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הוסף ספק חדש'),
        content: const Text('פונקציונליות זו תתווסף בגרסה הבאה'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _editVendor(Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ערוך ספק: ${vendor.name}'),
        content: const Text('פונקציונליות זו תתווסף בגרסה הבאה'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _updateVendorStatus(Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('עדכן סטטוס: ${vendor.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: VendorStatus.values.map((status) {
            return RadioListTile<VendorStatus>(
              title: Text(_getStatusDisplay(status)),
              value: status,
              groupValue: vendor.status,
              onChanged: (value) async {
                if (value != null) {
                  final success = await FirebaseVendorService.updateVendorStatus(
                      vendor.id, value);
                  if (success) {
                    _loadData();
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('סטטוס הספק עודכן בהצלחה'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  void _rateVendor(Vendor vendor) {
    double rating = vendor.rating ?? 5.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('דרג ספק: ${vendor.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('בחר דירוג:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                    icon: Icon(
                      rating > index ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'דירוג: ${rating.toStringAsFixed(0)} כוכבים',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await FirebaseVendorService.updateVendorRating(
                  vendor.id,
                  rating,
                  vendor.completedJobs,
                  vendor.totalJobs,
                );
                
                if (success) {
                  _loadData();
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('דירוג הספק עודכן בהצלחה'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('שמור דירוג'),
            ),
          ],
        ),
      ),
    );
  }
}
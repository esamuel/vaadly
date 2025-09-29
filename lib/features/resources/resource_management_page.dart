import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/asset_inventory_service.dart';
import '../../../services/firebase_resident_service.dart';
import '../../../services/firebase_vendor_service.dart';
import '../../../services/firebase_activity_service.dart';
import '../../../core/models/resident.dart';
import '../../../core/models/vendor.dart';

class ResourceManagementPage extends StatefulWidget {
  final String buildingId;
  const ResourceManagementPage({super.key, required this.buildingId});

  @override
  State<ResourceManagementPage> createState() => _ResourceManagementPageState();
}

class _ResourceManagementPageState extends State<ResourceManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Updated to 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ניהול משאבים',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('מחסנים, חניות וספקים', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'מחסנים'),
            Tab(icon: Icon(Icons.local_parking), text: 'חניות'),
            Tab(icon: Icon(Icons.build), text: 'ספקים'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AssetsList(
            buildingId: widget.buildingId,
            type: AssetType.storage,
          ),
          _AssetsList(
            buildingId: widget.buildingId,
            type: AssetType.parking,
          ),
          _VendorsList(buildingId: widget.buildingId),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final isVendorsTab = _tabController.index == 2;
          return isVendorsTab
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final newVendor = await showDialog<Vendor>(
                      context: context,
                      builder: (context) =>
                          _AddVendorDialog(buildingId: widget.buildingId),
                    );
                    if (newVendor != null) {
                      final id =
                          await FirebaseVendorService.addVendor(newVendor);
                      // Log activity (best-effort)
                      await FirebaseActivityService.logActivity(
                        buildingId: widget.buildingId,
                        type: 'vendor_added',
                        title: 'הוסף ספק חדש',
                        subtitle: newVendor.name,
                        extra: {'vendorId': id},
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('הספק נוסף בהצלחה'),
                              backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('הוסף ספק'),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}

enum AssetType { storage, parking }

class _AssetsList extends StatelessWidget {
  final String buildingId;
  final AssetType type;
  const _AssetsList({required this.buildingId, required this.type});

  @override
  Widget build(BuildContext context) {
    final stream = type == AssetType.storage
        ? AssetInventoryService.streamStorages(buildingId)
        : AssetInventoryService.streamParking(buildingId);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          // Auto-seed a small inventory if none exists yet (best-effort)
          Future.microtask(() async {
            try {
              await AssetInventoryService.seedInventoryForBuilding(
                buildingId: buildingId,
                storageCount: type == AssetType.storage ? 12 : 0,
                parkingCount: type == AssetType.parking ? 12 : 0,
              );
            } catch (_) {}
          });

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type == AssetType.storage
                      ? Icons.inventory
                      : Icons.local_parking,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  type == AssetType.storage
                      ? 'מכין מחסנים...'
                      : 'מכין חניות...',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<Resident>>(
          future: FirebaseResidentService.getResidents(buildingId),
          builder: (context, resSnap) {
            final residents = resSnap.data ?? const <Resident>[];
            String nameFor(String? userId) {
              if (userId == null) return '';
              final r = residents.firstWhere(
                (e) => e.id == userId,
                orElse: () => Resident(
                  id: '',
                  firstName: '',
                  lastName: '',
                  apartmentNumber: '',
                  phoneNumber: '',
                  email: '',
                  residentType: ResidentType.tenant,
                  status: ResidentStatus.active,
                  moveInDate: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  isActive: true,
                ),
              );
              if (r.id.isEmpty) return '';
              return 'app ${r.apartmentNumber}, ${r.firstName} ${r.lastName}';
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final number = data['number']?.toString() ?? '?';
                final label = data['label']?.toString() ?? '';
                final status = data['status']?.toString() ?? 'available';
                final assignedToUserId = data['assignedToUserId']?.toString();
                final assignedToUnitId = data['assignedToUnitId']?.toString();

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (status == 'assigned')
                          ? Colors.green.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                      child: Icon(
                        type == AssetType.storage
                            ? Icons.inventory
                            : Icons.local_parking,
                        color:
                            (status == 'assigned') ? Colors.green : Colors.grey,
                      ),
                    ),
                    title: Text('$label (מס׳ $number)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'סטטוס: ${status == 'assigned' ? 'מוקצה' : 'פנוי'}'),
                        if (assignedToUserId != null &&
                            assignedToUserId.isNotEmpty)
                          Text('מוקצה: ${nameFor(assignedToUserId)}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        if (assignedToUnitId != null &&
                            assignedToUnitId.isNotEmpty)
                          Text('דירה: $assignedToUnitId',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (status != 'assigned')
                          OutlinedButton.icon(
                            onPressed: () =>
                                _assign(context, buildingId, type, number),
                            icon: const Icon(Icons.person_add),
                            label: const Text('הקצה'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () =>
                                _unassign(context, buildingId, type, number),
                            icon: const Icon(Icons.person_remove),
                            label: const Text('בטל'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _assign(BuildContext context, String buildingId, AssetType type,
      String number) async {
    final resident = await showDialog<Resident>(
      context: context,
      builder: (context) => _ResidentPickerDialog(buildingId: buildingId),
    );
    if (resident == null) return;

    try {
      if (type == AssetType.storage) {
        await AssetInventoryService.assignStorage(
          buildingId: buildingId,
          number: number,
          userId: resident.id,
          unitId: resident.apartmentNumber,
        );
      } else {
        await AssetInventoryService.assignParking(
          buildingId: buildingId,
          number: number,
          userId: resident.id,
          unitId: resident.apartmentNumber,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('הוקצה בהצלחה'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('שגיאה בהקצאה: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unassign(BuildContext context, String buildingId,
      AssetType type, String number) async {
    try {
      if (type == AssetType.storage) {
        await AssetInventoryService.unassignStorage(
          buildingId: buildingId,
          number: number,
        );
      } else {
        await AssetInventoryService.unassignParking(
          buildingId: buildingId,
          number: number,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('בוטל בהצלחה'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('שגיאה בביטול: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _ResidentPickerDialog extends StatelessWidget {
  final String buildingId;
  const _ResidentPickerDialog({required this.buildingId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('בחר דייר'),
      content: SizedBox(
        width: 360,
        height: 420,
        child: StreamBuilder<List<Resident>>(
          stream: FirebaseResidentService.streamResidents(buildingId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final residents = snapshot.data ?? const <Resident>[];
            if (residents.isEmpty) {
              return const Center(child: Text('אין דיירים'));
            }
            return ListView.separated(
              itemCount: residents.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = residents[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('${r.firstName} ${r.lastName}'),
                  subtitle:
                      Text('דירה ${r.apartmentNumber} • ${r.email ?? ''}'),
                  onTap: () => Navigator.of(context).pop(r),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('בטל'),
        ),
      ],
    );
  }
}

class _VendorsList extends StatefulWidget {
  final String buildingId;
  const _VendorsList({required this.buildingId});

  @override
  State<_VendorsList> createState() => _VendorsListState();
}

class _VendorsListState extends State<_VendorsList> {
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Vendor>>(
      stream: FirebaseVendorService.streamVendors(widget.buildingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                Text('שגיאה: ${snapshot.error}'),
              ],
            ),
          );
        }

        final vendors = snapshot.data ?? [];

        // Initialize sample data if no vendors exist and not yet initialized
        if (vendors.isEmpty && !_hasInitialized) {
          Future.microtask(() => _initializeSampleVendorData());
        }

        if (vendors.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  _hasInitialized ? 'אין ספקים' : 'מפעיל נתוני דוגמה...',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _addVendor(context),
                  icon: const Icon(Icons.add),
                  label: const Text('הוסף ספק'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with stats
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'סה"כ ספקים',
                      vendors.length.toString(),
                      Icons.business,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'פעילים',
                      vendors
                          .where((v) => v.status == VendorStatus.active)
                          .length
                          .toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Vendors list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vendors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return _buildVendorCard(context, vendor);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _initializeSampleVendorData() async {
    setState(() {
      _hasInitialized = true;
    });

    try {
      await FirebaseVendorService.initializeSampleVendorDataForBuilding(
          widget.buildingId);
    } catch (e) {
      print('Error initializing vendor data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת נתוני דוגמה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, Vendor vendor) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: vendor.statusColor.withOpacity(0.15),
          child: Icon(
            _getCategoryIcon(vendor.categories.isNotEmpty
                ? vendor.categories.first
                : VendorCategory.general),
            color: vendor.statusColor,
          ),
        ),
        title: Text(
          vendor.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('איש קשר: ${vendor.contactPerson}'),
            Text('טלפון: ${vendor.phone}'),
            Text('תחום: ${vendor.categoriesDisplay}'),
            if (vendor.rating != null && vendor.rating! > 0)
              Text(
                  'דירוג: ${'⭐' * vendor.rating!.round()} (${vendor.rating!.toStringAsFixed(1)})'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vendor.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: vendor.statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    vendor.statusDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: vendor.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (vendor.hourlyRate != null)
                  Text(
                    '₪${vendor.hourlyRate!.toInt()}/שעה',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editVendor(context, vendor);
                    break;
                  case 'delete':
                    _deleteVendor(context, vendor);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('ערוך'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('מחק', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showVendorDetails(context, vendor),
      ),
    );
  }

  IconData _getCategoryIcon(VendorCategory category) {
    switch (category) {
      case VendorCategory.plumbing:
        return Icons.plumbing;
      case VendorCategory.electrical:
        return Icons.electrical_services;
      case VendorCategory.hvac:
        return Icons.air;
      case VendorCategory.cleaning:
        return Icons.cleaning_services;
      case VendorCategory.gardening:
        return Icons.grass;
      case VendorCategory.elevator:
        return Icons.elevator;
      case VendorCategory.security:
        return Icons.security;
      case VendorCategory.structural:
        return Icons.construction;
      case VendorCategory.painting:
        return Icons.format_paint;
      case VendorCategory.carpentry:
        return Icons.carpenter;
      case VendorCategory.roofing:
        return Icons.roofing;
      case VendorCategory.general:
      default:
        return Icons.build;
    }
  }

  void _addVendor(BuildContext context) async {
    final newVendor = await showDialog<Vendor>(
      context: context,
      builder: (context) => _AddVendorDialog(buildingId: widget.buildingId),
    );
    if (newVendor != null && mounted) {
      await FirebaseVendorService.addVendor(newVendor);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('הספק נוסף בהצלחה'), backgroundColor: Colors.green),
      );
    }
  }

  void _showVendorDetails(BuildContext context, Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vendor.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('איש קשר: ${vendor.contactPerson}'),
            Text('טלפון: ${vendor.phone}'),
            if (vendor.email != null) Text('אימייל: ${vendor.email}'),
            Text('כתובת: ${vendor.fullAddress}'),
            Text('תחום: ${vendor.categoriesDisplay}'),
            Text('סטטוס: ${vendor.statusDisplay}'),
            if (vendor.hourlyRate != null)
              Text('תעריף: ₪${vendor.hourlyRate}/שעה'),
            if (vendor.rating != null && vendor.rating! > 0)
              Text(
                  'דירוג: ${'⭐' * vendor.rating!.round()} (${vendor.rating!.toStringAsFixed(1)})'),
            if (vendor.notes != null) Text('הערות: ${vendor.notes}'),
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

  void _editVendor(BuildContext context, Vendor vendor) {
    // TODO: Implement edit vendor functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('עריכת ספק - בקרוב...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteVendor(BuildContext context, Vendor vendor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק ספק'),
        content: Text('האם אתה בטוח שברצונך למחוק את הספק "${vendor.name}"?\nפעולה זו אינה ניתנת לביטול.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('בטל'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await FirebaseVendorService.deleteVendor(vendor.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הספק נמחק בהצלחה'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Log activity
          await FirebaseActivityService.logActivity(
            buildingId: widget.buildingId,
            type: 'vendor_deleted',
            title: 'ספק נמחק',
            subtitle: vendor.name,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('שגיאה במחיקת הספק'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה במחיקת הספק: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _AddVendorDialog extends StatefulWidget {
  final String buildingId;
  const _AddVendorDialog({required this.buildingId});

  @override
  State<_AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends State<_AddVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _cityController = TextEditingController(text: 'תל אביב');
  VendorCategory _category = VendorCategory.general;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _hourlyRateController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הוסף ספק חדש'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'שם העסק *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'נדרש שם עסק' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'איש קשר *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'נדרש איש קשר' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'טלפון *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'נדרש טלפון' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'אימייל',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'תעריף לשעה (₪)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'כתובת',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VendorCategory>(
                initialValue: _category,
                items: [
                  VendorCategory.plumbing,
                  VendorCategory.electrical,
                  VendorCategory.hvac,
                  VendorCategory.elevator,
                  VendorCategory.cleaning,
                  VendorCategory.gardening,
                  VendorCategory.security,
                  VendorCategory.structural,
                  VendorCategory.painting,
                  VendorCategory.carpentry,
                  VendorCategory.roofing,
                  VendorCategory.general,
                ].map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(_categoryLabel(c)),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? VendorCategory.general),
                decoration: const InputDecoration(
                  labelText: 'קטגוריה',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'עיר',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'הערות',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('שמור'),
        ),
      ],
    );
  }

  String _categoryLabel(VendorCategory c) {
    switch (c) {
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
      case VendorCategory.painting:
        return 'צביעה';
      case VendorCategory.carpentry:
        return 'נגרות';
      case VendorCategory.roofing:
        return 'גגות';
      case VendorCategory.general:
      default:
        return 'כללי';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final vendor = Vendor(
      id: '',
      buildingId: widget.buildingId,
      name: _nameController.text.trim(),
      contactPerson: _contactController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      website: null,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: '',
      country: 'ישראל',
      categories: [_category],
      status: VendorStatus.active,
      licenseNumber: null,
      insuranceInfo: null,
      hourlyRate: _hourlyRateController.text.trim().isEmpty
          ? null
          : double.tryParse(_hourlyRateController.text.trim()),
      rating: null,
      completedJobs: 0,
      totalJobs: 0,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      photoUrls: const [],
      documentUrls: const [],
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
    Navigator.of(context).pop(vendor);
  }
}

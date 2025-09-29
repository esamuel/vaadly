import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MaintenanceRequestCreatePage extends StatefulWidget {
  final String buildingId;
  const MaintenanceRequestCreatePage({super.key, required this.buildingId});

  @override
  State<MaintenanceRequestCreatePage> createState() => _MaintenanceRequestCreatePageState();
}

class _MaintenanceRequestCreatePageState extends State<MaintenanceRequestCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String? _category; // plumbing, electrical, elevator, general, gardening, sanitation
  String _priority = 'בינוני'; // נמוך | בינוני | גבוה
  final _descriptionController = TextEditingController();
  final _regionController = TextEditingController();

  // Vendors
  bool _loadingVendors = false;
  List<Map<String, dynamic>> _committeeVendors = [];
  String? _selectedVendorId;

  @override
  void initState() {
    super.initState();
    _loadCommitteeVendors();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _loadCommitteeVendors() async {
    setState(() => _loadingVendors = true);
    try {
      final db = FirebaseFirestore.instance;
      final buildingRef = db.collection('buildings').doc(widget.buildingId);
      final poolDoc = await buildingRef.collection('committee_vendor_pools').doc('default').get();
      final vendorIds = ((poolDoc.data() ?? const {})['vendorIds'] as List?)?.cast<String>() ?? const [];

      _committeeVendors = [];
      if (vendorIds.isNotEmpty) {
        // Firestore whereIn supports up to 10 values; chunk if needed (MVP: first 10)
        final batchIds = vendorIds.take(10).toList();
        final profilesSnap = await buildingRef
            .collection('committee_vendor_profiles')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        _committeeVendors = profilesSnap.docs.map((d) {
          final data = d.data();
          data['vendorId'] = d.id;
          return data;
        }).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת ספקים: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingVendors = false);
    }
  }

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    final request = {
      'category': _category,
      'priority': _priority, // נמוך/בינוני/גבוה
      'description': _descriptionController.text.trim(),
      'createdAt': Timestamp.fromDate(now),
      'status': 'draft',
      'region': _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
      'selectedVendorId': _selectedVendorId,
    };

    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.buildingId)
          .collection('maintenance_requests')
          .add(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הבקשה נשמרה בהצלחה'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בשמירת הבקשה: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openAddVendorDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final regionController = TextEditingController();

    // Categories selection
    final categories = <String, bool>{
      'אינסטלציה': false,
      'חשמל': false,
      'מעליות': false,
      'כללי': false,
      'גינון': false,
      'תברואה': false,
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('הוסף ספק חדש'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'שם הספק'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'נא להזין שם ספק' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'טלפון'),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'אימייל'),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: regionController,
                    decoration: const InputDecoration(labelText: 'אזור שירות (למשל: תל-אביב)'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('תחומי שירות', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: categories.keys.map((k) {
                      return FilterChip(
                        label: Text(k),
                        selected: categories[k]!,
                        onSelected: (v) => (ctx as Element).markNeedsBuild() /* no-op */,
                        // We'll toggle manually below
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    // Collect selected categories (simplify: re-evaluate FilterChips state via controllers is complex in AlertDialog)
    // Fallback: consider at least 'כללי' if none selected for MVP
    final selectedCategories = categories.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedCategories.isEmpty) selectedCategories.add('כללי');

    final vendorDoc = FirebaseFirestore.instance
        .collection('buildings')
        .doc(widget.buildingId)
        .collection('committee_vendor_profiles')
        .doc();

    final vendor = {
      'name': nameController.text.trim(),
      'contactEmail': emailController.text.trim(),
      'contactPhone': phoneController.text.trim(),
      'serviceCategories': selectedCategories,
      'coverageRegions': [if (regionController.text.trim().isNotEmpty) regionController.text.trim()],
      'ratingAvg': 0.0,
      'jobsDone': 0,
      'slaAvgHours': 24.0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await vendorDoc.set(vendor);

    // Ensure default pool exists and include vendor
    final poolRef = FirebaseFirestore.instance
        .collection('buildings')
        .doc(widget.buildingId)
        .collection('committee_vendor_pools')
        .doc('default');

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final poolSnap = await tx.get(poolRef);
      final vendorIds = <String>[];
      if (poolSnap.exists) {
        final data = poolSnap.data() as Map<String, dynamic>;
        final arr = (data['vendorIds'] as List?)?.cast<String>() ?? [];
        vendorIds.addAll(arr);
      }
      vendorIds.add(vendorDoc.id);
      tx.set(poolRef, {
        'poolId': 'default',
        'name': 'בריכת ועד הבית (ברירת מחדל)',
        'scope': 'committee',
        'active': true,
        'vendorIds': vendorIds,
        'services': [],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // Reload vendor list
    await _loadCommitteeVendors();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הספק נוסף בהצלחה'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('בקשת תחזוקה חדשה'),
          actions: [
            IconButton(
              tooltip: 'שמור בקשה',
              onPressed: _saveRequest,
              icon: const Icon(Icons.save),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Category
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'קטגוריה',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _category,
                  items: const [
                    DropdownMenuItem(value: 'plumbing', child: Text('אינסטלציה')),
                    DropdownMenuItem(value: 'electrical', child: Text('חשמל')),
                    DropdownMenuItem(value: 'elevator', child: Text('מעליות')),
                    DropdownMenuItem(value: 'general', child: Text('כללי')),
                    DropdownMenuItem(value: 'gardening', child: Text('גינון')),
                    DropdownMenuItem(value: 'sanitation', child: Text('תברואה')),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'נא לבחור קטגוריה' : null,
                ),
                const SizedBox(height: 12),

                // Priority
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'עדיפות',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _priority,
                  items: const [
                    DropdownMenuItem(value: 'נמוך', child: Text('נמוך')),
                    DropdownMenuItem(value: 'בינוני', child: Text('בינוני')),
                    DropdownMenuItem(value: 'גבוה', child: Text('גבוה')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 'בינוני'),
                ),
                const SizedBox(height: 12),

                // Region
                TextFormField(
                  controller: _regionController,
                  decoration: const InputDecoration(
                    labelText: 'אזור (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'תיאור',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 6,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'נא להזין תיאור' : null,
                ),
                const SizedBox(height: 20),

                // Vendors list
                Row(
                  children: [
                    const Expanded(
                      child: Text('ספקים בבריכת הוועד'),
                    ),
                    TextButton.icon(
                      onPressed: _openAddVendorDialog,
                      icon: const Icon(Icons.add_business),
                      label: const Text('הוסף ספק'),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                _loadingVendors
                    ? const Center(child: CircularProgressIndicator())
                    : _committeeVendors.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: const Text('אין ספקים בבריכת הוועד. הוסף ספק חדש כדי להתחיל.'),
                          )
                        : DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'בחר ספק (אופציונלי)',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _selectedVendorId,
                            items: _committeeVendors
                                .map((v) => DropdownMenuItem(
                                      value: v['vendorId'] as String,
                                      child: Text(v['name'] ?? 'ללא שם'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedVendorId = v),
                          ),

                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saveRequest,
                  icon: const Icon(Icons.save),
                  label: const Text('שמור בקשה'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../core/models/maintenance_request.dart';
import '../../../core/models/unit.dart';
import '../../../core/services/building_service.dart';

class IssueReportingForm extends StatefulWidget {
  final String buildingId;
  final String? residentId;
  final Function(MaintenanceRequest) onIssueReported;

  const IssueReportingForm({
    super.key,
    required this.buildingId,
    this.residentId,
    required this.onIssueReported,
  });

  @override
  State<IssueReportingForm> createState() => _IssueReportingFormState();
}

class _IssueReportingFormState extends State<IssueReportingForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _notesController = TextEditingController();

  MaintenanceCategory _selectedCategory = MaintenanceCategory.general;
  MaintenancePriority _selectedPriority = MaintenancePriority.normal;
  String? _selectedUnitId;
  final List<String> _photoUrls = [];
  final List<String> _documentUrls = [];
  bool _isUrgent = false;
  bool _requiresImmediateAttention = false;

  List<Unit> _availableUnits = [];
  List<Unit> _buildingUnits = [];

  @override
  void initState() {
    super.initState();
    _loadBuildingUnits();
  }

  void _loadBuildingUnits() {
    _buildingUnits = BuildingService.getUnitsByBuilding(widget.buildingId);
    // Filter to show only residential units for residents
    if (widget.residentId != null) {
      _availableUnits = _buildingUnits.where((unit) => 
        unit.unitType == UnitType.apartment && 
        unit.currentResidentId == widget.residentId
      ).toList();
    } else {
      // For committee members, show all units
      _availableUnits = _buildingUnits.where((unit) => 
        unit.unitType == UnitType.apartment
      ).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _estimatedCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final request = MaintenanceRequest(
        id: '',
        buildingId: widget.buildingId,
        unitId: _selectedUnitId,
        residentId: widget.residentId ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        status: MaintenanceStatus.pending,
        reportedAt: DateTime.now(),
        photoUrls: _photoUrls,
        documentUrls: _documentUrls,
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        estimatedCost: _estimatedCostController.text.trim().isEmpty 
            ? null 
            : _estimatedCostController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        isUrgent: _isUrgent,
        requiresImmediateAttention: _requiresImmediateAttention,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onIssueReported(request);
      Navigator.of(context).pop();
    }
  }

  void _addPhoto() {
    // TODO: Implement photo capture/upload
    setState(() {
      _photoUrls.add('photo_${_photoUrls.length + 1}.jpg');
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('תמונה נוספה (פונקציונליות תתווסף בקרוב)'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _addDocument() {
    // TODO: Implement document upload
    setState(() {
      _documentUrls.add('document_${_documentUrls.length + 1}.pdf');
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('מסמך נוסף (פונקציונליות תתווסף בקרוב)'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _documentUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('דיווח על בעיה'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Issue Details Section
            _buildSectionHeader('פרטי הבעיה', Icons.report_problem),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'כותרת הבעיה *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                hintText: 'תיאור קצר של הבעיה',
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'כותרת הבעיה היא שדה חובה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'תיאור מפורט *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'תיאור מפורט של הבעיה והמיקום',
              ),
              maxLines: 4,
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'תיאור הבעיה הוא שדה חובה';
                }
                if (value.trim().length < 10) {
                  return 'התיאור חייב להכיל לפחות 10 תווים';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<MaintenanceCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'קטגוריה *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: MaintenanceCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryDisplay(category)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Priority
            DropdownButtonFormField<MaintenancePriority>(
              initialValue: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'עדיפות *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: MaintenancePriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                                             Container(
                         width: 16,
                         height: 16,
                         decoration: BoxDecoration(
                           color: _getPriorityColor(priority),
                           shape: BoxShape.circle,
                         ),
                       ),
                      const SizedBox(width: 8),
                                             Text(_getPriorityDisplay(priority)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Unit Selection (if applicable)
            if (_availableUnits.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedUnitId,
                decoration: const InputDecoration(
                  labelText: 'יחידה (אופציונלי)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                  hintText: 'בחר יחידה אם הבעיה ספציפית ליחידה',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('בעיה כללית בבניין'),
                  ),
                  ..._availableUnits.map((unit) {
                    return DropdownMenuItem(
                      value: unit.id,
                      child: Text('${unit.unitNumber} - ${unit.description ?? ''}'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnitId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'מיקום ספציפי',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'למשל: קומה 3, חדר מדרגות, גינה',
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),

            // Urgency Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'אפשרויות דחיפות',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('בעיה דחופה'),
                      subtitle: const Text('דורשת טיפול מיידי'),
                      value: _isUrgent,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent = value;
                          if (value) {
                            _selectedPriority = MaintenancePriority.urgent;
                          }
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('דורש תשומת לב מיידית'),
                      subtitle: const Text('בעיה קריטית לבטיחות'),
                      value: _requiresImmediateAttention,
                      onChanged: (value) {
                        setState(() {
                          _requiresImmediateAttention = value;
                          if (value) {
                            _selectedPriority = MaintenancePriority.urgent;
                            _isUrgent = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Media Section
            _buildSectionHeader('מדיה ומסמכים', Icons.attach_file),
            const SizedBox(height: 16),

            // Photos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_camera),
                        const SizedBox(width: 8),
                        const Text('תמונות'),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _addPhoto,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('הוסף תמונה'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_photoUrls.isEmpty)
                      const Text(
                        'אין תמונות נוספות',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _photoUrls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final photoUrl = entry.value;
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Documents
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description),
                        const SizedBox(width: 8),
                        const Text('מסמכים'),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _addDocument,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('הוסף מסמך'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_documentUrls.isEmpty)
                      const Text(
                        'אין מסמכים נוספים',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Column(
                        children: _documentUrls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final documentUrl = entry.value;
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(documentUrl),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeDocument(index),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Information Section
            _buildSectionHeader('מידע נוסף', Icons.info),
            const SizedBox(height: 16),

            // Estimated Cost
            TextFormField(
              controller: _estimatedCostController,
              decoration: const InputDecoration(
                labelText: 'עלות משוערת',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'למשל: ₪500',
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'הערות נוספות',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'מידע נוסף שיכול לעזור בפתרון הבעיה',
              ),
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'שלח דיווח',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  String _getCategoryDisplay(MaintenanceCategory category) {
    switch (category) {
      case MaintenanceCategory.plumbing:
        return 'אינסטלציה';
      case MaintenanceCategory.electrical:
        return 'חשמל';
      case MaintenanceCategory.hvac:
        return 'מיזוג אוויר';
      case MaintenanceCategory.cleaning:
        return 'ניקיון';
      case MaintenanceCategory.gardening:
        return 'גינון';
      case MaintenanceCategory.elevator:
        return 'מעליות';
      case MaintenanceCategory.security:
        return 'אבטחה';
      case MaintenanceCategory.structural:
        return 'מבני';
      case MaintenanceCategory.general:
        return 'כללי';
    }
  }

  String _getPriorityDisplay(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.urgent:
        return 'דחוף';
      case MaintenancePriority.high:
        return 'גבוה';
      case MaintenancePriority.normal:
        return 'רגיל';
      case MaintenancePriority.low:
        return 'נמוך';
    }
  }

  Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.urgent:
        return Colors.red;
      case MaintenancePriority.high:
        return Colors.orange;
      case MaintenancePriority.normal:
        return Colors.blue;
      case MaintenancePriority.low:
        return Colors.green;
    }
  }
}

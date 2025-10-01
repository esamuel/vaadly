import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Optional photo attachment
  XFile? _attachedPhoto;
  final ImagePicker _picker = ImagePicker();
  
  String _selectedCategory = 'כללי';
  String _selectedPriority = 'רגיל';
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _categories = [
    'כללי',
    'אינסטלציה',
    'חשמל',
    'מזגן',
    'מעלית',
    'דלתות וחלונות',
    'צבע וגימור',
    'אבטחה',
    'גינון',
    'אחר'
  ];

  final List<String> _priorities = [
    'רגיל',
    'דחוף',
    'חירום'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService.currentUser;
      final buildingContext = BuildingContextService.currentBuilding;
      
      // Check for required data
      if (user == null) {
        throw Exception('משתמש לא מחובר');
      }
      
      if (buildingContext == null) {
        throw Exception('לא נמצא הקשר לבניין');
      }
      
      final buildingId = buildingContext.buildingId;
      final unitId = user.getResidentUnit(buildingId) ?? '';
      
      // 1) Create issue document in Firestore
      final issuesCol = FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .collection('issues');

      final issueDoc = await issuesCol.add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'residentId': user.id,
        'residentName': user.name,
        'residentEmail': user.email,
        'unitId': unitId,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      String? photoUrl;

      // 2) If photo attached, upload to Storage and save URL
      if (_attachedPhoto != null) {
        final storage = FirebaseStorage.instance;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_attachedPhoto!.name}';
        final ref = storage.ref('buildings/$buildingId/issues/${issueDoc.id}/attachments/$fileName');
        final data = await _attachedPhoto!.readAsBytes();
        final meta = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(data, meta);
        photoUrl = await ref.getDownloadURL();

        await issueDoc.collection('attachments').add({
          'url': photoUrl,
          'type': 'image',
          'uploadedAt': FieldValue.serverTimestamp(),
          'uploadedBy': user.id,
        });

        // Also store top-level field for quick preview
        await issueDoc.update({'previewImageUrl': photoUrl});
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הבקשה נשלחה בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאה בשליחת הבקשה: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'חירום':
        return Colors.red;
      case 'דחוף':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'אינסטלציה':
        return Icons.water_drop;
      case 'חשמל':
        return Icons.electrical_services;
      case 'מזגן':
        return Icons.ac_unit;
      case 'מעלית':
        return Icons.elevator;
      case 'דלתות וחלונות':
        return Icons.door_front_door;
      case 'צבע וגימור':
        return Icons.format_paint;
      case 'אבטחה':
        return Icons.security;
      case 'גינון':
        return Icons.local_florist;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final buildingContext = BuildingContextService.currentBuilding;
    final unitId = user?.getResidentUnit(buildingContext?.buildingId ?? '') ?? 'לא ידוע';
    
    // Handle case where user is not authenticated
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('דיווח על תקלה'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('שגיאה: משתמש לא מחובר'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('דיווח על תקלה חדשה'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info card
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.orange, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'דירה $unitId - ${buildingContext?.buildingName ?? 'בניין לא ידוע'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Photo attachment (optional)
              Text(
                'תמונה (אופציונלי)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1920, maxHeight: 1080);
                            if (picked != null) {
                              setState(() => _attachedPhoto = picked);
                            }
                          },
                    icon: const Icon(Icons.photo),
                    label: const Text('בחר תמונה'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1920, maxHeight: 1080);
                            if (picked != null) {
                              setState(() => _attachedPhoto = picked);
                            }
                          },
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('מצלמה'),
                  ),
                ],
              ),
              if (_attachedPhoto != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FutureBuilder<Uint8List>(
                    future: _attachedPhoto!.readAsBytes(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const SizedBox(
                          height: 140,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Image.memory(
                        snap.data!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Category selection
              Text(
                'קטגוריה',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  prefixIcon: Icon(_getCategoryIcon(_selectedCategory)),
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((category) => DropdownMenuItem<String>(
                  value: category,
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(category), size: 20),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                )).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Priority selection
              Text(
                'עדיפות',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.priority_high, color: _getPriorityColor(_selectedPriority)),
                  border: const OutlineInputBorder(),
                ),
                items: _priorities.map((priority) => DropdownMenuItem<String>(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(Icons.priority_high, color: _getPriorityColor(priority), size: 20),
                      const SizedBox(width: 8),
                      Text(priority),
                    ],
                  ),
                )).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedPriority = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Issue title
              Text(
                'כותרת הבעיה',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'לדוגמה: ברז נוטף במטבח',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'אנא הכנס כותרת לתקלה';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location
              Text(
                'מיקום בדירה',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'לדוגמה: מטבח, חדר שינה, סלון',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'אנא ציין את מיקום התקלה';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'תיאור מפורט',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'תאר את הבעיה בפירוט - מתי התחילה, מה קרה, האם זה מפריע לחיי היומיום',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'אנא הכנס תיאור מפורט של הבעיה';
                  }
                  if (value.trim().length < 10) {
                    return 'התיאור קצר מדי - אנא הרחב';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('שולח בקשה...'),
                          ],
                        )
                      : const Text(
                          'שלח בקשת תחזוקה',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Info card
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'מידע חשוב:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('• בקשות רגילות יטופלו תוך 3-5 יום עבודה'),
                      const Text('• בקשות דחופות יטופלו תוך 24 שעות'),
                      const Text('• בשעת חירום - התקשר ל: 100'),
                      const Text('• תקבל עדכון SMS על התקדמות הטיפול'),
                      const Text('• ניתן לעקוב אחר הבקשה בלשונית תחזוקה'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';

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
      final user = AuthService.currentUser!;
      final buildingContext = BuildingContextService.currentBuilding!;
      
      // Simulate issue submission
      await Future.delayed(const Duration(seconds: 2));
      
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
    final user = AuthService.currentUser!;
    final buildingContext = BuildingContextService.currentBuilding;
    final unitId = user.getResidentUnit(buildingContext?.buildingId ?? '') ?? 'לא ידוע';

    return Scaffold(
      appBar: AppBar(
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

              // Category selection
              Text(
                'קטגוריה',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  prefixIcon: Icon(_getCategoryIcon(_selectedCategory)),
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((category) => DropdownMenuItem(
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
                  setState(() {
                    _selectedCategory = value!;
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
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.priority_high, color: _getPriorityColor(_selectedPriority)),
                  border: const OutlineInputBorder(),
                ),
                items: _priorities.map((priority) => DropdownMenuItem(
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
                  setState(() {
                    _selectedPriority = value!;
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_building_service.dart';
import '../../core/models/building.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.length <= 3) {
      return newValue.copyWith(
        text: '($text',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    } else if (text.length <= 10) {
      final formatted = '(${text.substring(0, 3)})${text.substring(3)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      final truncated = text.substring(0, 10);
      final formatted = '(${truncated.substring(0, 3)})${truncated.substring(3)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
}

class AddBuildingScreen extends StatefulWidget {
  const AddBuildingScreen({super.key});

  @override
  State<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends State<AddBuildingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buildingNameController = TextEditingController();
  final _buildingCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _unitsController = TextEditingController();
  final _floorsController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _managerEmailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isCreating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _buildingNameController.dispose();
    _buildingCodeController.dispose();
    _addressController.dispose();
    _unitsController.dispose();
    _floorsController.dispose();
    _managerNameController.dispose();
    _managerPhoneController.dispose();
    _managerEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generateBuildingCode() {
    final name = _buildingNameController.text.trim();
    if (name.isNotEmpty) {
      // Simple code generation - replace spaces with dashes and make lowercase
      final code = name
          .replaceAll(' ', '-')
          .replaceAll('ה', '')
          .replaceAll('ב', '')
          .replaceAll('ל', '')
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\-]'), '');
      
      setState(() {
        _buildingCodeController.text = code;
      });
    }
  }

  Future<void> _createBuilding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // Create the building object
      final building = Building(
        id: '', // Will be assigned by BuildingService
        buildingCode: _buildingCodeController.text.trim(),
        name: _buildingNameController.text.trim(),
        address: _addressController.text.trim(),
        city: 'תל אביב', // Default city
        postalCode: '00000', // Default postal code
        country: 'ישראל',
        totalFloors: int.parse(_floorsController.text.trim()),
        totalUnits: int.parse(_unitsController.text.trim()),
        parkingSpaces: 0, // Default
        storageUnits: 0, // Default
        buildingArea: 0.0, // Default
        yearBuilt: DateTime.now().year,
        buildingType: 'residential',
        amenities: ['elevator', 'security'],
        buildingManager: _managerNameController.text.trim(),
        managerPhone: _managerPhoneController.text.trim(),
        managerEmail: _managerEmailController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      
      // Save the building using Firebase
      final savedBuilding = await FirebaseBuildingService.addBuilding(building);
      
      final buildingLink = 'http://localhost:3000/#/manage/${savedBuilding.buildingCode}';
      
      if (mounted) {
        // Show success dialog with building link
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('בניין נוצר בהצלחה!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('הבניין "${_buildingNameController.text}" נוצר בהצלחה במערכת.'),
                const SizedBox(height: 16),
                const Text(
                  'קישור הבניין:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          buildingLink,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: buildingLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('קישור הועתק ללוח הגזירים')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'העתק קישור',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'שלח קישור זה לועד הבית כדי שיוכלו להקים חשבון ולהתחיל לנהל את הבניין.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Go back to buildings list with success result
                },
                child: const Text('סגור'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאה ביצירת הבניין: $e';
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הוספת בניין חדש'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            'הוספת לקוח חדש',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('מלא את פרטי הבניין והועדה כדי להוסיף לקוח חדש למערכת.'),
                      const Text('הועדה תקבל קישור לכניסה לפורטל הבניין שלה.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Building Information Section
              Text(
                'פרטי בניין',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _buildingNameController,
                decoration: const InputDecoration(
                  labelText: 'שם הבניין *',
                  hintText: 'לדוגמה: מגדל שלום',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _generateBuildingCode(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'אנא הכנס שם הבניין';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _buildingCodeController,
                decoration: InputDecoration(
                  labelText: 'קוד בניין *',
                  hintText: 'magdal-shalom',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _generateBuildingCode,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'יצירה אוטומטית',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'אנא הכנס קוד בניין';
                  }
                  if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(value)) {
                    return 'רק אותיות באנגלית, מספרים ומקף';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'מספר קומות *',
                        hintText: '8',
                        prefixIcon: Icon(Icons.layers),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'חובה';
                        }
                        final floors = int.tryParse(value);
                        if (floors == null || floors <= 0) {
                          return 'מספר לא תקין';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'מספר דירות *',
                        hintText: '24',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'חובה';
                        }
                        final units = int.tryParse(value);
                        if (units == null || units <= 0) {
                          return 'מספר לא תקין';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'כתובת הבניין *',
                  hintText: 'רחוב הרצל 123, תל אביב',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'אנא הכנס כתובת הבניין';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Committee Information Section
              Text(
                'פרטי ועד הבית',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _managerNameController,
                decoration: const InputDecoration(
                  labelText: 'שם מנהל הבניין *',
                  hintText: 'יוסי כהן',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'אנא הכנס שם מנהל הבניין';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _managerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'טלפון *',
                        hintText: '(123)4567890',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        PhoneNumberFormatter(),
                        LengthLimitingTextInputFormatter(13), // (123)4567890
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'אנא הכנס טלפון';
                        }
                        final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                        if (digitsOnly.length < 9) {
                          return 'מספר טלפון חייב להכיל לפחות 9 ספרות';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _managerEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'דואר אלקטרוני *',
                        hintText: 'manager@building.co.il',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'חובה';
                        }
                        if (!value.contains('@')) {
                          return 'כתובת לא תקינה';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'הערות נוספות',
                  hintText: 'מידע נוסף או הערות על הבניין...',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

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

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createBuilding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: _isCreating
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
                            Text('יוצר בניין...'),
                          ],
                        )
                      : const Text(
                          'צור בניין ולקוח חדש',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
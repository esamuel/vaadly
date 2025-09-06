import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/resident.dart';
import '../../../core/services/building_context_service.dart';
import '../../../services/firebase_building_service.dart';

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

class AddResidentForm extends StatefulWidget {
  final Function(Resident) onResidentAdded;
  final Resident? residentToEdit;

  const AddResidentForm({
    super.key,
    required this.onResidentAdded,
    this.residentToEdit,
  });

  @override
  State<AddResidentForm> createState() => _AddResidentFormState();
}

class _AddResidentFormState extends State<AddResidentForm> {
  int? _totalUnits;
  int? _totalFloors;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _floorController = TextEditingController();
  final _residentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  ResidentType _selectedType = ResidentType.tenant;
  ResidentStatus _selectedStatus = ResidentStatus.active;
  DateTime _selectedMoveInDate = DateTime.now();
  DateTime? _selectedMoveOutDate;
  bool _hasMoveOutDate = false;
  // Store canonical tag KEYS (English identifiers) for compatibility with existing data
  List<String> _selectedTags = [];
  bool _isActive = true;

  // Canonical keys and translations
  static const Map<String, String> _tagTranslations = {
    'VIP': 'VIP',
    'Special Needs': 'צרכים מיוחדים',
    'Pet Owner': 'בעל/ת חיית מחמד',
    'Senior Citizen': 'אזרח/ית ותיק/ה',
    'Student': 'סטודנט/ית',
    'Family with Children': 'משפחה עם ילדים',
    'Single': 'רווק/ה',
    'Working Professional': 'עובד/ת',
    'Retired': 'גמלאי/ת',
    'Medical Professional': 'איש/אשת רפואה',
    'Emergency Contact': 'איש קשר לחירום',
    'Building Committee Member': 'חבר/ת ועד הבית',
  };

  static const List<String> _availableTagKeys = [
    'Student',
    'Senior Citizen',
    'Pet Owner',
    'Special Needs',
    'VIP',
    'Retired',
    'Working Professional',
    'Single',
    'Family with Children',
    'Building Committee Member',
    'Emergency Contact',
    'Medical Professional',
  ];

  String _t(String key) => _tagTranslations[key] ?? key;
  String _keyFromLabel(String label) {
    // Try exact reverse lookup
    final entry = _tagTranslations.entries.firstWhere(
      (e) => e.value == label,
      orElse: () => const MapEntry('', ''),
    );
    if (entry.key.isNotEmpty) return entry.key;
    // If label already a key, return it
    if (_tagTranslations.containsKey(label)) return label;
    return label; // fallback
  }

  @override
  void initState() {
    super.initState();
    if (widget.residentToEdit != null) {
      _populateForm(widget.residentToEdit!);
    }
    _loadBuildingLimits();
  }

  void _populateForm(Resident resident) {
    _firstNameController.text = resident.firstName;
    _lastNameController.text = resident.lastName;
    _apartmentController.text = resident.apartmentNumber;
    _floorController.text = resident.floor ?? '';
    _residentIdController.text = resident.residentId ?? '';
    _phoneController.text = resident.phoneNumber;
    _emailController.text = resident.email;
    _emergencyContactController.text = resident.emergencyContact ?? '';
    _emergencyPhoneController.text = resident.emergencyPhone ?? '';
    _notesController.text = resident.notes ?? '';
    _selectedType = resident.residentType;
    _selectedStatus = resident.status;
    _selectedMoveInDate = resident.moveInDate;
    _selectedMoveOutDate = resident.moveOutDate;
    _hasMoveOutDate = resident.moveOutDate != null;
    // Normalize existing tags to canonical KEYS
    _selectedTags = resident.tags.map(_keyFromLabel).toList();
    _isActive = resident.isActive;
  }

  Future<void> _loadBuildingLimits() async {
    try {
      final id = BuildingContextService.buildingId;
      if (id == null) return;
      final building = await FirebaseBuildingService.getBuildingById(id);
      if (building != null) {
        setState(() {
          _totalUnits = building.totalUnits;
          _totalFloors = building.totalFloors;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _apartmentController.dispose();
    _floorController.dispose();
    _residentIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isMoveIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMoveIn
          ? _selectedMoveInDate
          : (_selectedMoveOutDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isMoveIn) {
          _selectedMoveInDate = picked;
          // If move-in date is after move-out date, clear move-out date
          if (_selectedMoveOutDate != null &&
              _selectedMoveInDate.isAfter(_selectedMoveOutDate!)) {
            _selectedMoveOutDate = null;
            _hasMoveOutDate = false;
          }
        } else {
          _selectedMoveOutDate = picked;
        }
      });
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final resident = Resident(
        id: widget.residentToEdit?.id ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        apartmentNumber: _apartmentController.text.trim(),
        floor: _floorController.text.trim().isEmpty
            ? null
            : _floorController.text.trim(),
        residentId: _residentIdController.text.trim().isEmpty
            ? null
            : _residentIdController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        residentType: _selectedType,
        status: _selectedStatus,
        moveInDate: _selectedMoveInDate,
        moveOutDate: _hasMoveOutDate ? _selectedMoveOutDate : null,
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.residentToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: _isActive,
        tags: _selectedTags,
        customFields: {},
      );

      widget.onResidentAdded(resident);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.residentToEdit != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isEditing ? 'ערוך דייר' : 'הוסף דייר חדש'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Personal Information Section
            _buildSectionHeader('מידע אישי', Icons.person),
            const SizedBox(height: 16),

            // First Name
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'שם פרטי *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'שם פרטי הוא שדה חובה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'שם משפחה *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.family_restroom),
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'שם משפחה הוא שדה חובה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Apartment Number
            TextFormField(
              controller: _apartmentController,
              decoration: const InputDecoration(
                labelText: 'מספר דירה *',
                border: OutlineInputBorder(),
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'מספר דירה הוא שדה חובה';
                }
                final text = value.trim();
                final asInt = int.tryParse(text);
                if (asInt != null && _totalUnits != null) {
                  if (asInt < 1 || asInt > _totalUnits!) {
                    return 'מספר הדירה חייב להיות בין 1 ל-$_totalUnits';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Floor Number
            TextFormField(
              controller: _floorController,
              decoration: InputDecoration(
                labelText: 'קומה',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.layers),
                hintText: _totalFloors != null ? '1 - $_totalFloors (אופציונלי)' : 'מספר קומה (אופציונלי)',
              ),
              textDirection: TextDirection.rtl,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null; // optional
                final asInt = int.tryParse(value.trim());
                if (asInt == null) return 'יש להזין מספר תקין';
                if (_totalFloors != null && (asInt < 1 || asInt > _totalFloors!)) {
                  return 'מספר הקומה חייב להיות בין 1 ל-$_totalFloors';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Resident ID
            TextFormField(
              controller: _residentIdController,
              decoration: const InputDecoration(
                labelText: 'תעודת זהות/דרכון',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                hintText: 'מספר תעודת זהות או דרכון (אופציונלי)',
              ),
              textDirection: TextDirection.rtl,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Contact Information Section
            _buildSectionHeader('פרטי קשר', Icons.contact_phone),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'מספר טלפון *',
                hintText: '(123)4567890',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                PhoneNumberFormatter(),
                LengthLimitingTextInputFormatter(13), // (123)4567890
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'מספר טלפון הוא שדה חובה';
                }
                final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                if (digitsOnly.length < 9) {
                  return 'מספר טלפון חייב להכיל לפחות 9 ספרות';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'כתובת אימייל *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'כתובת אימייל היא שדה חובה';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'כתובת אימייל לא תקינה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Emergency Contact
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'איש קשר לחירום',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.emergency),
                hintText: 'שם איש קשר לחירום (אופציונלי)',
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),

            // Emergency Phone
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(
                labelText: 'טלפון חירום',
                hintText: '(123)4567890 (אופציונלי)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_forwarded),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                PhoneNumberFormatter(),
                LengthLimitingTextInputFormatter(13), // (123)4567890
              ],
            ),
            const SizedBox(height: 16),

            // Resident Details Section
            _buildSectionHeader('פרטי דייר', Icons.info),
            const SizedBox(height: 16),

            // Resident Type
            DropdownButtonFormField<ResidentType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'סוג דייר *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ResidentType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeDisplay(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<ResidentStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'סטטוס *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: ResidentStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusDisplay(status)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Move-in Date
            InkWell(
              onTap: () => _selectDate(context, true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'תאריך כניסה *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedMoveInDate.day}/${_selectedMoveInDate.month}/${_selectedMoveInDate.year}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Move-out Date (Optional)
            Row(
              children: [
                Checkbox(
                  value: _hasMoveOutDate,
                  onChanged: (value) {
                    setState(() {
                      _hasMoveOutDate = value!;
                      if (!_hasMoveOutDate) {
                        _selectedMoveOutDate = null;
                      }
                    });
                  },
                ),
                const Text('יש תאריך יציאה'),
              ],
            ),
            if (_hasMoveOutDate) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'תאריך יציאה',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedMoveOutDate != null
                        ? '${_selectedMoveOutDate!.day}/${_selectedMoveOutDate!.month}/${_selectedMoveOutDate!.year}'
                        : 'בחר תאריך',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Active Status
            SwitchListTile(
              title: const Text('דייר פעיל'),
              subtitle: const Text('הדייר פעיל במערכת'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Tags Section
            _buildSectionHeader('תגיות', Icons.label),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTagKeys.map((key) {
                final isSelected = _selectedTags.contains(key);
                return FilterChip(
                  label: Text(_t(key)),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(key),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes Section
            _buildSectionHeader('הערות', Icons.note),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'הערות',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
                hintText: 'הערות נוספות על הדייר (אופציונלי)',
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
              child: Text(
                isEditing ? 'עדכן דייר' : 'הוסף דייר',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  String _getTypeDisplay(ResidentType type) {
    switch (type) {
      case ResidentType.owner:
        return 'בעל דירה';
      case ResidentType.tenant:
        return 'שוכר';
      case ResidentType.familyMember:
        return 'בן משפחה';
      case ResidentType.guest:
        return 'אורח';
      default:
        return 'לא ידוע';
    }
  }

  String _getStatusDisplay(ResidentStatus status) {
    switch (status) {
      case ResidentStatus.active:
        return 'פעיל';
      case ResidentStatus.inactive:
        return 'לא פעיל';
      case ResidentStatus.pending:
        return 'ממתין לאישור';
      case ResidentStatus.suspended:
        return 'מושעה';
      default:
        return 'לא ידוע';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/building.dart';

class AddBuildingForm extends StatefulWidget {
  final Function(Building) onBuildingAdded;
  final Building? buildingToEdit;

  const AddBuildingForm({
    super.key,
    required this.onBuildingAdded,
    this.buildingToEdit,
  });

  @override
  State<AddBuildingForm> createState() => _AddBuildingFormState();
}

class _AddBuildingFormState extends State<AddBuildingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _totalUnitsController = TextEditingController();
  final _parkingSpacesController = TextEditingController();
  final _storageUnitsController = TextEditingController();
  final _buildingAreaController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _buildingManagerController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _managerEmailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedBuildingType = 'residential';
  List<String> _selectedAmenities = [];
  bool _isActive = true;

  final List<String> _availableAmenities = [
    'pool', // בריכה
    'gym', // חדר כושר
    'garden', // גינה
    'playground', // מגרש משחקים
    'parking', // חניה
    'storage', // מחסן
    'elevator', // מעלית
    'security', // אבטחה
    'cctv', // מצלמות אבטחה
    'intercom', // אינטרקום
    'airConditioning', // מיזוג אוויר
    'heating', // חימום
    'wifi', // אינטרנט אלחוטי
    'laundry', // חדר כביסה
    'bikeStorage', // אחסון אופניים
    'petFriendly', // ידידותי לחיות מחמד
    'accessibility', // נגישות
  ];

  @override
  void initState() {
    super.initState();
    if (widget.buildingToEdit != null) {
      _populateForm(widget.buildingToEdit!);
    } else {
      // Set default values for new building
      _countryController.text = 'ישראל';
      _yearBuiltController.text = DateTime.now().year.toString();
    }
  }

  void _populateForm(Building building) {
    _nameController.text = building.name;
    _addressController.text = building.address;
    _cityController.text = building.city;
    _postalCodeController.text = building.postalCode;
    _countryController.text = building.country;
    _totalFloorsController.text = building.totalFloors.toString();
    _totalUnitsController.text = building.totalUnits.toString();
    _parkingSpacesController.text = building.parkingSpaces.toString();
    _storageUnitsController.text = building.storageUnits.toString();
    _buildingAreaController.text = building.buildingArea.toString();
    _yearBuiltController.text = building.yearBuilt.toString();
    _buildingManagerController.text = building.buildingManager ?? '';
    _managerPhoneController.text = building.managerPhone ?? '';
    _managerEmailController.text = building.managerEmail ?? '';
    _emergencyContactController.text = building.emergencyContact ?? '';
    _emergencyPhoneController.text = building.emergencyPhone ?? '';
    _notesController.text = building.notes ?? '';
    _selectedBuildingType = building.buildingType;
    _selectedAmenities = List.from(building.amenities);
    _isActive = building.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _totalFloorsController.dispose();
    _totalUnitsController.dispose();
    _parkingSpacesController.dispose();
    _storageUnitsController.dispose();
    _buildingAreaController.dispose();
    _yearBuiltController.dispose();
    _buildingManagerController.dispose();
    _managerPhoneController.dispose();
    _managerEmailController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final building = Building(
        id: widget.buildingToEdit?.id ?? '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
        totalFloors: int.parse(_totalFloorsController.text.trim()),
        totalUnits: int.parse(_totalUnitsController.text.trim()),
        parkingSpaces: int.parse(_parkingSpacesController.text.trim()),
        storageUnits: int.parse(_storageUnitsController.text.trim()),
        buildingArea: double.parse(_buildingAreaController.text.trim()),
        yearBuilt: int.parse(_yearBuiltController.text.trim()),
        buildingType: _selectedBuildingType,
        amenities: _selectedAmenities,
        buildingManager: _buildingManagerController.text.trim().isEmpty
            ? null
            : _buildingManagerController.text.trim(),
        managerPhone: _managerPhoneController.text.trim().isEmpty
            ? null
            : _managerPhoneController.text.trim(),
        managerEmail: _managerEmailController.text.trim().isEmpty
            ? null
            : _managerEmailController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.buildingToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: _isActive,
      );

      widget.onBuildingAdded(building);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.buildingToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ערוך בניין' : 'הוסף בניין חדש'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            _buildSectionHeader('מידע בסיסי', Icons.business),
            const SizedBox(height: 16),

            // Building Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'שם הבניין *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
                hintText: 'למשל: מגדל השלום, בניין וודלי',
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'שם הבניין הוא שדה חובה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'כתובת *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'רחוב ומספר בית',
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'כתובת היא שדה חובה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'עיר *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
                hintText: 'למשל: תל אביב, ירושלים',
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'עיר היא שדה חובה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Postal Code
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'מיקוד *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.markunread_mailbox),
                hintText: '7 ספרות',
              ),
              textDirection: TextDirection.rtl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'מיקוד הוא שדה חובה';
                }
                if (value.length != 7) {
                  return 'מיקוד חייב להכיל 7 ספרות';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'מדינה *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
                hintText: 'למשל: ישראל',
              ),
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'מדינה היא שדה חובה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Building Specifications Section
            _buildSectionHeader('מפרט הבניין', Icons.architecture),
            const SizedBox(height: 16),

            // Building Type
            DropdownButtonFormField<String>(
              initialValue: _selectedBuildingType,
              decoration: const InputDecoration(
                labelText: 'סוג בניין *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'residential', child: Text('מגורים')),
                DropdownMenuItem(value: 'commercial', child: Text('מסחרי')),
                DropdownMenuItem(value: 'mixed', child: Text('מעורב')),
                DropdownMenuItem(value: 'office', child: Text('משרדים')),
                DropdownMenuItem(value: 'industrial', child: Text('תעשייתי')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBuildingType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Total Floors
            TextFormField(
              controller: _totalFloorsController,
              decoration: const InputDecoration(
                labelText: 'מספר קומות *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers),
                hintText: 'למשל: 15',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'מספר קומות הוא שדה חובה';
                }
                final floors = int.tryParse(value);
                if (floors == null || floors < 1) {
                  return 'מספר קומות חייב להיות מספר חיובי';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Total Units
            TextFormField(
              controller: _totalUnitsController,
              decoration: const InputDecoration(
                labelText: 'מספר יחידות *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
                hintText: 'למשל: 60',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'מספר יחידות הוא שדה חובה';
                }
                final units = int.tryParse(value);
                if (units == null || units < 1) {
                  return 'מספר יחידות חייב להיות מספר חיובי';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Parking Spaces
            TextFormField(
              controller: _parkingSpacesController,
              decoration: const InputDecoration(
                labelText: 'מספר חניות',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_parking),
                hintText: 'למשל: 45',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final parking = int.tryParse(value);
                  if (parking == null || parking < 0) {
                    return 'מספר חניות חייב להיות מספר חיובי';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Storage Units
            TextFormField(
              controller: _storageUnitsController,
              decoration: const InputDecoration(
                labelText: 'מספר מחסנים',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
                hintText: 'למשל: 30',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final storage = int.tryParse(value);
                  if (storage == null || storage < 0) {
                    return 'מספר מחסנים חייב להיות מספר חיובי';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Building Area
            TextFormField(
              controller: _buildingAreaController,
              decoration: const InputDecoration(
                labelText: 'שטח הבניין (מ"ר) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.square_foot),
                hintText: 'למשל: 8500',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'שטח הבניין הוא שדה חובה';
                }
                final area = double.tryParse(value);
                if (area == null || area <= 0) {
                  return 'שטח הבניין חייב להיות מספר חיובי';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Year Built
            TextFormField(
              controller: _yearBuiltController,
              decoration: const InputDecoration(
                labelText: 'שנת בנייה *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                hintText: 'למשל: 2015',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'שנת בנייה היא שדה חובה';
                }
                final year = int.tryParse(value);
                if (year == null ||
                    year < 1900 ||
                    year > DateTime.now().year + 5) {
                  return 'שנת בנייה לא תקינה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Management Information Section
            _buildSectionHeader('מידע ניהולי', Icons.manage_accounts),
            const SizedBox(height: 16),

            // Building Manager
            TextFormField(
              controller: _buildingManagerController,
              decoration: const InputDecoration(
                labelText: 'מנהל הבניין',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'שם מנהל הבניין (אופציונלי)',
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),

            // Manager Phone
            TextFormField(
              controller: _managerPhoneController,
              decoration: const InputDecoration(
                labelText: 'טלפון מנהל',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: 'מספר טלפון מנהל הבניין (אופציונלי)',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Manager Email
            TextFormField(
              controller: _managerEmailController,
              decoration: const InputDecoration(
                labelText: 'אימייל מנהל',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                hintText: 'כתובת אימייל מנהל הבניין (אופציונלי)',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'כתובת אימייל לא תקינה';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Emergency Contact
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'איש קשר חירום',
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_forwarded),
                hintText: 'מספר טלפון לחירום (אופציונלי)',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Amenities Section
            _buildSectionHeader('שירותים ונוחות', Icons.emoji_emotions),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAmenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return FilterChip(
                  label: Text(_getAmenityDisplay(amenity)),
                  selected: isSelected,
                  onSelected: (_) => _toggleAmenity(amenity),
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
                hintText: 'הערות נוספות על הבניין (אופציונלי)',
              ),
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),

            // Active Status
            SwitchListTile(
              title: const Text('בניין פעיל'),
              subtitle: const Text('הבניין פעיל במערכת'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
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
                isEditing ? 'עדכן בניין' : 'הוסף בניין',
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

  String _getAmenityDisplay(String amenity) {
    switch (amenity) {
      case 'pool':
        return 'בריכה';
      case 'gym':
        return 'חדר כושר';
      case 'garden':
        return 'גינה';
      case 'playground':
        return 'מגרש משחקים';
      case 'parking':
        return 'חניה';
      case 'storage':
        return 'מחסן';
      case 'elevator':
        return 'מעלית';
      case 'security':
        return 'אבטחה';
      case 'cctv':
        return 'מצלמות אבטחה';
      case 'intercom':
        return 'אינטרקום';
      case 'airConditioning':
        return 'מיזוג אוויר';
      case 'heating':
        return 'חימום';
      case 'wifi':
        return 'אינטרנט אלחוטי';
      case 'laundry':
        return 'חדר כביסה';
      case 'bikeStorage':
        return 'אחסון אופניים';
      case 'petFriendly':
        return 'ידידותי לחיות מחמד';
      case 'accessibility':
        return 'נגישות';
      default:
        return amenity;
    }
  }
}

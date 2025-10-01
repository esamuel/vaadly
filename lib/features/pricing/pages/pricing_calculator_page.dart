import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/pricing_calculator.dart';
import '../../../core/services/pricing_calculator_service.dart';
import '../../../core/models/building.dart' hide BuildingType, BuildingAmenity;
import '../../../services/firebase_building_service.dart';
import '../../../core/models/invoice.dart';
import '../../../core/models/expense.dart';
import '../../../services/firebase_financial_service.dart';

class PricingCalculatorPage extends StatefulWidget {
  const PricingCalculatorPage({super.key});

  @override
  State<PricingCalculatorPage> createState() => _PricingCalculatorPageState();
}

class _PricingCalculatorPageState extends State<PricingCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _pricingService = PricingCalculatorService();

  // Form controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _totalApartmentsController = TextEditingController();
  final _apartmentsPerFloorController = TextEditingController();
  final _buildingAgeController = TextEditingController();

  // Building selection
  List<Building> _buildings = [];
  Building? _selectedBuilding;
  bool _isLoadingBuildings = false;

  // Form state
  ServiceTier _selectedServiceTier = ServiceTier.standard;
  ContractDuration _selectedContractDuration = ContractDuration.annual;
  final BuildingType _selectedBuildingType = BuildingType.residential;
  final List<BuildingAmenity> _selectedAmenities = [];
  final List<String> _selectedAdditionalServices = [];

  final bool _hasElevator = false;
  final bool _hasStorage = false;
  final bool _hasBalconies = false;
  bool _isCalculating = false;
  bool _isSavingFinance = false;

  PricingResult? _pricingResult;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    _totalFloorsController.dispose();
    _totalApartmentsController.dispose();
    _apartmentsPerFloorController.dispose();
    _buildingAgeController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _isLoadingBuildings = true;
    });

    try {
      final buildings = await FirebaseBuildingService.getAllBuildings();
      setState(() {
        _buildings = buildings;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בטעינת רשימת בניינים: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingBuildings = false;
      });
    }
  }

  void _onBuildingSelected(Building? building) {
    setState(() {
      _selectedBuilding = building;
    });

    if (building != null) {
      // Auto-populate building data
      _addressController.text = building.address;
      _cityController.text = building.city;
      _totalFloorsController.text = building.totalFloors.toString();
      _totalApartmentsController.text = building.totalUnits.toString();
      _apartmentsPerFloorController.text =
          (building.totalUnits / building.totalFloors).round().toString();

      // Calculate building age from year built
      final currentYear = DateTime.now().year;
      final buildingAge = currentYear - building.yearBuilt;
      _buildingAgeController.text = buildingAge.toString();

      // Auto-select building amenities
      _selectedAmenities.clear();
      for (final amenity in building.amenities) {
        final buildingAmenity = _mapStringToAmenity(amenity);
        if (buildingAmenity != null) {
          _selectedAmenities.add(buildingAmenity);
        }
      }
    }
  }

  BuildingAmenity? _mapStringToAmenity(String amenityString) {
    switch (amenityString.toLowerCase()) {
      case 'pool':
      case 'בריכה':
        return BuildingAmenity.swimmingPool;
      case 'gym':
      case 'חדר כושר':
        return BuildingAmenity.gym;
      case 'garden':
      case 'גינה':
        return BuildingAmenity.garden;
      case 'playground':
      case 'גן משחקים':
        return BuildingAmenity
            .wheelchairAccess; // map generic outdoor facility to accessibility
      case 'security':
      case 'אבטחה':
        return BuildingAmenity.securitySystem;
      case 'concierge':
      case 'אינטרקום':
        return BuildingAmenity.intercom;
      case 'elevator':
      case 'מעלית':
        return BuildingAmenity.elevator;
      case 'parking':
      case 'חניה':
        return BuildingAmenity.parkingGarage;
      case 'storage':
      case 'מחסן':
        return BuildingAmenity.storageRooms;
      case 'מרפסות':
      case 'balconies':
        return BuildingAmenity.balconies;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מחשבון מחיר ניהול בניין'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildBuildingSelectionCard(),
              const SizedBox(height: 16),
              _buildBuildingDetailsCard(),
              const SizedBox(height: 16),
              _buildServiceOptionsCard(),
              const SizedBox(height: 16),
              _buildAmenitiesCard(),
              const SizedBox(height: 16),
              _buildAdditionalServicesCard(),
              const SizedBox(height: 24),
              _buildCalculateButton(),
              if (_pricingResult != null) ...[
                const SizedBox(height: 24),
                _buildResultCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.calculate, size: 48, color: Colors.indigo),
            const SizedBox(height: 8),
            const Text(
              'מחשבון מחיר ניהול בניין',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'קבלו הצעת מחיר מותאמת אישית לניהול הבניין שלכם',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'בחירת בניין',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'בחרו בניין קיים כדי להיטען נתוניו אוטומטית, או השאירו ריק להזנה ידנית',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Building>(
              value: _selectedBuilding,
              decoration: const InputDecoration(
                labelText: 'בניין',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.apartment),
              ),
              hint: _isLoadingBuildings
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('טוען בניינים...'),
                      ],
                    )
                  : const Text('בחרו בניין או השאירו ריק'),
              items: _buildings.map((building) {
                return DropdownMenuItem<Building>(
                  value: building,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        building.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${building.address}, ${building.city} • ${building.totalUnits} יחידות',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _isLoadingBuildings ? null : _onBuildingSelected,
            ),
            if (_selectedBuilding != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'נתוני הבניין הוטענו אוטומטית. ניתן לערוך אותם במידת הצורך.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'פרטי הבניין',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'כתובת מלאה',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'נא להזין כתובת';
                }
                return null;
              },
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'עיר',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'נא להזין עיר';
                      }
                      return null;
                    },
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _neighborhoodController,
                    decoration: const InputDecoration(
                      labelText: 'שכונה',
                      border: OutlineInputBorder(),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalFloorsController,
                    decoration: const InputDecoration(
                      labelText: 'מספר קומות',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'נא להזין מספר קומות';
                      }
                      final number = int.tryParse(value!);
                      if (number == null || number <= 0) {
                        return 'מספר קומות לא תקין';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _totalApartmentsController,
                    decoration: const InputDecoration(
                      labelText: 'מספר דירות',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'נא להזין מספר דירות';
                      }
                      final number = int.tryParse(value!);
                      if (number == null || number <= 0) {
                        return 'מספר דירות לא תקין';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _apartmentsPerFloorController,
                    decoration: const InputDecoration(
                      labelText: 'דירות בקומה',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _buildingAgeController,
                    decoration: const InputDecoration(
                      labelText: 'גיל הבניין (שנים)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final number = int.tryParse(value!);
                        if (number == null || number < 0) {
                          return 'גיל בניין לא תקין';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'אפשרויות שירות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('רמת שירות:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...ServiceTier.values.map((tier) {
              return RadioListTile<ServiceTier>(
                title: Text(tier.hebrewName),
                subtitle: Text(tier.description,
                    style: const TextStyle(fontSize: 12)),
                value: tier,
                groupValue: _selectedServiceTier,
                onChanged: (value) {
                  setState(() {
                    _selectedServiceTier = value!;
                  });
                },
              );
            }),
            const SizedBox(height: 16),
            const Text('משך חוזה:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ContractDuration>(
              value: _selectedContractDuration,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: ContractDuration.values.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(duration.hebrewName),
                      if (duration.discountMultiplier < 1.0)
                        Text(
                          '${((1 - duration.discountMultiplier) * 100).toInt()}% הנחה',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedContractDuration = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'מתקנים בבניין',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: BuildingAmenity.values.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return FilterChip(
                  label: Text(amenity.hebrewName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity);
                      } else {
                        _selectedAmenities.remove(amenity);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalServicesCard() {
    final additionalServices = {
      'security_patrol': 'סיור אבטחה - ₪800/חודש',
      'garden_maintenance': 'תחזוקת גינה - ₪600/חודש',
      'cleaning_service': 'שירותי ניקיון - ₪1,200/חודש',
      'concierge_service': 'שירות קונסיירז - ₪2,000/חודש',
      'technical_maintenance': 'תחזוקה טכנית - ₪400/חודש',
      'legal_consulting': 'ייעוץ משפטי - ₪300/חודש',
      'accounting_service': 'שירותי הנהלת חשבונות - ₪500/חודש',
      'energy_management': 'ניהול אנרגיה - ₪350/חודש',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'שירותים נוספים',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'בחרו שירותים נוספים שתרצו לכלול (אופציונלי):',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...additionalServices.entries.map((entry) {
              final isSelected =
                  _selectedAdditionalServices.contains(entry.key);
              return CheckboxListTile(
                title: Text(entry.value),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedAdditionalServices.add(entry.key);
                    } else {
                      _selectedAdditionalServices.remove(entry.key);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _isCalculating ? null : _calculatePrice,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: _isCalculating
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('חשב מחיר'),
    );
  }

  Widget _buildResultCard() {
    if (_pricingResult == null) return const SizedBox();

    final result = _pricingResult!;

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'הצעת מחיר',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo),
              ),
              child: Column(
                children: [
                  Text(
                    '₪${result.monthlyPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const Text('לחודש', style: TextStyle(fontSize: 16)),
                  if (result.contractMultiplier < 1.0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'מחיר מלא: ₪${(result.monthlyPrice / result.contractMultiplier).toStringAsFixed(0)}',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceBreakdown(result),
            if (_selectedBuilding != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSavingFinance ? null : _generateFinancialRecords,
                icon: const Icon(Icons.account_balance),
                label: const Text('הוסף להכנסות במערכת הפיננסית'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'הכנסה זו תתווסף כחשבון טיוטה במערכת הפיננסית ותוכלו לנהל אותה משם',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning,
                        color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'בחרו בניין כדי להוסיף את ההכנסה למערכת הפיננסית',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(PricingResult result) {
    return ExpansionTile(
      title: const Text('פירוט המחיר'),
      children: [
        ListTile(
          title: const Text('מחיר בסיס'),
          trailing: Text('₪${result.basePrice.toStringAsFixed(0)}'),
        ),
        ListTile(
          title: Text('מיקום (${result.breakdown.locationPricing.priceZone})'),
          trailing: Text('×${result.locationMultiplier.toStringAsFixed(2)}'),
        ),
        ListTile(
          title: const Text('מורכבות הבניין'),
          trailing: Text('×${result.complexityMultiplier.toStringAsFixed(2)}'),
        ),
        ListTile(
          title: Text('רמת שירות (${_selectedServiceTier.hebrewName})'),
          trailing: Text('×${result.serviceTierMultiplier.toStringAsFixed(2)}'),
        ),
        if (result.contractMultiplier < 1.0)
          ListTile(
            title: Text('הנחת חוזה (${_selectedContractDuration.hebrewName})'),
            trailing: Text('×${result.contractMultiplier.toStringAsFixed(2)}'),
          ),
        if (result.additionalServicesPrice > 0)
          ListTile(
            title: const Text('שירותים נוספים'),
            trailing:
                Text('+₪${result.additionalServicesPrice.toStringAsFixed(0)}'),
          ),
        const Divider(),
        ListTile(
          title:
              const Text('סה"כ', style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(
            '₪${result.finalPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _calculatePrice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final buildingProfile = BuildingProfile(
        address: _addressController.text,
        latitude: 0.0, // TODO: Integrate with geocoding service
        longitude: 0.0,
        city: _cityController.text,
        neighborhood: _neighborhoodController.text,
        totalFloors: int.parse(_totalFloorsController.text),
        totalApartments: int.parse(_totalApartmentsController.text),
        apartmentsPerFloor: int.tryParse(_apartmentsPerFloorController.text) ??
            (int.parse(_totalApartmentsController.text) /
                    int.parse(_totalFloorsController.text))
                .round(),
        buildingAge: int.tryParse(_buildingAgeController.text) ?? 0,
        buildingType: _selectedBuildingType,
        amenities: _selectedAmenities,
        hasElevator: _hasElevator,
        hasStorage: _hasStorage,
        hasBalconies: _hasBalconies,
      );

      final request = PricingRequest(
        buildingId: _selectedBuilding?.id ??
            'temp-${DateTime.now().millisecondsSinceEpoch}',
        buildingProfile: buildingProfile,
        serviceTier: _selectedServiceTier,
        contractDuration: _selectedContractDuration,
        additionalServices: _selectedAdditionalServices,
      );

      final result = await _pricingService.calculatePrice(request);

      setState(() {
        _pricingResult = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בחישוב המחיר: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<void> _generateFinancialRecords() async {
    if (_pricingResult == null || _selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש לבחור בניין ולחשב מחיר לפני יצירת רשומות פיננסיות'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isSavingFinance) return;
    setState(() {
      _isSavingFinance = true;
    });

    try {
      final result = _pricingResult!;
      final building = _selectedBuilding!;

      // Create an invoice item for the management fee
      final invoiceItem = InvoiceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: 'דמי ניהול חודשיים - ${building.name}',
        quantity: 1,
        unitPrice: result.monthlyPrice,
        taxRate: 0.0, // No tax on management fees typically
      );

      // Create deterministic invoice number per building-month
      final now = DateTime.now();
      final monthKey = '${now.year}${now.month.toString().padLeft(2, '0')}';
      final stableInvoiceNumber = 'MNG-${building.id}-$monthKey';

      // Create invoice
      final invoice = Invoice(
        id: 'pricing_${DateTime.now().millisecondsSinceEpoch}',
        buildingId: building.id,
        invoiceNumber: stableInvoiceNumber,
        type: InvoiceType.management,
        status: InvoiceStatus.draft,
        issueDate: now,
        dueDate: DateTime(now.year, now.month, 1).add(const Duration(days: 30)),
        items: [invoiceItem],
        subtotal: invoiceItem.subtotal,
        taxAmount: invoiceItem.taxAmount,
        total: invoiceItem.subtotal + invoiceItem.taxAmount,
        notes:
            'חשבון שנוצר ממחשבון התמחור - רמת שירות: ${_selectedServiceTier.hebrewName}, משך חוזה: ${_selectedContractDuration.hebrewName}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Persist invoice to Firestore
      await FirebaseFinancialService.addInvoice(building.id, invoice);

      // Add expenses for selected additional services
      if (_selectedAdditionalServices.isNotEmpty) {
        final Map<String, double> servicePricing =
            result.breakdown.additionalServicesPricing;

        ExpenseCategory mapServiceToCategory(String key) {
          switch (key) {
            case 'security_patrol':
              return ExpenseCategory.security;
            case 'garden_maintenance':
              return ExpenseCategory.gardening;
            case 'cleaning_service':
              return ExpenseCategory.cleaning;
            case 'concierge_service':
              return ExpenseCategory.management;
            case 'technical_maintenance':
              return ExpenseCategory.maintenance;
            case 'legal_consulting':
              return ExpenseCategory.legal;
            case 'accounting_service':
              return ExpenseCategory.management;
            case 'energy_management':
              return ExpenseCategory.utilities;
            default:
              return ExpenseCategory.other;
          }
        }

        String serviceTitle(String key) {
          switch (key) {
            case 'security_patrol':
              return 'סיור אבטחה';
            case 'garden_maintenance':
              return 'תחזוקת גינה';
            case 'cleaning_service':
              return 'שירותי ניקיון';
            case 'concierge_service':
              return 'שירות קונסיירז';
            case 'technical_maintenance':
              return 'תחזוקה טכנית';
            case 'legal_consulting':
              return 'ייעוץ משפטי';
            case 'accounting_service':
              return 'שירותי הנהלת חשבונות';
            case 'energy_management':
              return 'ניהול אנרגיה';
            default:
              return key;
          }
        }

        for (final serviceKey in _selectedAdditionalServices) {
          final amount = servicePricing[serviceKey] ?? 0.0;
          if (amount <= 0) continue;

          final expense = Expense(
            id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
            buildingId: building.id,
            title: serviceTitle(serviceKey),
            description: 'נוצר מהמחשבון עבור ${building.name}',
            category: mapServiceToCategory(serviceKey),
            status:
                amount <= 2000 ? ExpenseStatus.approved : ExpenseStatus.pending,
            priority: ExpensePriority.normal,
            amount: amount,
            vendorName: null,
            expenseDate: DateTime(now.year, now.month, 1),
            dueDate:
                DateTime(now.year, now.month, 1).add(const Duration(days: 30)),
            approvedBy: amount <= 2000 ? 'system' : null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await FirebaseFinancialService.addExpense(building.id, expense);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('נוספה הכנסה והוצאות נלוות מהמחשבון'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה ביצירת רשומות פיננסיות: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingFinance = false;
        });
      }
    }
  }

  String _getBuildingTypeText(BuildingType type) {
    switch (type) {
      case BuildingType.residential:
        return 'מגורים';
      case BuildingType.commercial:
        return 'מסחרי';
      case BuildingType.mixedUse:
        return 'מעורב';
      case BuildingType.luxury:
        return 'יוקרה';
      case BuildingType.studentHousing:
        return 'דיור סטודנטים';
    }
  }
}

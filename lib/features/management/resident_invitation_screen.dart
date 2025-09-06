import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';
import '../../services/firebase_building_service.dart';
import '../../core/config/app_links.dart';
import '../../core/models/user.dart';
import '../../core/utils/phone_number_formatter.dart';

class ResidentInvitationScreen extends StatefulWidget {
  const ResidentInvitationScreen({super.key});

  @override
  State<ResidentInvitationScreen> createState() => _ResidentInvitationScreenState();
}

class _ResidentInvitationScreenState extends State<ResidentInvitationScreen> {
  int? _totalUnits;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _unitController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isCreating = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isFormattingPhone = false;

  @override
  void initState() {
    super.initState();
    _loadBuildingLimits();
    // Ensure any pre-filled phone value is formatted on load
    if (_phoneController.text.isNotEmpty) {
      final formatted = PhoneNumberFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: _phoneController.text),
      );
      _phoneController.value = formatted;
    }

    // Listen for programmatic changes (e.g., autofill) and format consistently
    _phoneController.addListener(() {
      if (_isFormattingPhone) return;
      final current = _phoneController.text;
      if (current.isEmpty) return;
      final formatted = PhoneNumberFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: current),
      );
      if (formatted.text != current) {
        _isFormattingPhone = true;
        _phoneController.value = formatted;
        _isFormattingPhone = false;
      }
    });
  }

  Future<void> _loadBuildingLimits() async {
    try {
      final ctx = BuildingContextService.currentBuilding;
      if (ctx == null) return;
      final b = await FirebaseBuildingService.getBuildingById(ctx.buildingId);
      if (b != null) setState(() => _totalUnits = b.totalUnits);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _unitController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _inviteResident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final buildingContext = BuildingContextService.currentBuilding!;
      final email = _emailController.text.trim().toLowerCase();
      final name = _nameController.text.trim();
      const defaultPassword = '123456';

      // Try to create Auth user; if email is already in use, continue anyway
      String effectiveEmail = email;
      try {
        final authUser = await AuthService.createFirebaseAuthAccount(email, defaultPassword);
        print('✅ Firebase Auth account created: ${authUser.email}');
        effectiveEmail = authUser.email ?? email;
      } catch (e) {
        print('ℹ️ Skipping Auth creation: $e');
      }

      // Try to create app user; if user exists, continue (manager still shares link)
      try {
        await AuthService.createUser(
          email: effectiveEmail,
          name: name,
          role: UserRole.resident,
          buildingAccess: {buildingContext.buildingId: 'read'},
          unitAccess: {_unitController.text.trim(): buildingContext.buildingId},
        );
      } catch (e) {
        print('ℹ️ Skipping user doc creation (might exist): $e');
      }

      // Generate canonical invitation link for resident portal
      final invitationLink = AppLinks.buildingPortal(
        buildingContext.buildingCode,
        canonical: true,
      );

      setState(() {
        _successMessage = 'הדייר הוזמן בהצלחה!\n'
            'שתף קישור זה: $invitationLink\n'
            'דוא"ל (אם רלוונטי): $effectiveEmail\n'
            'סיסמה זמנית (אם נוצר משתמש חדש): 123456';
      });

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _unitController.clear();
      _phoneController.clear();

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _copyInvitationDetails() {
    if (_successMessage != null) {
      Clipboard.setData(ClipboardData(text: _successMessage!));
      ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('פרטי ההזמנה הועתקו ללוח'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildingContext = BuildingContextService.currentBuilding;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('הזמן דייר חדש'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Building info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.indigo, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buildingContext?.buildingName ?? 'בניין לא ידוע',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'הזמן דיירים לפורטל הבניין',
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

            // Invitation form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
'פרטי דייר חדש',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
labelText: 'שם מלא *',
                          hintText: 'הכנס שם מלא של הדייר',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
return 'אנא הזן שם דייר';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
labelText: 'דואר אלקטרוני *',
                          hintText: 'הכנס דוא"ל של הדייר',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
return 'אנא הזן דואר אלקטרוני';
                          }
                          if (!value.contains('@')) {
return 'אנא הזן דוא"ל תקין';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(
labelText: 'מספר דירה *',
                                hintText: 'לדוגמה: 4, 12, 101',
                                prefixIcon: Icon(Icons.home),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'אנא הזן מספר דירה';
                                }
                                final numVal = int.tryParse(value.trim());
                                if (numVal != null && _totalUnits != null) {
                                  if (numVal < 1 || numVal > _totalUnits!) {
                                    return 'מספר הדירה חייב להיות בין 1 ל-$_totalUnits';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
labelText: 'מספר טלפון',
                                hintText: 'לא חובה',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              textDirection: TextDirection.ltr,
                              inputFormatters: [
                                PhoneNumberFormatter(),
                                LengthLimitingTextInputFormatter(13),
                              ],
                            ),
                          ),
                        ],
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

                      // Success message
                      if (_successMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.green),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'הזמנה נוצרה!',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _copyInvitationDetails,
                                    icon: const Icon(Icons.copy, color: Colors.green),
tooltip: 'העתק פרטים',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _successMessage!,
                                style: const TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),

                      // Create button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isCreating ? null : _inviteResident,
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
                                    Text('יוצר הזמנה...'),
                                  ],
                                )
: const Text(
                                  'יצירת משתמש לדייר ושליחת הזמנה',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
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
                          'איך זה עובד:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. מלא את פרטי הדייר למעלה'),
                    const Text('2. לחץ על "יצירת משתמש לדייר ושליחת הזמנה"'),
                    const Text('3. שתף את הקישור שנוצר עם הדייר'),
                    const Text('4. הדייר ייכנס לפורטל הבניין דרך הקישור'),
                    const Text('5. ניתן לצפות בתשלומים, לשלוח בקשות ולראות מידע על הבניין')
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
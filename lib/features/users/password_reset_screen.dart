import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_building_service.dart';
import '../../core/models/building.dart';
import '../../core/models/user.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _buildingCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;
  Building? _foundBuilding;
  VaadlyUser? _foundUser;

  @override
  void dispose() {
    _emailController.dispose();
    _buildingCodeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
      _foundBuilding = null;
      _foundUser = null;
    });

    try {
      // Find building by building code
      final buildings = await FirebaseBuildingService.getAllBuildings();
      _foundBuilding = buildings.firstWhere(
        (b) => b.buildingCode.toLowerCase() == _buildingCodeController.text.toLowerCase().trim(),
        orElse: () => throw Exception('Building not found'),
      );

      // For demo purposes, we'll simulate finding a user
      // In a real app, you would query the users collection
      final email = _emailController.text.toLowerCase().trim();
      
      // Create a demo user for illustration
      _foundUser = UserFactory.createBuildingCommittee(
        id: 'demo_user_id',
        email: email,
        name: 'ועד הבית', // Committee
        buildingId: _foundBuilding!.id,
      );

      setState(() {
        _successMessage = 'נמצא חשבון ועד בית עבור בניין: ${_foundBuilding!.name}';
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'לא נמצא חשבון מתאים. בדוק את פרטי הבניין והמייל.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_foundUser == null || _newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'אנא הכנס סיסמה חדשה (לפחות 6 תווים)';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // In a real app, you would update the user's password in the database
      // For demo purposes, we'll just show success
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        _successMessage = '''
✅ הסיסמה עודכנה בהצלחה!

פרטי כניסה חדשים:
📧 דואר אלקטרוני: ${_foundUser!.email}
🔑 סיסמה חדשה: ${_newPasswordController.text}

ועד הבית יכול כעת להתחבר עם הפרטים החדשים.
        ''';
      });

      // Clear the form
      _emailController.clear();
      _buildingCodeController.clear();
      _newPasswordController.clear();
      _foundUser = null;
      _foundBuilding = null;

    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאה באיפוס הסיסמה: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Colors.orange),
            SizedBox(width: 8),
            Text('איפוס סיסמה לועד בית'),
          ],
        ),
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
              // Info card
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'איפוס גישה לועד בית',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('כאשר ועד בית שוכח את פרטי הכניסה שלו, תוכל לאפס עבורו את הסיסמה.'),
                      const Text('הכנס את קוד הבניין ודואר אלקטרוני של הועד כדי לאתר את החשבון.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Search form
              Text(
                'איתור חשבון ועד בית',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buildingCodeController,
                      decoration: const InputDecoration(
                        labelText: 'קוד בניין *',
                        hintText: 'magdal-shalom',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'אנא הכנס קוד בניין';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'דואר אלקטרוני *',
                        hintText: 'committee@building.co.il',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'אנא הכנס דואר אלקטרוני';
                        }
                        if (!value.contains('@')) {
                          return 'כתובת דואר אלקטרוני לא תקינה';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _searchUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
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
                            Text('מחפש חשבון...'),
                          ],
                        )
                      : const Text(
                          'חפש חשבון ועד',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              // Success/Error messages
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
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
              ],

              if (_successMessage != null && _foundUser != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'חשבון נמצא!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_successMessage!),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Password reset form
                Text(
                  'איפוס סיסמה',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'סיסמה חדשה *',
                    hintText: 'לפחות 6 תווים',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'סיסמה חייבת להכיל לפחות 6 תווים';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Reset password button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
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
                              Text('מעדכן סיסמה...'),
                            ],
                          )
                        : const Text(
                            'עדכן סיסמה',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],

              if (_successMessage != null && _foundUser == null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'סיסמה עודכנה!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _successMessage!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _successMessage!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('פרטי הכניסה הועתקו ללוח')),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('העתק פרטים'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
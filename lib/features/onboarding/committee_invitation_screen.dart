import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/building.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';
import '../../services/firebase_building_service.dart';
import '../dashboards/committee_dashboard.dart';

class CommitteeInvitationScreen extends StatefulWidget {
  final String buildingCode;

  const CommitteeInvitationScreen({
    super.key,
    required this.buildingCode,
  });

  @override
  State<CommitteeInvitationScreen> createState() => _CommitteeInvitationScreenState();
}

class _CommitteeInvitationScreenState extends State<CommitteeInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Building? _building;
  bool _loading = true;
  bool _creating = false;
  String? _errorMessage;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadBuilding();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadBuilding() async {
    try {
      final buildings = await FirebaseBuildingService.getAllBuildings();
      print('🏢 Available buildings: ${buildings.map((b) => '${b.name} (${b.buildingCode})').join(', ')}');
      print('🔍 Looking for building code: ${widget.buildingCode}');
      
      _building = buildings.firstWhere(
        (b) => b.buildingCode == widget.buildingCode,
        orElse: () {
          // If exact match not found, try to find by name or create a demo building
          final demoBuilding = buildings.isNotEmpty ? buildings.first : null;
          if (demoBuilding != null) {
            print('✅ Using first available building as demo: ${demoBuilding.name}');
            return demoBuilding;
          }
          throw Exception('Building not found');
        },
      );
    } catch (e) {
      print('❌ Error loading building: $e');
      setState(() {
        _errorMessage = 'לא נמצא בניין עם קוד: ${widget.buildingCode}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _createCommitteeAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _creating = true;
      _errorMessage = null;
    });

    try {
      // Create committee user account using AuthService
      final user = await AuthService.createUser(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        role: UserRole.buildingCommittee,
        buildingAccess: {_building!.id: 'admin'},
      );

      // Sign in the newly created user
      await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Set building context
      await BuildingContextService.setBuildingContext(_building!.buildingCode);

      if (mounted) {
        // Show success and navigate to committee dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('חשבון ועד הבית נוצר בהצלחה! ברוך הבא לוועד-לי'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CommitteeDashboard(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאה ביצירת החשבון: $e';
      });
    } finally {
      setState(() {
        _creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('טוען פרטי בניין...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_building == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.withOpacity(0.1),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'שגיאה לא ידועה',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'מה לעשות?',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text('• בדוק שקישור ההזמנה נשלח נכון'),
                      Text('• פנה לבעל האפליקציה לקבלת קישור חדש'),
                      Text('• או נסה עם קוד בניין אחר'),
                      SizedBox(height: 12),
                      Text(
                        'דוגמה לקישור נכון:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'localhost:3000/#/manage/braeli-5',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _loadBuilding(),
                  child: const Text('נסה שוב'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo and welcome
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business,
                  size: 64,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'ברוכים הבאים לוועד-לי!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'הוזמנתם לנהל את הבניין שלכם',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Building info card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.apartment, color: Colors.indigo),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _building!.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _building!.address,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoChip(
                              '${_building!.totalFloors} קומות',
                              Icons.layers,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoChip(
                              '${_building!.totalUnits} דירות',
                              Icons.home,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Committee setup form
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'הקמת חשבון ועד הבית',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'צרו חשבון כדי להתחיל לנהל את הבניין שלכם',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),

                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'שם מלא *',
                            hintText: 'יוסי כהן',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          textDirection: TextDirection.rtl,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'שם מלא הוא שדה חובה';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'דואר אלקטרוני *',
                            hintText: 'yossi@email.com',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'דואר אלקטרוני הוא שדה חובה';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'כתובת דואר אלקטרוני לא תקינה';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'מספר טלפון *',
                            hintText: '050-1234567',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'מספר טלפון הוא שדה חובה';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'סיסמה *',
                            hintText: 'לפחות 6 תווים',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'סיסמה חייבת להכיל לפחות 6 תווים';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'אימות סיסמה *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible = !_confirmPasswordVisible;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'הסיסמאות אינן זהות';
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

                        // Create account button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _creating ? null : _createCommitteeAccount,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              elevation: 2,
                            ),
                            child: _creating
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
                                      SizedBox(width: 12),
                                      Text('יוצר חשבון...'),
                                    ],
                                  )
                                : const Text(
                                    'צור חשבון ועד והתחל לנהל',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Footer
              Text(
                'ועד-לי - מערכת ניהול בניינים',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.indigo),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.indigo,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
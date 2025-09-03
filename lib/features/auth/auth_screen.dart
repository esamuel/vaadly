import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'app_owner_auth_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Navigate to appropriate dashboard based on user role
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setDemoUser(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = '123456';
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and title
                      Icon(
                        Icons.business,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vaadly',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'ועד-לי',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'מערכת ניהול בניינים רב-דיירים',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Login form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'דואר אלקטרוני',
                                hintText: 'הכנס כתובת דואר אלקטרוני',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'אנא הכנס כתובת דואר אלקטרוני';
                                }
                                if (!value.contains('@')) {
                                  return 'אנא הכנס כתובת דואר אלקטרוני תקינה';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'סיסמה',
                                hintText: 'הכנס סיסמה',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'אנא הכנס סיסמה';
                                }
                                if (value.length < 6) {
                                  return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _signIn(),
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

                            // Sign in button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
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
                                          Text('מתחבר...'),
                                        ],
                                      )
                                    : const Text(
                                        'התחבר',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App Owner Portal Link
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AppOwnerAuthScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.business_center),
                          label: const Text('App Owner Portal'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.indigo.withOpacity(0.5)),
                            foregroundColor: Colors.indigo,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Demo users section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎭 משתמשי הדגמה',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDemoUserButton(
                              'בעל האפליקציה',
                              'owner@vaadly.com',
                              'גישה מלאה לכל הבניינים',
                              Icons.admin_panel_settings,
                              Colors.purple,
                            ),
                            const SizedBox(height: 8),
                            _buildDemoUserButton(
                              'ועד בית',
                              'committee@shalom-tower.co.il',
                              'ניהול בניין מגדל שלום',
                              Icons.business,
                              Colors.indigo,
                            ),
                            const SizedBox(height: 8),
                            _buildDemoUserButton(
                              'דייר',
                              'resident@example.com',
                              'דירה 101 במגדל שלום',
                              Icons.person,
                              Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoUserButton(
    String role,
    String email,
    String description,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _setDemoUser(email),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
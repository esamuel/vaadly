import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/building_context_service.dart';
import '../../core/models/user.dart';

class ResidentInvitationScreen extends StatefulWidget {
  const ResidentInvitationScreen({super.key});

  @override
  State<ResidentInvitationScreen> createState() => _ResidentInvitationScreenState();
}

class _ResidentInvitationScreenState extends State<ResidentInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _unitController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isCreating = false;
  String? _errorMessage;
  String? _successMessage;

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
      
      // Create resident user
      final resident = await AuthService.createUser(
        email: _emailController.text.trim().toLowerCase(),
        name: _nameController.text.trim(),
        role: UserRole.resident,
        buildingAccess: {buildingContext.buildingId: 'read'},
        unitAccess: {_unitController.text.trim(): buildingContext.buildingId},
      );

      // Generate invitation link
      final invitationLink = 'http://localhost:3000/building/${buildingContext.buildingCode}';
      
      setState(() {
        _successMessage = 'Resident invited successfully!\n'
            'Share this link: $invitationLink\n'
            'Email: ${resident.email}\n'
            'Temporary password: 123456';
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
        const SnackBar(content: Text('Invitation details copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildingContext = BuildingContextService.currentBuilding;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite New Resident'),
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
                            buildingContext?.buildingName ?? 'Unknown Building',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Invite residents to access building portal',
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
                        'New Resident Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Enter resident\'s full name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter resident\'s name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          hintText: 'Enter resident\'s email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email address';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email address';
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
                                labelText: 'Unit Number *',
                                hintText: 'e.g., 101, A-5',
                                prefixIcon: Icon(Icons.home),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter unit number';
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
                                labelText: 'Phone Number',
                                hintText: 'Optional',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
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
                                    'Invitation Created!',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _copyInvitationDetails,
                                    icon: const Icon(Icons.copy, color: Colors.green),
                                    tooltip: 'Copy details',
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
                                    Text('Creating Invitation...'),
                                  ],
                                )
                              : const Text(
                                  'Create Resident Account & Send Invitation',
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
                          'How it works:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Fill in the resident\'s details above'),
                    const Text('2. Click "Create Resident Account & Send Invitation"'),
                    const Text('3. Share the generated link with the resident'),
                    const Text('4. Resident uses the link to access their building portal'),
                    const Text('5. They can view payments, submit requests, and see building info'),
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
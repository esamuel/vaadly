import 'package:flutter/material.dart';

/// App Owner Dashboard - Your main SaaS business control center
/// This is where YOU manage your entire Vaadly platform
class AppOwnerDashboard extends StatefulWidget {
  const AppOwnerDashboard({super.key});

  @override
  State<AppOwnerDashboard> createState() => _AppOwnerDashboardState();
}

class _AppOwnerDashboardState extends State<AppOwnerDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.business_center, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Vaadly - App Owner Dashboard'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center,
              size: 64,
              color: Colors.indigo,
            ),
            SizedBox(height: 16),
            Text(
              'App Owner Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your SaaS business control center',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              '🎉 Multi-Tenant Architecture Complete!',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
            SizedBox(height: 8),
            Text(
              'Ready to onboard building committees',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
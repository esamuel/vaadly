import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:vaadly/firebase_options.dart';
import 'package:vaadly/core/services/firebase_service.dart';
import 'package:vaadly/services/firebase_building_service.dart';
import 'package:vaadly/core/models/building.dart';

// Run with:
// flutter run -t scripts/migrate_building_codes.dart -d macos
// or: flutter run -t scripts/migrate_building_codes.dart -d chrome
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseService.initialize();
  } catch (e) {
    // ignore: avoid_print
    print('❌ Firebase init failed: $e');
    return;
  }

  runApp(const _MigratorApp());
}

class _MigratorApp extends StatelessWidget {
  const _MigratorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _MigrationScreen(),
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    );
  }
}

class _MigrationScreen extends StatefulWidget {
  const _MigrationScreen();

  @override
  State<_MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<_MigrationScreen> {
  String _log = '';
  bool _running = false;
  int _updated = 0;

  @override
  void initState() {
    super.initState();
    // Auto-run migration on launch
    // Delay a tick to ensure build context is ready for setState and logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMigration();
    });
  }

  void _append(String line) {
    setState(() {
      _log += '$line\n';
    });
    // Also print to console
    // ignore: avoid_print
    print(line);
  }

  bool _isInvalidCode(String code) {
    if (code.isEmpty) return true;
    if (code.length < 3) return true;
    if (RegExp(r'^[0-9\-]+$').hasMatch(code)) return true; // numeric-only/dashes
    if (code.startsWith('-')) return true;
    if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(code)) return true;
    return false;
  }

  String _slugify(String name) {
    var base = name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    base = base
        .replaceAll(RegExp(r'^-+'), '')
        .replaceAll(RegExp(r'-+$'), '');

    final isNumericOnly = RegExp(r'^[0-9\-]+$').hasMatch(base);
    if (base.length < 3 || isNumericOnly) {
      final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      base = 'b-${ts.substring(ts.length - 5)}';
    }
    return base;
  }

  Future<String> _ensureUniqueCode(String desired, List<Building> all) async {
    // If desired conflicts, append base36 suffix until unique
    String candidate = desired;
    int tries = 0;
    final existing = all.map((b) => b.buildingCode).toSet();
    while (existing.contains(candidate)) {
      final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final suffix = ts.substring(ts.length - 3);
      candidate = '$desired-$suffix';
      tries++;
      if (tries > 5) break; // avoid infinite loops
    }
    return candidate;
  }

  Future<void> _runMigration() async {
    if (_running) return;
    setState(() {
      _running = true;
      _log = '';
      _updated = 0;
    });

    try {
      _append('📋 Loading buildings...');
      final buildings = await FirebaseBuildingService.getAllBuildings();
      _append('✅ Found ${buildings.length} buildings');

      for (final b in buildings) {
        final old = b.buildingCode.trim();
        if (_isInvalidCode(old)) {
          final desired = _slugify(b.name.isNotEmpty ? b.name : 'building');
          final unique = await _ensureUniqueCode(desired, buildings);
          _append('🛠️ ${b.id}: "$old" -> "$unique"');

          final updated = b.copyWith(buildingCode: unique);
          final result = await FirebaseBuildingService.updateBuilding(updated);
          if (result != null) {
            _updated++;
          }
        }
      }

      _append('🎉 Migration finished. Updated: $_updated');
    } catch (e) {
      _append('❌ Migration failed: $e');
    } finally {
      setState(() {
        _running = false;
      });
      // Exit shortly after finishing so this can run headlessly
      await Future.delayed(const Duration(seconds: 1));
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Migrate Building Codes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This tool updates invalid building codes to robust slugs.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('- Avoid numeric-only/too-short codes'),
            const Text('- Keep lowercase, a-z, 0-9 and dashes'),
            const Text('- Ensure uniqueness (appends base36 suffix if needed)'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _running ? null : _runMigration,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Migration'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

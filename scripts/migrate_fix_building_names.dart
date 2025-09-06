import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vaadly/core/services/firebase_service.dart';
import 'package:vaadly/firebase_options.dart';

// Run with (recommended):
// flutter run -t scripts/migrate_fix_building_names.dart -d macos --dart-define=DRY_RUN=true
// or to actually write changes:
// flutter run -t scripts/migrate_fix_building_names.dart -d macos --dart-define=DRY_RUN=false
//
// This script scans all buildings (collection group) and replaces any
// occurrences of the incorrect value 'לוי אשכול 24' in name/address with
// the corrected value 'בורלא 14'.

const bool kDryRun = bool.fromEnvironment('DRY_RUN', defaultValue: true);
const String kOldValue = 'לוי אשכול 24';
const String kNewValue = 'בורלא 14';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const _MigrationScreen(),
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
  int _scanned = 0;
  int _matched = 0;
  int _updated = 0;

  @override
  void initState() {
    super.initState();
    // Auto-run after first frame to allow setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMigration();
    });
  }

  void _append(String line) {
    setState(() {
      _log += '$line\n';
    });
    // ignore: avoid_print
    print(line);
  }

  Future<void> _runMigration() async {
    if (_running) return;
    setState(() {
      _running = true;
      _log = '';
      _scanned = 0;
      _matched = 0;
      _updated = 0;
    });

    try {
      _append('🚀 Starting migration: fix building names/addresses');
      _append('Mode: ${kDryRun ? 'DRY RUN (no writes)' : 'APPLY CHANGES'}');

      final firestore = FirebaseFirestore.instance;

      // Try filtered queries first; if indexes are missing, fall back to scanning all
      final paths = <String, DocumentReference>{};
      bool usedFallback = false;

      try {
        _append('🔎 Querying buildings where name == "$kOldValue" ...');
        final byName = await firestore
            .collectionGroup('buildings')
            .where('name', isEqualTo: kOldValue)
            .get();
        for (final doc in byName.docs) {
          paths[doc.reference.path] = doc.reference;
        }

        _append('🔎 Querying buildings where address == "$kOldValue" ...');
        final byAddress = await firestore
            .collectionGroup('buildings')
            .where('address', isEqualTo: kOldValue)
            .get();
        for (final doc in byAddress.docs) {
          paths[doc.reference.path] = doc.reference;
        }
      } catch (e) {
        usedFallback = true;
        _append('⚠️ Filtered query failed (likely missing index). Falling back to scan-all...');
        final all = await firestore.collectionGroup('buildings').get();
        for (final doc in all.docs) {
          final data = doc.data();
          final name = (data['name'] as String? ?? '').trim();
          final address = (data['address'] as String? ?? '').trim();
          if (name == kOldValue || address == kOldValue) {
            paths[doc.reference.path] = doc.reference;
          }
        }
      }

      _append('📋 Found ${paths.length} building documents to examine${usedFallback ? ' (via scan-all fallback)' : ''}');

      for (final ref in paths.values) {
        _scanned++;
        final snap = await ref.get();
        if (!snap.exists) continue;
        final data = snap.data() as Map<String, dynamic>;

        final name = (data['name'] as String? ?? '').trim();
        final address = (data['address'] as String? ?? '').trim();

        bool needsUpdate = false;
        final updates = <String, dynamic>{};

        if (name == kOldValue) {
          needsUpdate = true;
          updates['name'] = kNewValue;
        }
        if (address == kOldValue) {
          needsUpdate = true;
          updates['address'] = kNewValue;
        }

        if (needsUpdate) {
          _matched++;
          updates['updatedAt'] = FieldValue.serverTimestamp();
          _append('🛠️ ${ref.path}: ${name == kOldValue ? 'name' : ''}${name == kOldValue && address == kOldValue ? ' & ' : ''}${address == kOldValue ? 'address' : ''} -> "$kNewValue"');

          if (!kDryRun) {
            await ref.update(updates);
            _updated++;
          }
        }
      }

      _append('\n✅ Migration complete.');
      _append('Scanned: $_scanned');
      _append('Matched: $_matched');
      _append('Updated: $_updated');
    } catch (e, st) {
      _append('❌ Migration failed: $e');
      // ignore: avoid_print
      print(st);
    } finally {
      setState(() {
        _running = false;
      });
      // Exit shortly after finishing so this can run headlessly (non-web)
      if (!kIsWeb) {
        await Future.delayed(const Duration(seconds: 1));
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Building Names/Addresses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This tool replaces "$kOldValue" with "$kNewValue" in building name/address across tenants.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('DRY_RUN: $kDryRun'),
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

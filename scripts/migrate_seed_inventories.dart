import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';
import '../lib/services/asset_inventory_service.dart';

// Usage:
// dart run scripts/migrate_seed_inventories.dart
// Seeds storages/parking inventories for existing buildings that don't have them yet
Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  print('🔎 Scanning buildings...');
  final buildingsSnap = await db.collection('buildings').get();
  print('📦 Found ${buildingsSnap.size} buildings');

  int seeded = 0;
  int skipped = 0;
  for (final doc in buildingsSnap.docs) {
    final data = doc.data();
    final buildingId = doc.id;
    final storageUnits = (data['storageUnits'] ?? 0) as int;
    final parkingSpaces = (data['parkingSpaces'] ?? 0) as int;

    // Count existing subcollections (basic scan)
    final storagesSnap = await db.collection('buildings').doc(buildingId).collection('storages').limit(1).get();
    final parkingSnap = await db.collection('buildings').doc(buildingId).collection('parking').limit(1).get();

    final needStorages = storageUnits > 0 && storagesSnap.size == 0;
    final needParking = parkingSpaces > 0 && parkingSnap.size == 0;

    if (needStorages || needParking) {
      print('➡️  Seeding building $buildingId (storages=$storageUnits, parking=$parkingSpaces)');
      await AssetInventoryService.seedInventoryForBuilding(
        buildingId: buildingId,
        storageCount: needStorages ? storageUnits : 0,
        parkingCount: needParking ? parkingSpaces : 0,
      );
      seeded++;
    } else {
      skipped++;
    }
  }

  print('✅ Done. Seeded: $seeded, skipped: $skipped');
}


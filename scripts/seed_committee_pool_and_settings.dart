import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vaadly/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  final db = FirebaseFirestore.instance;

  const buildingId = 'demo_building_1';

  // Seed a few committee vendor profiles
  final profiles = [
    {
      'name': 'Glow Electric',
      'contactEmail': 'service@glow-elec.co.il',
      'contactPhone': '+972-50-700-0001',
      'serviceCategories': ['electrical'],
      'coverageRegions': ['tel-aviv'],
      'ratingAvg': 4.3,
      'jobsDone': 40,
      'slaAvgHours': 12.0,
    },
    {
      'name': 'Garden Care',
      'contactEmail': 'hello@gcare.co.il',
      'contactPhone': '+972-50-700-0002',
      'serviceCategories': ['gardening'],
      'coverageRegions': ['tel-aviv'],
      'ratingAvg': 4.7,
      'jobsDone': 55,
      'slaAvgHours': 24.0,
    },
  ];

  final buildingRef = db.collection('buildings').doc(buildingId);
  final profilesRef = buildingRef.collection('committee_vendor_profiles');
  final vendorIds = <String>[];
  for (final p in profiles) {
    final doc = profilesRef.doc();
    await doc.set(p);
    vendorIds.add(doc.id);
  }

  // Create/update default committee pool
  final poolRef = buildingRef.collection('committee_vendor_pools').doc('default');
  await poolRef.set({
    'poolId': 'default',
    'name': 'בריכת ועד הבית (ברירת מחדל)',
    'scope': 'committee',
    'active': true,
    'vendorIds': vendorIds,
    'services': [],
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // Create/update settings/maintenance document
  final settingsRef = buildingRef.collection('settings').doc('maintenance');
  await settingsRef.set({
    'managementMode': 'committeeManaged',
    'committeePoolId': 'default',
    'appOwnerPoolId': 'default_app_owner_pool',
    'costPolicy': {
      'autoCompareThresholdIls': 500,
      'minQuotes': 2,
      'weightPrice': 0.6,
      'weightRating': 0.25,
      'weightSla': 0.15,
    }
  }, SetOptions(merge: true));

  // Done
  // ignore: avoid_print
  print('✅ Seeded committee vendor profiles (${vendorIds.length}), pool=default and settings for buildingId=$buildingId');
}

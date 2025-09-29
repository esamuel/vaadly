import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vaadly/firebase_options.dart';
import 'package:vaadly/core/models/maintenance/enums.dart';
import 'package:vaadly/core/models/maintenance/vendor_profile.dart';
import 'package:vaadly/core/models/maintenance/vendor_pool.dart';

// Run with: flutter pub run dart run scripts/seed_vendors.dart
// Seeds demo vendors into app_owners/{ownerId}/vendor_profiles and a default pool.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  final db = FirebaseFirestore.instance;

  const ownerId = 'demo_app_owner';

  final vendors = <VendorProfile>[
    VendorProfile(
      vendorId: 'v_plumbing_a',
      name: 'AquaFix Plumbing',
      contactEmail: 'contact@aquafix.co.il',
      contactPhone: '+972-50-111-1111',
      serviceCategories: [ServiceCategory.plumbing],
      coverageRegions: ['tel-aviv', 'gush-dan'],
      ratingAvg: 4.6,
      jobsDone: 120,
      slaAvgHours: 8,
      calloutFeeIls: 150,
      hourlyRateIls: 220,
      minHours: 1,
    ),
    VendorProfile(
      vendorId: 'v_electrical_a',
      name: 'VoltMaster Electric',
      contactEmail: 'info@voltmaster.co.il',
      contactPhone: '+972-50-222-2222',
      serviceCategories: [ServiceCategory.electrical],
      coverageRegions: ['tel-aviv'],
      ratingAvg: 4.5,
      jobsDone: 95,
      slaAvgHours: 12,
      calloutFeeIls: 180,
      hourlyRateIls: 240,
      minHours: 1,
    ),
    VendorProfile(
      vendorId: 'v_elevator_a',
      name: 'ElevatePro',
      contactEmail: 'support@elevatepro.co.il',
      contactPhone: '+972-50-333-3333',
      serviceCategories: [ServiceCategory.elevator],
      coverageRegions: ['tel-aviv'],
      ratingAvg: 4.2,
      jobsDone: 70,
      slaAvgHours: 6,
    ),
    VendorProfile(
      vendorId: 'v_gardening_a',
      name: 'GreenLeaf Gardening',
      contactEmail: 'team@greenleaf.co.il',
      contactPhone: '+972-50-444-4444',
      serviceCategories: [ServiceCategory.gardening],
      coverageRegions: ['tel-aviv'],
      ratingAvg: 4.7,
      jobsDone: 60,
      slaAvgHours: 24,
      calloutFeeIls: 120,
      hourlyRateIls: 180,
      minHours: 2,
    ),
    VendorProfile(
      vendorId: 'v_sanitation_a',
      name: 'CleanCity Sanitation',
      contactEmail: 'hello@cleancity.co.il',
      contactPhone: '+972-50-555-5555',
      serviceCategories: [ServiceCategory.sanitation],
      coverageRegions: ['tel-aviv'],
      ratingAvg: 4.4,
      jobsDone: 80,
      slaAvgHours: 24,
    ),
  ];

  final batch = db.batch();
  final ownerDoc = db.collection('app_owners').doc(ownerId);
  final vendorColl = ownerDoc.collection('vendor_profiles');
  for (final v in vendors) {
    batch.set(vendorColl.doc(v.vendorId), v.toJson());
  }

  final pool = VendorPool(
    poolId: 'default_app_owner_pool',
    name: 'Default App Owner Pool',
    scope: 'app_owner',
    vendorIds: vendors.map((v) => v.vendorId).toList(),
    services: [
      ServiceCategory.plumbing,
      ServiceCategory.electrical,
      ServiceCategory.elevator,
      ServiceCategory.gardening,
      ServiceCategory.sanitation,
      ServiceCategory.general,
    ],
  );

  batch.set(ownerDoc.collection('vendor_pools').doc(pool.poolId), pool.toJson());

  await batch.commit();
  print('✅ Seeded app owner vendors and pool for ownerId=$ownerId');
}
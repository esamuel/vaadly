import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Demo data seeding script for Vaadly
// Run with: dart scripts/seed_data.dart

void main() async {
  // Initialize Firebase (you'll need to configure this)
  await Firebase.initializeApp();

  print('🌱 Seeding demo data for Vaadly...');

  try {
    await seedDemoData();
    print('✅ Demo data seeded successfully!');
  } catch (e) {
    print('❌ Error seeding demo data: $e');
  }
}

Future<void> seedDemoData() async {
  final firestore = FirebaseFirestore.instance;

  // Demo building
  const buildingId = 'demo_building_001';
  final buildingRef = firestore.collection('buildings').doc(buildingId);

  await buildingRef.set({
    'name': 'Demo Building',
    'address': '123 Demo Street, Tel Aviv',
    'totalUnits': 24,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  print('🏢 Created demo building: Demo Building');

  // Demo members
  final members = [
    {
      'uid': 'demo_admin_001',
      'buildingId': buildingId,
      'role': 'super_admin',
      'unitNumber': null,
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    },
    {
      'uid': 'demo_committee_001',
      'buildingId': buildingId,
      'role': 'committee',
      'unitNumber': '101',
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    },
    {
      'uid': 'demo_resident_001',
      'buildingId': buildingId,
      'role': 'resident',
      'unitNumber': '102',
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    },
  ];

  for (final member in members) {
    await buildingRef
        .collection('members')
        .doc(member['uid'] as String)
        .set(member);
  }

  print('👥 Created demo members');

  // Demo units
  final units = List.generate(24, (index) {
    final unitNumber = (101 + index).toString();
    return {
      'id': 'unit_$unitNumber',
      'buildingId': buildingId,
      'number': unitNumber,
      'ownerUid': index < 3 ? 'demo_resident_${index + 1}' : null,
      'status': index < 3 ? 'occupied' : 'vacant',
      'createdAt': FieldValue.serverTimestamp(),
    };
  });

  for (final unit in units) {
    await buildingRef.collection('units').doc(unit['id'] as String).set(unit);
  }

  print('🏠 Created demo units');

  // Demo vendors
  final vendors = [
    {
      'id': 'vendor_plumbing_001',
      'buildingId': buildingId,
      'name': 'Quick Fix Plumbing',
      'category': 'plumbing',
      'status': 'active',
      'rating': 4.8,
      'isDefault': true,
      'phone': '+972-50-123-4567',
      'email': 'info@quickfixplumbing.co.il',
      'services': ['plumbing', 'drainage', 'water_heater'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'vendor_electrical_001',
      'buildingId': buildingId,
      'name': 'Spark Electric',
      'category': 'electrical',
      'status': 'active',
      'rating': 4.6,
      'isDefault': true,
      'phone': '+972-50-234-5678',
      'email': 'service@sparkelectric.co.il',
      'services': ['electrical', 'lighting', 'wiring'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'vendor_cleaning_001',
      'buildingId': buildingId,
      'name': 'Clean Pro Services',
      'category': 'cleaning',
      'status': 'active',
      'rating': 4.7,
      'isDefault': true,
      'phone': '+972-50-345-6789',
      'email': 'info@cleanpro.co.il',
      'services': ['cleaning', 'maintenance', 'sanitization'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  ];

  for (final vendor in vendors) {
    await buildingRef
        .collection('vendors')
        .doc(vendor['id'] as String)
        .set(vendor);
  }

  print('👷 Created demo vendors');

  // Demo work orders
  final workOrders = [
    {
      'id': 'wo_001',
      'buildingId': buildingId,
      'title': 'Leaky Faucet in Kitchen',
      'description': 'Kitchen faucet is dripping constantly, needs repair',
      'status': 'open',
      'priority': 'normal',
      'category': 'plumbing',
      'unitNumber': '101',
      'reportedBy': 'demo_resident_001',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'mediaUrls': [],
      'dispatchReady': false,
    },
    {
      'id': 'wo_002',
      'buildingId': buildingId,
      'title': 'Broken Light Switch',
      'description': 'Light switch in hallway not working, sparks when touched',
      'status': 'open',
      'priority': 'high',
      'category': 'electrical',
      'unitNumber': '102',
      'reportedBy': 'demo_resident_001',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'mediaUrls': [],
      'dispatchReady': false,
    },
    {
      'id': 'wo_003',
      'buildingId': buildingId,
      'title': 'Lobby Cleaning Needed',
      'description': 'Lobby area needs deep cleaning, especially floor tiles',
      'status': 'open',
      'priority': 'low',
      'category': 'cleaning',
      'unitNumber': null,
      'reportedBy': 'demo_committee_001',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'mediaUrls': [],
      'dispatchReady': false,
    },
  ];

  for (final workOrder in workOrders) {
    await buildingRef
        .collection('work_orders')
        .doc(workOrder['id'] as String)
        .set(workOrder);
  }

  print('📋 Created demo work orders');

  // Demo announcements
  final announcements = [
    {
      'title': 'Welcome to Vaadly!',
      'body':
          'Welcome to our new building management system. Please report any issues through the app.',
      'type': 'welcome',
      'priority': 'normal',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Monthly Committee Meeting',
      'body':
          'Monthly committee meeting will be held on the first Sunday of each month at 7 PM.',
      'type': 'meeting',
      'priority': 'normal',
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  for (final announcement in announcements) {
    await buildingRef.collection('announcements').add(announcement);
  }

  print('📢 Created demo announcements');

  print('🎉 Demo data seeding completed!');
  print('Building ID: $buildingId');
  print('You can now test the app with this demo data.');
}

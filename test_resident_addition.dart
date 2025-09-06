#!/usr/bin/env dart
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // Test data for a new resident
  print('🧪 Testing resident addition to building: shalom1234');
  
  final testResident = {
    'buildingId': 'shalom1234',
    'firstName': 'בדיקה',
    'lastName': 'שם משפחה',
    'apartmentNumber': '10',
    'floor': '5',
    'phoneNumber': '050-9999999',
    'email': 'test@example.com',
    'residentType': 'ResidentType.tenant',
    'status': 'ResidentStatus.active',
    'moveInDate': DateTime.now().toIso8601String(),
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
    'isActive': true,
    'tags': [],
    'customFields': {},
    'notes': 'דייר לבדיקה'
  };
  
  print('📋 Test resident data:');
  testResident.forEach((key, value) {
    print('  $key: $value');
  });
  
  print('\nℹ️ To test this:');
  print('1. Sign in as committee user: committee@shalom-tower.co.il (password: 123456)');
  print('2. Navigate to the residents tab');
  print('3. Add a new resident with the above information');
  print('4. Check if the resident is saved and appears in the list');
  
  print('\n🔍 Expected behavior:');
  print('- The form should submit successfully');
  print('- The resident should appear in the residents list');
  print('- Firebase should show the new document in the residents collection');
}

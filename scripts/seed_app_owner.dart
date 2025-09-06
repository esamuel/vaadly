import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

// Usage: dart scripts/seed_app_owner.dart
// Seeds or updates an App Owner document so you can sign in via App Owner portal.
// Sign-in in the app only validates password length; access is controlled by presence of this doc.

const String kOwnerEmail = 'samuel.eskenasy@gmail.com';
const String kOwnerName = 'Samuel Eskenasy';
const String kOwnerCompany = 'Vaadly';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;

  final email = kOwnerEmail.toLowerCase().trim();
  print('🔎 Looking up app owner by email: $email');

  try {
    final query = await firestore
        .collection('app_owners')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      print('✏️ Updating existing app owner: ${doc.id}');
      await doc.reference.set({
        'email': email,
        'name': kOwnerName,
        'company': kOwnerCompany,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ Updated app owner document: ${doc.id}');
    } else {
      print('➕ Creating new app owner record');
      final ref = await firestore.collection('app_owners').add({
        'email': email,
        'name': kOwnerName,
        'company': kOwnerCompany,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Created app owner document: ${ref.id}');
    }

    print('🎉 Done. You can now sign in as App Owner with:');
    print('    Email: $kOwnerEmail');
    print('    Password: Vaadli55');
  } catch (e) {
    print('❌ Error seeding app owner: $e');
    rethrow;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static bool _initialized = false;

  // Initialize Firebase
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if Firebase config is properly set
      final options = DefaultFirebaseOptions.currentPlatform;
      print('🔍 Checking Firebase configuration...');
      print('🏢 Project: ${options.projectId}');
      print('🔑 API Key: ${options.apiKey.substring(0, 10)}...');

      if (options.apiKey.contains('YOUR_API_KEY_HERE')) {
        throw Exception('''
❌ Firebase not configured!

Please follow these steps:
1. Go to https://console.firebase.google.com/
2. Create a new project or select existing one
3. Add a web app to your project
4. Copy the config object
5. Update lib/firebase_options.dart with your real config

Current config has placeholder values!
        ''');
      }

      await Firebase.initializeApp(options: options);
      _firestore = FirebaseFirestore.instance;

      // Enable offline persistence for better UX
      await _firestore!.enablePersistence();

      _initialized = true;
      print('✅ Firebase initialized successfully');
      print('🏢 Project: ${options.projectId}');
      print('🔑 API Key: ${options.apiKey.substring(0, 10)}...');
      print('📱 Platform: ${options.appId}');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      // For web, persistence might fail, so continue without it
      if (e.toString().contains('persistence')) {
        print('⚠️ Continuing without offline persistence (normal for web)');
        _initialized = true;
      } else {
        rethrow;
      }
    }
  }

  // Get Firestore instance
  static FirebaseFirestore get firestore {
    if (!_initialized || _firestore == null) {
      throw Exception(
          'Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _firestore!;
  }

  // Generic CRUD operations
  static Future<DocumentReference> addDocument(
      String collection, Map<String, dynamic> data) async {
    try {
      final docRef = await firestore.collection(collection).add(data);
      print('✅ Document added to $collection with ID: ${docRef.id}');
      return docRef;
    } catch (e) {
      print('❌ Error adding document to $collection: $e');
      rethrow;
    }
  }

  static Future<void> updateDocument(
      String collection, String id, Map<String, dynamic> data) async {
    try {
      await firestore.collection(collection).doc(id).update(data);
      print('✅ Document updated in $collection');
    } catch (e) {
      print('❌ Error updating document in $collection: $e');
      rethrow;
    }
  }

  static Future<void> deleteDocument(String collection, String id) async {
    try {
      await firestore.collection(collection).doc(id).delete();
      print('✅ Document deleted from $collection');
    } catch (e) {
      print('❌ Error deleting document from $collection: $e');
      rethrow;
    }
  }

  static Future<QuerySnapshot> getDocuments(String collection) async {
    try {
      return await firestore.collection(collection).get();
    } catch (e) {
      print('❌ Error getting documents from $collection: $e');
      rethrow;
    }
  }

  static Future<DocumentSnapshot> getDocument(
      String collection, String id) async {
    try {
      return await firestore.collection(collection).doc(id).get();
    } catch (e) {
      print('❌ Error getting document from $collection: $e');
      rethrow;
    }
  }

  // Sample data initialization
  static Future<void> initializeSampleData() async {
    try {
      print('🚀 Initializing sample data in Firebase...');

      // Check if data already exists
      final buildingsSnapshot = await getDocuments('buildings');
      if (buildingsSnapshot.docs.isNotEmpty) {
        print('✅ Sample data already exists');
        return;
      }

      // Create sample building
      final buildingData = {
        'buildingCode': 'magdal-hashalom',
        'name': 'מגדל השלום',
        'address': 'רחוב הרצל 123, תל אביב',
        'city': 'תל אביב',
        'postalCode': '12345',
        'country': 'ישראל',
        'totalFloors': 8,
        'totalUnits': 24,
        'parkingSpaces': 30,
        'storageUnits': 24,
        'buildingArea': 2500.0,
        'yearBuilt': 2010,
        'buildingType': 'residential',
        'amenities': ['elevator', 'parking', 'garden'],
        'buildingManager': 'יוסי כהן',
        'managerPhone': '050-1234567',
        'managerEmail': 'yossi@shalom-tower.co.il',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await addDocument('buildings', buildingData);
      print('✅ Sample building created');

      // Create sample financial data
      final invoiceData = {
        'buildingId': '1',
        'invoiceNumber': 'INV-2024-001',
        'type': 'maintenance',
        'status': 'sent',
        'issueDate':
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'dueDate':
            DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        'total': 760.5,
        'notes': 'תחזוקה תקופתית למערכת המיזוג',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      };
      await addDocument('invoices', invoiceData);
      print('✅ Sample invoice created');

      final expenseData = {
        'buildingId': '1',
        'title': 'תחזוקת מעליות',
        'description': 'תחזוקה תקופתית למעליות הבניין',
        'category': 'maintenance',
        'status': 'approved',
        'amount': 1200.0,
        'expenseDate':
            DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        'createdAt':
            DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
      };
      await addDocument('expenses', expenseData);
      print('✅ Sample expense created');

      print('🎉 Sample data initialized successfully!');
    } catch (e) {
      print('❌ Error initializing sample data: $e');
      rethrow;
    }
  }
}

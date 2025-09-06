import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/vendor.dart';

class FirebaseVendorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Real-time stream of vendors for a building using flat structure
  static Stream<List<Vendor>> streamVendors(String buildingId) {
    return _firestore
        .collection('vendors')
        .where('buildingId', isEqualTo: buildingId)
        .snapshots()
        .map((snapshot) {
          final vendors = snapshot.docs
              .map((doc) => Vendor.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort by name on client side to avoid index requirement
          vendors.sort((a, b) => a.name.compareTo(b.name));
          return vendors;
        });
  }
  
  // Get all vendors
  static Future<List<Vendor>> getAllVendors() async {
    try {
      final snapshot = await _firestore
          .collection('vendors')
          .orderBy('name')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Vendor.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('❌ Error getting vendors: $e');
      return [];
    }
  }

  // Add vendor
  static Future<String?> addVendor(Vendor vendor) async {
    try {
      final docRef = await _firestore
          .collection('vendors')
          .add(vendor.toMap());
      
      print('✅ Vendor added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding vendor: $e');
      return null;
    }
  }

  // Update vendor
  static Future<bool> updateVendor(String vendorId, Vendor vendor) async {
    try {
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .update(vendor.toMap());
      
      print('✅ Vendor updated');
      return true;
    } catch (e) {
      print('❌ Error updating vendor: $e');
      return false;
    }
  }

  // Delete vendor
  static Future<bool> deleteVendor(String vendorId) async {
    try {
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .delete();
      
      print('✅ Vendor deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting vendor: $e');
      return false;
    }
  }

  // Search vendors
  static Future<List<Vendor>> searchVendors(String query) async {
    try {
      if (query.isEmpty) return await getAllVendors();

      // Firebase doesn't support complex text search, so we'll get all vendors
      // and filter on client side for now
      final allVendors = await getAllVendors();
      final lowercaseQuery = query.toLowerCase();
      
      return allVendors.where((vendor) {
        return vendor.name.toLowerCase().contains(lowercaseQuery) ||
            vendor.contactPerson.toLowerCase().contains(lowercaseQuery) ||
            vendor.phone.contains(lowercaseQuery) ||
            (vendor.email?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      print('❌ Error searching vendors: $e');
      return [];
    }
  }

  // Get vendors by category
  static Future<List<Vendor>> getVendorsByCategory(VendorCategory category) async {
    try {
      final snapshot = await _firestore
          .collection('vendors')
          .where('categories', arrayContains: category.toString().split('.').last)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Vendor.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('❌ Error getting vendors by category: $e');
      return [];
    }
  }

  // Get active vendors
  static Future<List<Vendor>> getActiveVendors() async {
    try {
      final snapshot = await _firestore
          .collection('vendors')
          .where('status', isEqualTo: VendorStatus.active.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Vendor.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('❌ Error getting active vendors: $e');
      return [];
    }
  }

  // Update vendor status
  static Future<bool> updateVendorStatus(String vendorId, VendorStatus status) async {
    try {
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Vendor status updated');
      return true;
    } catch (e) {
      print('❌ Error updating vendor status: $e');
      return false;
    }
  }

  // Update vendor rating
  static Future<bool> updateVendorRating(String vendorId, double rating, int completedJobs, int totalJobs) async {
    try {
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .update({
        'rating': rating,
        'completedJobs': completedJobs,
        'totalJobs': totalJobs,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Vendor rating updated');
      return true;
    } catch (e) {
      print('❌ Error updating vendor rating: $e');
      return false;
    }
  }

  // Get vendor statistics
  static Future<Map<String, dynamic>> getVendorStatistics() async {
    try {
      final vendors = await getAllVendors();
      
      final totalVendors = vendors.length;
      final activeVendors = vendors.where((v) => v.status == VendorStatus.active).length;
      final suspendedVendors = vendors.where((v) => v.status == VendorStatus.suspended).length;
      final blacklistedVendors = vendors.where((v) => v.status == VendorStatus.blacklisted).length;
      
      // Category breakdown
      final categoryBreakdown = <String, int>{};
      for (final vendor in vendors) {
        for (final category in vendor.categories) {
          final categoryName = vendor.getCategoryDisplay(category);
          categoryBreakdown[categoryName] = (categoryBreakdown[categoryName] ?? 0) + 1;
        }
      }
      
      // Rating statistics
      final vendorsWithRating = vendors.where((v) => v.rating != null).toList();
      double averageRating = 0;
      if (vendorsWithRating.isNotEmpty) {
        averageRating = vendorsWithRating.fold<double>(
          0,
          (total, vendor) => total + (vendor.rating ?? 0),
        ) / vendorsWithRating.length;
      }
      
      // City breakdown
      final cityBreakdown = <String, int>{};
      for (final vendor in vendors) {
        cityBreakdown[vendor.city] = (cityBreakdown[vendor.city] ?? 0) + 1;
      }
      
      return {
        'totalVendors': totalVendors,
        'activeVendors': activeVendors,
        'suspendedVendors': suspendedVendors,
        'blacklistedVendors': blacklistedVendors,
        'categoryBreakdown': categoryBreakdown,
        'cityBreakdown': cityBreakdown,
        'averageRating': averageRating,
        'activeRate': totalVendors > 0 
            ? (activeVendors / totalVendors * 100).toStringAsFixed(1) 
            : '0.0',
        'vendorsWithRating': vendorsWithRating.length,
      };
    } catch (e) {
      print('❌ Error getting vendor statistics: $e');
      return {
        'totalVendors': 0,
        'activeVendors': 0,
        'suspendedVendors': 0,
        'blacklistedVendors': 0,
        'categoryBreakdown': <String, int>{},
        'cityBreakdown': <String, int>{},
        'averageRating': 0.0,
        'activeRate': '0.0',
        'vendorsWithRating': 0,
      };
    }
  }

  // Initialize sample vendor data for a specific building
  static Future<void> initializeSampleVendorDataForBuilding(String buildingId) async {
    try {
      // Check if vendors already exist for this building
      final existingVendors = await _firestore
          .collection('vendors')
          .where('buildingId', isEqualTo: buildingId)
          .get();
      
      if (existingVendors.docs.isNotEmpty) {
        print('✅ Sample vendor data already exists for building $buildingId');
        return;
      }

      final sampleVendors = _generateSampleVendorsForBuilding(buildingId);
      
      for (final vendor in sampleVendors) {
        await addVendor(vendor);
      }
      
      print('✅ Sample vendor data initialized for building $buildingId');
    } catch (e) {
      print('❌ Error initializing sample vendor data for building: $e');
    }
  }

  // Generate sample vendors for a specific building
  static List<Vendor> _generateSampleVendorsForBuilding(String buildingId) {
    final now = DateTime.now();
    
    return [
      Vendor(
        id: '',
        buildingId: buildingId,
        name: 'חברת חשמל כהן',
        contactPerson: 'יוסי כהן',
        phone: '050-1234567',
        email: 'yossi@cohen-electric.co.il',
        website: 'www.cohen-electric.co.il',
        address: 'רחוב הרצל 15',
        city: 'תל אביב',
        postalCode: '67132',
        country: 'ישראל',
        categories: [VendorCategory.electrical, VendorCategory.security],
        status: VendorStatus.active,
        licenseNumber: 'EL-12345',
        insuranceInfo: 'ביטוח כללי עד ₪1,000,000',
        hourlyRate: 150.0,
        rating: 4.8,
        completedJobs: 45,
        totalJobs: 47,
        notes: 'ספק אמין עם ניסיון של 15 שנים',
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),

      Vendor(
        id: '',
        buildingId: buildingId,
        name: 'חברת מעליות גולדברג',
        contactPerson: 'דוד גולדברג',
        phone: '052-9876543',
        email: 'david@goldberg-elevators.co.il',
        website: 'www.goldberg-elevators.co.il',
        address: 'רחוב ויצמן 8',
        city: 'חיפה',
        postalCode: '32000',
        country: 'ישראל',
        categories: [VendorCategory.elevator, VendorCategory.structural],
        status: VendorStatus.active,
        licenseNumber: 'ELV-67890',
        insuranceInfo: 'ביטוח אחריות עד ₪2,000,000',
        hourlyRate: 200.0,
        rating: 4.9,
        completedJobs: 23,
        totalJobs: 23,
        notes: 'מומחים במעליות עם תעודות ISO',
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),

      Vendor(
        id: '',
        buildingId: buildingId,
        name: 'אינסטלטור משה',
        contactPerson: 'משה לוי',
        phone: '054-5551234',
        email: 'moshe@plumbing.co.il',
        address: 'רחוב בן גוריון 22',
        city: 'ירושלים',
        postalCode: '91000',
        country: 'ישראל',
        categories: [VendorCategory.plumbing],
        status: VendorStatus.active,
        licenseNumber: 'PL-11111',
        insuranceInfo: 'ביטוח אחריות עד ₪500,000',
        hourlyRate: 120.0,
        rating: 4.6,
        completedJobs: 67,
        totalJobs: 72,
        notes: 'אינסטלטור מקצועי עם 20 שנות ניסיון',
        createdAt: now.subtract(const Duration(days: 730)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),

      Vendor(
        id: '',
        buildingId: buildingId,
        name: 'גינון ירוק',
        contactPerson: 'שרה כהן',
        phone: '053-7778888',
        email: 'sarah@green-garden.co.il',
        website: 'www.green-garden.co.il',
        address: 'רחוב הטבע 5',
        city: 'רמת גן',
        postalCode: '52500',
        country: 'ישראל',
        categories: [VendorCategory.gardening, VendorCategory.cleaning],
        status: VendorStatus.active,
        licenseNumber: 'GR-22222',
        insuranceInfo: 'ביטוח כללי עד ₪300,000',
        hourlyRate: 80.0,
        rating: 4.4,
        completedJobs: 34,
        totalJobs: 38,
        notes: 'שירותי גינון וניקיון איכותיים',
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 45)),
      ),

      Vendor(
        id: '',
        buildingId: buildingId,
        name: 'צביעה מקצועית רם',
        contactPerson: 'רם אברמוביץ',
        phone: '052-1112222',
        email: 'ram@professional-paint.co.il',
        website: 'www.professional-paint.co.il',
        address: 'רחוב הצבע 3',
        city: 'פתח תקווה',
        postalCode: '49100',
        country: 'ישראל',
        categories: [VendorCategory.painting, VendorCategory.general],
        status: VendorStatus.active,
        licenseNumber: 'PT-44444',
        insuranceInfo: 'ביטוח אחריות עד ₪400,000',
        hourlyRate: 100.0,
        rating: 4.7,
        completedJobs: 52,
        totalJobs: 54,
        notes: 'מתמחה בצביעת חזיתות ופנים בניינים',
        createdAt: now.subtract(const Duration(days: 270)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
    ];
  }

  // Get top rated vendors
  static Future<List<Vendor>> getTopRatedVendors({int limit = 5}) async {
    try {
      final vendors = await getAllVendors();
      final vendorsWithRating = vendors.where((v) => v.rating != null).toList();
      vendorsWithRating.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      return vendorsWithRating.take(limit).toList();
    } catch (e) {
      print('❌ Error getting top rated vendors: $e');
      return [];
    }
  }

  // Get vendors by city
  static Future<List<Vendor>> getVendorsByCity(String city) async {
    try {
      final snapshot = await _firestore
          .collection('vendors')
          .where('city', isEqualTo: city)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Vendor.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('❌ Error getting vendors by city: $e');
      return [];
    }
  }
}

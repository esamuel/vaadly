import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id;
  final String buildingId;
  final String name;
  final String category;
  final String status; // 'active' | 'inactive' | 'suspended'
  final double rating;
  final bool isDefault;
  final String? phone;
  final String? email;
  final String? address;
  final List<String> services;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vendor({
    required this.id,
    required this.buildingId,
    required this.name,
    required this.category,
    required this.status,
    required this.rating,
    required this.isDefault,
    this.phone,
    this.email,
    this.address,
    this.services = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vendor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vendor(
      id: doc.id,
      buildingId: data['buildingId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'active',
      rating: (data['rating'] ?? 0.0).toDouble(),
      isDefault: data['isDefault'] ?? false,
      phone: data['phone'],
      email: data['email'],
      address: data['address'],
      services: List<String>.from(data['services'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'name': name,
      'category': category,
      'status': status,
      'rating': rating,
      'isDefault': isDefault,
      'phone': phone,
      'email': email,
      'address': address,
      'services': services,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Vendor copyWith({
    String? id,
    String? buildingId,
    String? name,
    String? category,
    String? status,
    double? rating,
    bool? isDefault,
    String? phone,
    String? email,
    String? address,
    List<String>? services,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      isDefault: isDefault ?? this.isDefault,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      services: services ?? this.services,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VendorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all vendors for a building
  Future<List<Vendor>> getVendors(String buildingId) async {
    try {
      final query = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('vendors')
          .where('status', isEqualTo: 'active')
          .orderBy('isDefault', descending: true)
          .orderBy('rating', descending: true)
          .get();

      return query.docs.map((doc) => Vendor.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vendors: $e');
    }
  }

  // Get vendors by category
  Future<List<Vendor>> getVendorsByCategory(
      String buildingId, String category) async {
    try {
      final query = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('vendors')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active')
          .orderBy('isDefault', descending: true)
          .orderBy('rating', descending: true)
          .get();

      return query.docs.map((doc) => Vendor.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vendors by category: $e');
    }
  }

  // Get default vendor for a category
  Future<Vendor?> getDefaultVendor(String buildingId, String category) async {
    try {
      final query = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('vendors')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Vendor.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch default vendor: $e');
    }
  }

  // Add new vendor
  Future<void> addVendor(Vendor vendor) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(vendor.buildingId)
          .collection('vendors')
          .doc(vendor.id)
          .set(vendor.toMap());
    } catch (e) {
      throw Exception('Failed to add vendor: $e');
    }
  }

  // Update vendor
  Future<void> updateVendor(Vendor vendor) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(vendor.buildingId)
          .collection('vendors')
          .doc(vendor.id)
          .update(vendor.toMap());
    } catch (e) {
      throw Exception('Failed to update vendor: $e');
    }
  }

  // Delete vendor
  Future<void> deleteVendor(String buildingId, String vendorId) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('vendors')
          .doc(vendorId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete vendor: $e');
    }
  }

  // Update vendor rating
  Future<void> updateVendorRating(
      String buildingId, String vendorId, double newRating) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('vendors')
          .doc(vendorId)
          .update({
        'rating': newRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update vendor rating: $e');
    }
  }

  // Set vendor as default for category
  Future<void> setDefaultVendor(
      String buildingId, String category, String vendorId) async {
    try {
      final batch = _firestore.batch();

      // Remove default from all vendors in this category
      final vendorsQuery = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('vendors')
          .where('category', isEqualTo: category)
          .where('isDefault', isEqualTo: true)
          .get();

      for (final doc in vendorsQuery.docs) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Set new default vendor
      batch.update(
        _firestore
            .collection('buildings')
            .doc(buildingId)
            .collection('vendors')
            .doc(vendorId),
        {
          'isDefault': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set default vendor: $e');
    }
  }

  // Get vendor statistics
  Future<Map<String, dynamic>> getVendorStats(String buildingId) async {
    try {
      final vendorsQuery = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('vendors')
          .get();

      final vendors =
          vendorsQuery.docs.map((doc) => Vendor.fromFirestore(doc)).toList();

      final totalVendors = vendors.length;
      final activeVendors = vendors.where((v) => v.status == 'active').length;
      final categories = vendors.map((v) => v.category).toSet().toList();
      final avgRating = vendors.isNotEmpty
          ? vendors.map((v) => v.rating).reduce((a, b) => a + b) /
              vendors.length
          : 0.0;

      return {
        'totalVendors': totalVendors,
        'activeVendors': activeVendors,
        'categories': categories,
        'averageRating': avgRating,
      };
    } catch (e) {
      throw Exception('Failed to fetch vendor statistics: $e');
    }
  }
}

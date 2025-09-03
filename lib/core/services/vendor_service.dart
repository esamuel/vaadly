import '../models/vendor.dart';

class VendorService {
  // In-memory storage for now (will be replaced with Firebase later)
  static final List<Vendor> _vendors = [];
  static int _nextVendorId = 1;

  // CRUD operations
  static List<Vendor> getAllVendors() {
    return List.from(_vendors);
  }

  static Vendor? getVendorById(String id) {
    try {
      return _vendors.firstWhere((vendor) => vendor.id == id);
    } catch (e) {
      return null;
    }
  }

  static Vendor addVendor(Vendor vendor) {
    final newVendor = vendor.copyWith(
      id: _nextVendorId.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _vendors.add(newVendor);
    _nextVendorId++;

    return newVendor;
  }

  static Vendor? updateVendor(Vendor vendor) {
    final index = _vendors.indexWhere((v) => v.id == vendor.id);
    if (index != -1) {
      final updatedVendor = vendor.copyWith(
        updatedAt: DateTime.now(),
      );
      _vendors[index] = updatedVendor;
      return updatedVendor;
    }
    return null;
  }

  static bool deleteVendor(String id) {
    final index = _vendors.indexWhere((v) => v.id == id);
    if (index != -1) {
      _vendors.removeAt(index);
      return true;
    }
    return false;
  }

  // Search and filtering
  static List<Vendor> searchVendors(String query) {
    if (query.isEmpty) return getAllVendors();

    final lowercaseQuery = query.toLowerCase();
    return _vendors.where((vendor) {
      return vendor.name.toLowerCase().contains(lowercaseQuery) ||
          vendor.contactPerson.toLowerCase().contains(lowercaseQuery) ||
          vendor.phone.contains(lowercaseQuery) ||
          (vendor.email?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  static List<Vendor> filterVendors({
    VendorCategory? category,
    VendorStatus? status,
    String? city,
    bool? isActive,
  }) {
    return _vendors.where((vendor) {
      if (category != null && !vendor.categories.contains(category)) {
        return false;
      }
      if (status != null && vendor.status != status) return false;
      if (city != null && vendor.city.toLowerCase() != city.toLowerCase()) {
        return false;
      }
      if (isActive != null && vendor.isActive != isActive) return false;
      return true;
    }).toList();
  }

  static List<Vendor> getVendorsByCategory(VendorCategory category) {
    return _vendors
        .where((vendor) => vendor.categories.contains(category))
        .toList();
  }

  static List<Vendor> getActiveVendors() {
    return _vendors
        .where((vendor) => vendor.status == VendorStatus.active)
        .toList();
  }

  // Statistics
  static Map<String, dynamic> getVendorStatistics() {
    final totalVendors = _vendors.length;
    final activeVendors =
        _vendors.where((v) => v.status == VendorStatus.active).length;
    final suspendedVendors =
        _vendors.where((v) => v.status == VendorStatus.suspended).length;
    final blacklistedVendors =
        _vendors.where((v) => v.status == VendorStatus.blacklisted).length;

    // Category breakdown
    final categoryBreakdown = <String, int>{};
    for (final vendor in _vendors) {
      for (final category in vendor.categories) {
        final categoryName = _getCategoryDisplay(category);
        categoryBreakdown[categoryName] =
            (categoryBreakdown[categoryName] ?? 0) + 1;
      }
    }

    // Rating statistics
    final vendorsWithRating = _vendors.where((v) => v.rating != null).toList();
    double averageRating = 0;
    if (vendorsWithRating.isNotEmpty) {
      averageRating = vendorsWithRating.fold<double>(
            0,
            (total, vendor) => total + (vendor.rating ?? 0),
          ) /
          vendorsWithRating.length;
    }

    return {
      'totalVendors': totalVendors,
      'activeVendors': activeVendors,
      'suspendedVendors': suspendedVendors,
      'blacklistedVendors': blacklistedVendors,
      'categoryBreakdown': categoryBreakdown,
      'averageRating': averageRating,
      'activeRate': totalVendors > 0
          ? (activeVendors / totalVendors * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  // Sample data initialization
  static void initializeSampleData() {
    if (_vendors.isNotEmpty) return; // Already initialized

    final sampleVendors = [
      Vendor(
        id: '1',
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
        notes: 'ספק אמין עם ניסיון של 15 שנות',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Vendor(
        id: '2',
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
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Vendor(
        id: '3',
        name: 'אינסטלטור משה',
        contactPerson: 'משה לוי',
        phone: '054-5551234',
        email: 'moshe@plumbing.co.il',
        website: null,
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
        createdAt: DateTime.now().subtract(const Duration(days: 730)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Vendor(
        id: '4',
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
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Vendor(
        id: '5',
        name: 'מיזוג אוויר קל',
        contactPerson: 'אברהם גולדברג',
        phone: '050-9990000',
        email: 'abraham@easy-ac.co.il',
        website: 'www.easy-ac.co.il',
        address: 'רחוב הקיץ 12',
        city: 'אשדוד',
        postalCode: '77400',
        country: 'ישראל',
        categories: [VendorCategory.hvac],
        status: VendorStatus.suspended,
        licenseNumber: 'HVAC-33333',
        insuranceInfo: 'ביטוח אחריות עד ₪800,000',
        hourlyRate: 180.0,
        rating: 3.8,
        completedJobs: 28,
        totalJobs: 35,
        notes: 'מושהה עקב תלונות על איכות שירות',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];

    for (final vendor in sampleVendors) {
      _vendors.add(vendor);
    }
    _nextVendorId = sampleVendors.length + 1;
  }

  // Utility methods
  static List<Vendor> getTopRatedVendors({int limit = 5}) {
    final sortedVendors = List<Vendor>.from(_vendors);
    sortedVendors.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return sortedVendors.take(limit).toList();
  }

  static List<Vendor> getVendorsByLocation(String city) {
    return _vendors
        .where((v) => v.city.toLowerCase() == city.toLowerCase())
        .toList();
  }

  static List<Vendor> getVendorsByPriceRange(
      {double? minPrice, double? maxPrice}) {
    return _vendors.where((vendor) {
      if (vendor.hourlyRate == null) return false;
      if (minPrice != null && vendor.hourlyRate! < minPrice) return false;
      if (maxPrice != null && vendor.hourlyRate! > maxPrice) return false;
      return true;
    }).toList();
  }

  // Helper method for category display
  static String _getCategoryDisplay(VendorCategory category) {
    switch (category) {
      case VendorCategory.plumbing:
        return 'אינסטלציה';
      case VendorCategory.electrical:
        return 'חשמל';
      case VendorCategory.hvac:
        return 'מיזוג אוויר';
      case VendorCategory.cleaning:
        return 'ניקיון';
      case VendorCategory.gardening:
        return 'גינון';
      case VendorCategory.elevator:
        return 'מעליות';
      case VendorCategory.security:
        return 'אבטחה';
      case VendorCategory.structural:
        return 'מבני';
      case VendorCategory.general:
        return 'כללי';
      case VendorCategory.painting:
        return 'צביעה';
      case VendorCategory.carpentry:
        return 'נגרות';
      case VendorCategory.roofing:
        return 'גגות';
    }
  }
}

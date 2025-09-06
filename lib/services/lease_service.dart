import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/lease.dart';
import '../core/services/firebase_service.dart';
import '../core/models/payment.dart';
import 'stripe_payment_service.dart';

class LeaseService {
  static const String _collection = 'leases';

  /// Create a new lease
  static Future<Lease?> createLease(Lease lease) async {
    try {
      await FirebaseService.initialize();
      
      final leaseData = lease.toMap();
      leaseData['createdAt'] = FieldValue.serverTimestamp();
      leaseData['updatedAt'] = FieldValue.serverTimestamp();
      
      print('📋 Creating lease: ${lease.title}');
      
      final docRef = await FirebaseService.addDocument(
        'buildings/${lease.buildingId}/leases',
        leaseData,
      );
      
      final savedLease = lease.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('✅ Lease created with ID: ${docRef.id}');
      return savedLease;
    } catch (e) {
      print('❌ Error creating lease: $e');
      return null;
    }
  }

  /// Get all leases for a building
  static Future<List<Lease>> getLeasesByBuilding(String buildingId) async {
    try {
      await FirebaseService.initialize();
      print('📋 Loading leases for building $buildingId...');
      
      final querySnapshot = await FirebaseService.getDocuments(
        'buildings/$buildingId/leases',
      );
      
      final leases = querySnapshot.docs.map((doc) {
        return Lease.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      // Sort by creation date (newest first)
      leases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ Loaded ${leases.length} leases for building $buildingId');
      return leases;
    } catch (e) {
      print('❌ Error loading leases: $e');
      return [];
    }
  }

  /// Get a specific lease by ID
  static Future<Lease?> getLeaseById(String buildingId, String leaseId) async {
    try {
      await FirebaseService.initialize();
      print('🔍 Loading lease $leaseId from building $buildingId...');
      
      final docSnapshot = await FirebaseService.getDocument(
        'buildings/$buildingId/leases',
        leaseId,
      );
      
      if (docSnapshot.exists) {
        final lease = Lease.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
        print('✅ Lease loaded: ${lease.title}');
        return lease;
      } else {
        print('❌ Lease $leaseId not found');
        return null;
      }
    } catch (e) {
      print('❌ Error loading lease $leaseId: $e');
      return null;
    }
  }

  /// Update an existing lease
  static Future<Lease?> updateLease(Lease lease) async {
    try {
      print('📝 Updating lease ${lease.id}...');
      
      final leaseData = lease.toMap();
      leaseData['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseService.updateDocument(
        'buildings/${lease.buildingId}/leases',
        lease.id,
        leaseData,
      );
      
      final updatedLease = lease.copyWith(updatedAt: DateTime.now());
      print('✅ Lease ${lease.id} updated successfully');
      return updatedLease;
    } catch (e) {
      print('❌ Error updating lease ${lease.id}: $e');
      return null;
    }
  }

  /// Delete a lease
  static Future<bool> deleteLease(String buildingId, String leaseId) async {
    try {
      print('🗑️ Deleting lease $leaseId...');
      
      await FirebaseService.deleteDocument(
        'buildings/$buildingId/leases',
        leaseId,
      );
      
      print('✅ Lease $leaseId deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting lease $leaseId: $e');
      return false;
    }
  }

  /// Get active leases
  static Future<List<Lease>> getActiveLeases(String buildingId) async {
    try {
      final allLeases = await getLeasesByBuilding(buildingId);
      final activeLeases = allLeases.where((lease) => 
        lease.status == LeaseStatus.active
      ).toList();
      
      print('✅ Found ${activeLeases.length} active leases');
      return activeLeases;
    } catch (e) {
      print('❌ Error getting active leases: $e');
      return [];
    }
  }

  /// Get expiring leases (within next 90 days)
  static Future<List<Lease>> getExpiringLeases(String buildingId) async {
    try {
      final allLeases = await getLeasesByBuilding(buildingId);
      final expiringLeases = allLeases.where((lease) => 
        lease.isExpiringSoon
      ).toList();
      
      // Sort by expiration date
      expiringLeases.sort((a, b) => a.endDate.compareTo(b.endDate));
      
      print('✅ Found ${expiringLeases.length} expiring leases');
      return expiringLeases;
    } catch (e) {
      print('❌ Error getting expiring leases: $e');
      return [];
    }
  }

  /// Get expired leases
  static Future<List<Lease>> getExpiredLeases(String buildingId) async {
    try {
      final allLeases = await getLeasesByBuilding(buildingId);
      final expiredLeases = allLeases.where((lease) => 
        lease.isExpired
      ).toList();
      
      print('✅ Found ${expiredLeases.length} expired leases');
      return expiredLeases;
    } catch (e) {
      print('❌ Error getting expired leases: $e');
      return [];
    }
  }

  /// Get leases that need renewal notice
  static Future<List<Lease>> getLeasesNeedingRenewalNotice(String buildingId) async {
    try {
      final allLeases = await getLeasesByBuilding(buildingId);
      final renewalNeededLeases = allLeases.where((lease) => 
        lease.needsRenewalNotice
      ).toList();
      
      print('✅ Found ${renewalNeededLeases.length} leases needing renewal notice');
      return renewalNeededLeases;
    } catch (e) {
      print('❌ Error getting leases needing renewal notice: $e');
      return [];
    }
  }

  /// Renew a lease
  static Future<Lease?> renewLease({
    required Lease currentLease,
    required DateTime newEndDate,
    required double newMonthlyRent,
    double? rentIncrease,
    int? newDurationMonths,
    bool updateAutoRenew = false,
    String? renewalNotes,
  }) async {
    try {
      print('🔄 Renewing lease ${currentLease.id}...');
      
      final renewedLease = currentLease.copyWith(
        status: LeaseStatus.renewed,
        endDate: newEndDate,
        monthlyRent: newMonthlyRent,
        durationMonths: newDurationMonths ?? currentLease.durationMonths,
        renewalRentIncrease: rentIncrease,
        lastRenewalDate: DateTime.now(),
        nextReviewDate: newEndDate.subtract(const Duration(days: 90)), // 3 months before next expiry
        autoRenew: updateAutoRenew,
        notes: renewalNotes != null 
          ? '${currentLease.notes ?? ''}\n\nחידוש ${DateTime.now().toString()}: $renewalNotes'.trim()
          : currentLease.notes,
        updatedAt: DateTime.now(),
      );
      
      final result = await updateLease(renewedLease);
      
      if (result != null) {
        print('✅ Lease renewed successfully');
        
        // Create new payment record for the first month of renewed lease
        await _createRenewalPayment(renewedLease);
      }
      
      return result;
    } catch (e) {
      print('❌ Error renewing lease: $e');
      return null;
    }
  }

  /// Terminate a lease
  static Future<Lease?> terminateLease({
    required Lease lease,
    required DateTime terminationDate,
    required String reason,
    double? penalty,
    String? notes,
  }) async {
    try {
      print('⚠️ Terminating lease ${lease.id}...');
      
      final terminatedLease = lease.copyWith(
        status: LeaseStatus.terminated,
        terminationDate: terminationDate,
        terminationReason: reason,
        terminationPenalty: penalty,
        notes: notes != null 
          ? '${lease.notes ?? ''}\n\nהפסקה ${DateTime.now().toString()}: $notes'.trim()
          : lease.notes,
        updatedAt: DateTime.now(),
      );
      
      final result = await updateLease(terminatedLease);
      print('✅ Lease terminated successfully');
      return result;
    } catch (e) {
      print('❌ Error terminating lease: $e');
      return null;
    }
  }

  /// Generate monthly rent payments for a lease
  static Future<List<Payment>> generateMonthlyPayments({
    required Lease lease,
    required int monthsCount,
    DateTime? startDate,
  }) async {
    try {
      print('💰 Generating $monthsCount monthly payments for lease ${lease.id}...');
      
      final payments = <Payment>[];
      final start = startDate ?? DateTime.now();
      
      for (int i = 0; i < monthsCount; i++) {
        final paymentDate = DateTime(
          start.year,
          start.month + i,
          lease.paymentDueDay,
        );
        
        final payment = await StripePaymentService.createPaymentRecord(
          buildingId: lease.buildingId,
          unitId: lease.unitId,
          residentId: lease.tenantId,
          title: 'שכירות ${_getMonthName(paymentDate.month)} ${paymentDate.year}',
          description: 'תשלום שכירות חודשי עבור ${lease.title}',
          type: PaymentType.rent,
          amount: lease.totalMonthlyPayment,
          dueDate: paymentDate,
          metadata: {
            'lease_id': lease.id,
            'month': paymentDate.month.toString(),
            'year': paymentDate.year.toString(),
          },
        );
        
        if (payment != null) {
          payments.add(payment);
        }
      }
      
      print('✅ Generated ${payments.length} payments');
      return payments;
    } catch (e) {
      print('❌ Error generating monthly payments: $e');
      return [];
    }
  }

  /// Get lease statistics for a building
  static Future<Map<String, dynamic>> getLeaseStatistics(String buildingId) async {
    try {
      print('📊 Calculating lease statistics for building $buildingId...');
      
      final leases = await getLeasesByBuilding(buildingId);
      
      final activeLeases = leases.where((l) => l.status == LeaseStatus.active).length;
      final expiredLeases = leases.where((l) => l.isExpired).length;
      final expiringLeases = leases.where((l) => l.isExpiringSoon).length;
      final terminatedLeases = leases.where((l) => l.status == LeaseStatus.terminated).length;
      
      final totalMonthlyRent = leases
          .where((l) => l.status == LeaseStatus.active)
          .fold<double>(0.0, (sum, lease) => sum + lease.monthlyRent);
      
      final averageRent = activeLeases > 0 ? totalMonthlyRent / activeLeases : 0.0;
      
      final stats = {
        'totalLeases': leases.length,
        'activeLeases': activeLeases,
        'expiredLeases': expiredLeases,
        'expiringLeases': expiringLeases,
        'terminatedLeases': terminatedLeases,
        'totalMonthlyRent': totalMonthlyRent,
        'averageRent': averageRent,
        'occupancyRate': leases.isNotEmpty 
            ? (activeLeases / leases.length * 100).toStringAsFixed(1)
            : '0.0',
      };
      
      print('✅ Lease statistics calculated');
      return stats;
    } catch (e) {
      print('❌ Error calculating lease statistics: $e');
      return {};
    }
  }

  /// Search leases by tenant name or unit
  static Future<List<Lease>> searchLeases(String buildingId, String query) async {
    try {
      if (query.isEmpty) return getLeasesByBuilding(buildingId);
      
      print('🔍 Searching leases for: $query');
      
      final allLeases = await getLeasesByBuilding(buildingId);
      final lowercaseQuery = query.toLowerCase();
      
      final filteredLeases = allLeases.where((lease) {
        return lease.title.toLowerCase().contains(lowercaseQuery) ||
            lease.unitId.toLowerCase().contains(lowercaseQuery) ||
            lease.tenantId.toLowerCase().contains(lowercaseQuery) ||
            (lease.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
      
      print('✅ Found ${filteredLeases.length} leases matching "$query"');
      return filteredLeases;
    } catch (e) {
      print('❌ Error searching leases: $e');
      return [];
    }
  }

  // Helper methods
  static Future<void> _createRenewalPayment(Lease lease) async {
    try {
      await StripePaymentService.createPaymentRecord(
        buildingId: lease.buildingId,
        unitId: lease.unitId,
        residentId: lease.tenantId,
        title: 'שכירות חודש ראשון - חוזה מחודש',
        description: 'תשלום עבור החודש הראשון של החוזה המחודש',
        type: PaymentType.rent,
        amount: lease.totalMonthlyPayment,
        dueDate: DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          lease.paymentDueDay,
        ),
        metadata: {
          'lease_id': lease.id,
          'renewal_payment': 'true',
        },
      );
    } catch (e) {
      print('❌ Error creating renewal payment: $e');
    }
  }

  static String _getMonthName(int month) {
    const months = [
      '', 'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'
    ];
    return months[month];
  }
}
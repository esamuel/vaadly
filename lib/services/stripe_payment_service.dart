import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../core/models/payment.dart' as app;
import '../core/services/firebase_service.dart';
import 'package:flutter/material.dart';

class StripePaymentService {
  static const String _baseUrl = 'https://api.stripe.com/v1';
  static String? _secretKey; // Will be set from Firebase Remote Config
  static String? _publishableKey; // Will be set from Firebase Remote Config

  // Initialize Stripe with keys from Firebase Remote Config
  static Future<void> initialize() async {
    try {
      // In a real app, these would come from Firebase Remote Config or secure environment
      // For demo purposes, using test keys (replace with your actual test keys)
      _publishableKey = 'pk_test_your_test_publishable_key_here';
      _secretKey = 'sk_test_your_test_secret_key_here';

      if (_publishableKey != null) {
        Stripe.publishableKey = _publishableKey!;
        print('✅ Stripe initialized with publishable key');
      } else {
        print('⚠️ Stripe publishable key not found');
      }
    } catch (e) {
      print('❌ Error initializing Stripe: $e');
    }
  }

  // Create payment intent for a specific amount
  static Future<String?> createPaymentIntent({
    required double amount,
    required String currency,
    required String buildingId,
    String? unitId,
    String? residentId,
    String? invoiceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_secretKey == null) {
        print('❌ Stripe secret key not configured');
        return null;
      }

      final url = Uri.parse('$_baseUrl/payment_intents');
      final amountInCents = (amount * 100).round(); // Convert to cents

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountInCents.toString(),
          'currency': currency.toLowerCase(),
          'metadata[building_id]': buildingId,
          if (unitId != null) 'metadata[unit_id]': unitId,
          if (residentId != null) 'metadata[resident_id]': residentId,
          if (invoiceId != null) 'metadata[invoice_id]': invoiceId,
          if (metadata != null)
            ...metadata.map(
                (key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Payment intent created: ${data['id']}');
        return data['client_secret'];
      } else {
        print('❌ Error creating payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception creating payment intent: $e');
      return null;
    }
  }

  // Process payment with Stripe
  static Future<PaymentResult> processPayment({
    required String clientSecret,
    required app.Payment payment,
    String? paymentMethodId,
  }) async {
    try {
      // Confirm payment with Stripe
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodId != null
            ? PaymentMethodParams.cardFromMethodId(
                paymentMethodData: PaymentMethodDataCardFromMethod(
                  paymentMethodId: paymentMethodId,
                ),
              )
            : const PaymentMethodParams.card(
                paymentMethodData: PaymentMethodData(),
              ),
      );

      // Update payment status in Firebase
      final updatedPayment = payment.copyWith(
        status: app.PaymentStatus.completed,
        paidDate: DateTime.now(),
        stripePaymentIntentId: _extractPaymentIntentId(clientSecret),
        updatedAt: DateTime.now(),
      );

      await _updatePaymentInFirebase(updatedPayment);

      print('✅ Payment completed successfully');
      return PaymentResult(
        success: true,
        payment: updatedPayment,
        message: 'תשלום הושלם בהצלחה',
      );
    } on StripeException catch (e) {
      print('❌ Stripe error: ${e.error.localizedMessage}');

      // Update payment status to failed
      final failedPayment = payment.copyWith(
        status: app.PaymentStatus.failed,
        failureReason: e.error.localizedMessage,
        updatedAt: DateTime.now(),
      );

      await _updatePaymentInFirebase(failedPayment);

      return PaymentResult(
        success: false,
        payment: failedPayment,
        message: e.error.localizedMessage ?? 'תשלום נכשל',
      );
    } catch (e) {
      print('❌ Payment error: $e');

      final failedPayment = payment.copyWith(
        status: app.PaymentStatus.failed,
        failureReason: e.toString(),
        updatedAt: DateTime.now(),
      );

      await _updatePaymentInFirebase(failedPayment);

      return PaymentResult(
        success: false,
        payment: failedPayment,
        message: 'שגיאה בעיבוד התשלום',
      );
    }
  }

  // Present payment sheet for easy payment
  static Future<PaymentResult> presentPaymentSheet({
    required app.Payment payment,
    required String clientSecret,
  }) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Vaadly',
          customerEphemeralKeySecret: null, // For guest checkout
          customerId: payment.residentId,
          style: ThemeMode.system,
          billingDetails: const BillingDetails(
            name: null,
            email: null,
            phone: null,
            address: Address(
              city: null,
              country: 'IL',
              line1: null,
              line2: null,
              postalCode: null,
              state: null,
            ),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful - update in Firebase
      final successfulPayment = payment.copyWith(
        status: app.PaymentStatus.completed,
        paidDate: DateTime.now(),
        stripePaymentIntentId: _extractPaymentIntentId(clientSecret),
        updatedAt: DateTime.now(),
      );

      await _updatePaymentInFirebase(successfulPayment);

      print('✅ Payment sheet completed successfully');
      return PaymentResult(
        success: true,
        payment: successfulPayment,
        message: 'תשלום הושלם בהצלחה',
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        print('⚠️ Payment cancelled by user');
        return PaymentResult(
          success: false,
          payment: payment,
          message: 'תשלום בוטל על ידי המשתמש',
        );
      } else {
        print('❌ Stripe error: ${e.error.localizedMessage}');

        final failedPayment = payment.copyWith(
          status: app.PaymentStatus.failed,
          failureReason: e.error.localizedMessage,
          updatedAt: DateTime.now(),
        );

        await _updatePaymentInFirebase(failedPayment);

        return PaymentResult(
          success: false,
          payment: failedPayment,
          message: e.error.localizedMessage ?? 'תשלום נכשל',
        );
      }
    } catch (e) {
      print('❌ Payment sheet error: $e');

      final failedPayment = payment.copyWith(
        status: app.PaymentStatus.failed,
        failureReason: e.toString(),
        updatedAt: DateTime.now(),
      );

      await _updatePaymentInFirebase(failedPayment);

      return PaymentResult(
        success: false,
        payment: failedPayment,
        message: 'שגיאה בעיבוד התשלום',
      );
    }
  }

  // Create payment record in Firebase
  static Future<app.Payment?> createPaymentRecord({
    required String buildingId,
    String? unitId,
    String? residentId,
    String? invoiceId,
    required String title,
    String? description,
    required app.PaymentType type,
    required double amount,
    required DateTime dueDate,
    app.PaymentMethod paymentMethod = app.PaymentMethod.creditCard,
    String currency = 'ILS',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final feeAmount = _calculateStripeFee(amount);
      final netAmount = amount - feeAmount;

      final payment = app.Payment(
        id: '', // Will be set by Firebase
        buildingId: buildingId,
        unitId: unitId,
        residentId: residentId,
        invoiceId: invoiceId,
        title: title,
        description: description,
        type: type,
        status: app.PaymentStatus.pending,
        paymentMethod: paymentMethod,
        amount: amount,
        feeAmount: feeAmount,
        netAmount: netAmount,
        currency: currency,
        dueDate: dueDate,
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      final docRef = await FirebaseService.addDocument(
        'buildings/$buildingId/payments',
        payment.toMap(),
      );

      final savedPayment = payment.copyWith(id: docRef.id);
      print('✅ Payment record created: ${docRef.id}');
      return savedPayment;
    } catch (e) {
      print('❌ Error creating payment record: $e');
      return null;
    }
  }

  // Helper methods
  static String _extractPaymentIntentId(String clientSecret) {
    return clientSecret.split('_secret_')[0];
  }

  static double _calculateStripeFee(double amount) {
    // Stripe Israel fee: 2.9% + ₪1.20 per successful charge
    return (amount * 0.029) + 1.20;
  }

  static Future<void> _updatePaymentInFirebase(app.Payment payment) async {
    try {
      await FirebaseService.updateDocument(
        'buildings/${payment.buildingId}/payments',
        payment.id,
        payment.toMap(),
      );
      print('✅ Payment updated in Firebase: ${payment.id}');
    } catch (e) {
      print('❌ Error updating payment in Firebase: $e');
    }
  }

  // Get payments for a building
  static Future<List<app.Payment>> getPaymentsByBuilding(
      String buildingId) async {
    try {
      final snapshot = await FirebaseService.getDocuments(
        'buildings/$buildingId/payments',
      );

      final payments = snapshot.docs.map((doc) {
        return app.Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort by creation date (newest first)
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Loaded ${payments.length} payments for building $buildingId');
      return payments;
    } catch (e) {
      print('❌ Error loading payments: $e');
      return [];
    }
  }

  // Get overdue payments
  static Future<List<app.Payment>> getOverduePayments(String buildingId) async {
    try {
      final payments = await getPaymentsByBuilding(buildingId);
      final overduePayments =
          payments.where((payment) => payment.isOverdue).toList();

      print('✅ Found ${overduePayments.length} overdue payments');
      return overduePayments;
    } catch (e) {
      print('❌ Error getting overdue payments: $e');
      return [];
    }
  }
}

// Payment result class
class PaymentResult {
  final bool success;
  final app.Payment payment;
  final String message;

  PaymentResult({
    required this.success,
    required this.payment,
    required this.message,
  });
}

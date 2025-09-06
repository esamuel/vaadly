import 'package:flutter/material.dart';
import '../../../core/models/payment.dart';
import '../../../services/stripe_payment_service.dart';
import 'package:intl/intl.dart';

class PaymentCard extends StatefulWidget {
  final Payment payment;
  final VoidCallback? onPaymentCompleted;
  final bool showPayButton;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onPaymentCompleted,
    this.showPayButton = true,
  });

  @override
  State<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<PaymentCard> {
  bool _processing = false;
  final _currencyFormatter = NumberFormat.currency(locale: 'he_IL', symbol: '₪');
  final _dateFormatter = DateFormat('dd/MM/yyyy', 'he');

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header row with title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.payment.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),

            // Description if available
            if (widget.payment.description != null) ...[
              Text(
                widget.payment.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Payment details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'סכום:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _currencyFormatter.format(widget.payment.amount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'תאריך יעד:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _dateFormatter.format(widget.payment.dueDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.payment.isOverdue ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Additional info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'סוג: ${widget.payment.typeDisplay}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (widget.payment.unitId != null)
                  Text(
                    'יחידה: ${widget.payment.unitId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),

            // Payment date if paid
            if (widget.payment.paidDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'שולם ב-${_dateFormatter.format(widget.payment.paidDate!)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Failure reason if failed
            if (widget.payment.status == PaymentStatus.failed && 
                widget.payment.failureReason != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'סיבת כישלון: ${widget.payment.failureReason}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Pay button for pending payments
            if (widget.showPayButton && 
                widget.payment.status == PaymentStatus.pending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _processing ? null : _processPayment,
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(_processing ? 'מעבד תשלום...' : 'שלם עכשיו'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.payment.isOverdue 
                        ? Colors.red 
                        : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Retry button for failed payments
            if (widget.showPayButton && 
                widget.payment.status == PaymentStatus.failed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _processing ? null : _processPayment,
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_processing ? 'מעבד תשלום...' : 'נסה שוב'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.payment.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.payment.statusColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        widget.payment.statusDisplay,
        style: TextStyle(
          color: widget.payment.statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _processing = true;
    });

    try {
      // Create payment intent
      final clientSecret = await StripePaymentService.createPaymentIntent(
        amount: widget.payment.amount,
        currency: widget.payment.currency,
        buildingId: widget.payment.buildingId,
        unitId: widget.payment.unitId,
        residentId: widget.payment.residentId,
        invoiceId: widget.payment.invoiceId,
        metadata: {
          'payment_id': widget.payment.id,
          'payment_type': widget.payment.type.toString(),
        },
      );

      if (clientSecret == null) {
        _showErrorMessage('שגיאה ביצירת תשלום');
        return;
      }

      // Present payment sheet
      final result = await StripePaymentService.presentPaymentSheet(
        payment: widget.payment,
        clientSecret: clientSecret,
      );

      if (result.success) {
        _showSuccessMessage(result.message);
        widget.onPaymentCompleted?.call();
      } else {
        _showErrorMessage(result.message);
      }
    } catch (e) {
      _showErrorMessage('שגיאה בעיבוד התשלום: ${e.toString()}');
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'סגור',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'סגור',
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}

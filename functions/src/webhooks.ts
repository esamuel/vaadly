import * as admin from 'firebase-admin';
import { onRequest } from 'firebase-functions/v2/https';

export const paymentWebhook = onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight request
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    // Verify request method
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    // TODO: Verify webhook signature for security
    // const signature = req.headers['x-signature'];
    // if (!verifySignature(req.body, signature)) {
    //   res.status(401).json({ error: 'Invalid signature' });
    //   return;
    // }

    const event = req.body;
    console.log('Payment webhook received:', JSON.stringify(event, null, 2));

    // Handle different event types
    switch (event.type) {
      case 'payment.succeeded':
        await handlePaymentSucceeded(db, event.data);
        break;
      
      case 'payment.failed':
        await handlePaymentFailed(db, event.data);
        break;
      
      case 'payment.refunded':
        await handlePaymentRefunded(db, event.data);
        break;
      
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ 
      success: true, 
      message: 'Webhook processed successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error processing payment webhook:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

async function handlePaymentSucceeded(db: FirebaseFirestore.Firestore, data: any) {
  const { buildingId, invoiceId, amount, currency, transactionId, paidAt } = data;
  
  if (!buildingId || !invoiceId || !amount || !transactionId) {
    throw new Error('Missing required payment data');
  }

  console.log(`Processing successful payment for invoice ${invoiceId}`);

  // Create payment record
  const paymentData = {
    buildingId,
    invoiceId,
    amount: parseFloat(amount),
    currency: currency || 'ILS',
    method: 'online_payment',
    status: 'completed',
    transactionId,
    paidAt: paidAt ? new Date(paidAt) : new Date(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await db.doc(`buildings/${buildingId}/payments/${transactionId}`).set(paymentData);

  // Update invoice status
  await db.doc(`buildings/${buildingId}/invoices/${invoiceId}`).set({
    status: 'paid',
    paidAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  // Create audit log
  await db.collection(`buildings/${buildingId}/audit`).add({
    event: 'payment_received',
    invoiceId,
    amount: parseFloat(amount),
    currency: currency || 'ILS',
    transactionId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    userId: 'payment_system'
  });

  // Send notification (optional)
  await sendPaymentNotification(db, buildingId, invoiceId, amount, currency);

  console.log(`Payment for invoice ${invoiceId} processed successfully`);
}

async function handlePaymentFailed(db: FirebaseFirestore.Firestore, data: any) {
  const { buildingId, invoiceId, amount, currency, transactionId, failureReason } = data;
  
  console.log(`Processing failed payment for invoice ${invoiceId}`);

  // Create failed payment record
  const paymentData = {
    buildingId,
    invoiceId,
    amount: parseFloat(amount),
    currency: currency || 'ILS',
    method: 'online_payment',
    status: 'failed',
    transactionId,
    failureReason: failureReason || 'Unknown failure',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await db.doc(`buildings/${buildingId}/payments/${transactionId}`).set(paymentData);

  // Update invoice status if needed
  await db.doc(`buildings/${buildingId}/invoices/${invoiceId}`).set({
    status: 'payment_failed',
    lastPaymentAttempt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  // Create audit log
  await db.collection(`buildings/${buildingId}/audit`).add({
    event: 'payment_failed',
    invoiceId,
    amount: parseFloat(amount),
    currency: currency || 'ILS',
    transactionId,
    failureReason: failureReason || 'Unknown failure',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    userId: 'payment_system'
  });

  console.log(`Failed payment for invoice ${invoiceId} recorded`);
}

async function handlePaymentRefunded(db: FirebaseFirestore.Firestore, data: any) {
  const { buildingId, invoiceId, amount, currency, transactionId, refundReason } = data;
  
  console.log(`Processing refund for invoice ${invoiceId}`);

  // Create refund record
  const refundData = {
    buildingId,
    invoiceId,
    amount: parseFloat(amount),
    currency: currency || 'ILS',
    method: 'refund',
    status: 'completed',
    transactionId,
    refundReason: refundReason || 'Customer request',
    refundedAt: new Date(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await db.doc(`buildings/${buildingId}/payments/refund_${transactionId}`).set(refundData);

  // Update invoice status
  await db.doc(`buildings/${buildingId}/invoices/${invoiceId}`).set({
    status: 'refunded',
    refundedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  // Create audit log
  await db.collection(`buildings/${buildingId}/audit`).add({
    event: 'payment_refunded',
    invoiceId,
    amount: parseFloat(amount),
    currency: currency || 'ILS',
    transactionId,
    refundReason: refundReason || 'Customer request',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    userId: 'payment_system'
  });

  console.log(`Refund for invoice ${invoiceId} processed successfully`);
}

async function sendPaymentNotification(db: FirebaseFirestore.Firestore, buildingId: string, invoiceId: string, amount: number, currency: string) {
  try {
    // Create announcement about successful payment
    await db.collection(`buildings/${buildingId}/announcements`).add({
      title: 'Payment Received',
      body: `Payment of ${amount} ${currency} received for invoice ${invoiceId}`,
      type: 'payment_success',
      invoiceId,
      amount,
      currency,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  } catch (error) {
    console.error('Failed to send payment notification:', error);
  }
}

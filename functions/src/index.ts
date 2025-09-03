import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v2';
import { classifyWorkOrder } from './classify';
import { dispatchWorkOrder } from './dispatch';
import { paymentWebhook } from './webhooks';
import { notify } from './notify';
import { notifyEnhanced } from './notify_enhanced';
import { aiIntake } from './ai_intake';

// Initialize Firebase Admin
admin.initializeApp();

// Trigger: classify on new work order
export const onWorkOrderCreate = functions.firestore
  .onDocumentCreated('buildings/{buildingId}/work_orders/{workOrderId}', async (event) => {
    const { buildingId, workOrderId } = event.params;
    await classifyWorkOrder(buildingId, workOrderId);
  });

// Scheduled: dispatch pending work orders (or chain after classify)
export const dispatchCron = functions.scheduler
  .onSchedule('every 1 minutes', async () => {
    await dispatchWorkOrder();
  });

// HTTPS: payment provider webhook
export const payments = functions.https.onRequest(paymentWebhook);

// HTTPS: send email/push notifications
export const sendNotify = functions.https.onRequest(notify);

// HTTPS: enhanced notifications with targeting and analytics
export const sendNotifyEnhanced = functions.https.onRequest(notifyEnhanced);

// HTTPS: AI resident intake (Hebrew NL -> structured work order)
export const ai_intake = aiIntake;

// Health check endpoint
export const health = functions.https.onRequest((req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'vaadly-functions'
  });
});

import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export const notify = onRequest(async (req, res) => {
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

    const { buildingId, type, data, recipients } = req.body;

    if (!buildingId || !type || !data) {
      res.status(400).json({ error: 'Missing required parameters' });
      return;
    }

    console.log(`Sending ${type} notification to building ${buildingId}`);

    let result;
    switch (type) {
      case 'work_order_created':
        result = await notifyWorkOrderCreated(db, buildingId, data);
        break;
      
      case 'work_order_assigned':
        result = await notifyWorkOrderAssigned(db, buildingId, data);
        break;
      
      case 'work_order_completed':
        result = await notifyWorkOrderCompleted(db, buildingId, data);
        break;
      
      case 'payment_received':
        result = await notifyPaymentReceived(db, buildingId, data);
        break;
      
      case 'announcement':
        result = await notifyAnnouncement(db, buildingId, data, recipients);
        break;
      
      default:
        res.status(400).json({ error: `Unknown notification type: ${type}` });
        return;
    }

    res.json({
      success: true,
      message: 'Notification sent successfully',
      result,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

async function notifyWorkOrderCreated(db: FirebaseFirestore.Firestore, buildingId: string, data: any) {
  const { workOrderId, title, description, unitNumber, reportedBy } = data;
  
  // Get building members to notify
  const membersQuery = await db.collection(`buildings/${buildingId}/members`)
    .where('role', 'in', ['committee', 'super_admin'])
    .get();

  const notifications = [];

  for (const member of membersQuery.docs) {
    const memberData = member.data();
    
    // Send push notification
    if (memberData.fcmToken) {
      try {
        await sendPushNotification(memberData.fcmToken, {
          title: 'New Work Order Created',
          body: `Issue: ${title}${unitNumber ? ` (Unit ${unitNumber})` : ''}`,
          data: {
            type: 'work_order_created',
            workOrderId,
            buildingId
          }
        });
        notifications.push({ type: 'push', userId: member.id, success: true });
      } catch (error) {
        console.error(`Failed to send push notification to ${member.id}:`, error);
        notifications.push({ type: 'push', userId: member.id, success: false, error: error instanceof Error ? error.message : 'Unknown error' });
      }
    }

    // Send email notification
    if (memberData.email) {
      try {
        await sendEmailNotification(memberData.email, {
          subject: 'New Work Order Created',
          template: 'work_order_created',
          data: {
            title,
            description,
            unitNumber,
            reportedBy,
            workOrderId,
            buildingId
          }
        });
        notifications.push({ type: 'email', userId: member.id, success: true });
      } catch (error) {
        console.error(`Failed to send email to ${member.id}:`, error);
        notifications.push({ type: 'email', userId: member.id, success: false, error: error instanceof Error ? error.message : 'Unknown error' });
      }
    }
  }

  return { notifications, totalSent: notifications.filter(n => n.success).length };
}

async function notifyWorkOrderAssigned(db: FirebaseFirestore.Firestore, buildingId: string, data: any) {
  const { workOrderId, title, vendorName } = data;
  
  // Notify vendor (if they have contact info)
  // This would typically be done through a separate vendor notification system
  
  // Notify building members
  const membersQuery = await db.collection(`buildings/${buildingId}/members`)
    .where('role', 'in', ['committee', 'super_admin'])
    .get();

  const notifications = [];

  for (const member of membersQuery.docs) {
    const memberData = member.data();
    
    if (memberData.fcmToken) {
      try {
        await sendPushNotification(memberData.fcmToken, {
          title: 'Work Order Assigned',
          body: `"${title}" assigned to ${vendorName}`,
          data: {
            type: 'work_order_assigned',
            workOrderId,
            buildingId
          }
        });
        notifications.push({ type: 'push', userId: member.id, success: true });
      } catch (error) {
        notifications.push({ type: 'push', userId: member.id, success: false, error: error instanceof Error ? error.message : 'Unknown error' });
      }
    }
  }

  return { notifications, totalSent: notifications.filter(n => n.success).length };
}

async function notifyWorkOrderCompleted(db: FirebaseFirestore.Firestore, buildingId: string, data: any) {
  const { workOrderId, title, vendorName } = data;
  
  // Notify building members
  const membersQuery = await db.collection(`buildings/${buildingId}/members`)
    .where('role', 'in', ['committee', 'super_admin'])
    .get();

  const notifications = [];

  for (const member of membersQuery.docs) {
    const memberData = member.data();
    
    if (memberData.fcmToken) {
      try {
        await sendPushNotification(memberData.fcmToken, {
          title: 'Work Order Completed',
          body: `"${title}" completed by ${vendorName}`,
          data: {
            type: 'work_order_completed',
            workOrderId,
            buildingId
          }
        });
        notifications.push({ type: 'push', userId: member.id, success: true });
      } catch (error) {
        notifications.push({ type: 'push', userId: member.id, success: false, error: error instanceof Error ? error.message : 'Unknown error' });
      }
    }
  }

  return { notifications, totalSent: notifications.filter(n => n.success).length };
}

async function notifyPaymentReceived(db: FirebaseFirestore.Firestore, buildingId: string, data: any) {
  const { invoiceId, amount, currency } = data;
  
  // Notify building members about payment
  const membersQuery = await db.collection(`buildings/${buildingId}/members`)
    .where('role', 'in', ['committee', 'super_admin'])
    .get();

  const notifications = [];

  for (const member of membersQuery.docs) {
    const memberData = member.data();
    
    if (memberData.fcmToken) {
      try {
        await sendPushNotification(memberData.fcmToken, {
          title: 'Payment Received',
          body: `Payment of ${amount} ${currency} received`,
          data: {
            type: 'payment_received',
            invoiceId,
            buildingId
          }
        });
        notifications.push({ type: 'push', userId: member.id, success: true });
      } catch (error) {
        notifications.push({ type: 'push', userId: member.id, success: false, error: error instanceof Error ? error.message : 'Unknown error' });
      }
    }
  }

  return { notifications, totalSent: notifications.filter(n => n.success).length };
}

async function notifyAnnouncement(db: FirebaseFirestore.Firestore, buildingId: string, data: any, recipients?: string[]) {
  const { title, body, type, priority } = data;
  
  let membersQuery;
  
  if (recipients && recipients.length > 0) {
    // Send to specific recipients
    membersQuery = await db.collection(`buildings/${buildingId}/members`)
      .where('uid', 'in', recipients)
      .get();
  } else {
    // Send to all active members
    membersQuery = await db.collection(`buildings/${buildingId}/members`)
      .where('isActive', '==', true)
      .get();
  }

  const notifications = [];

  for (const member of membersQuery.docs) {
    const memberData = member.data();
    
    if (memberData.fcmToken) {
      try {
        await sendPushNotification(memberData.fcmToken, {
          title,
          body,
          data: {
            type: 'announcement',
            announcementType: type,
            priority,
            buildingId
          }
        });
        notifications.push({ type: 'push', userId: member.id, success: true });
      } catch (error) {
        notifications.push({ type: 'push', userId: member.id, success: false, error: error instanceof Error ? error.message : 'Unknown error' });
      }
    }
  }

  return { notifications, totalSent: notifications.filter(n => n.success).length };
}

async function sendPushNotification(fcmToken: string, message: any) {
  try {
    const response = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: message.title,
        body: message.body
      },
      data: message.data,
      android: {
        priority: 'high',
        notification: {
          channelId: 'vaadly_notifications'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    });
    
    console.log('Push notification sent successfully:', response);
    return response;
  } catch (error) {
    console.error('Error sending push notification:', error);
    throw error;
  }
}

async function sendEmailNotification(email: string, data: any) {
  // TODO: Implement email sending using SendGrid or similar service
  // For now, just log the email data
  console.log('Email notification data:', { email, ...data });
  
  // Placeholder for email service integration
  // const emailService = new EmailService();
  // return await emailService.send(data);
  
  return { success: true, message: 'Email notification logged (service not implemented)' };
}

import * as admin from 'firebase-admin';
import { onRequest } from 'firebase-functions/v2/https';

export const notifyEnhanced = onRequest(async (req, res) => {
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

    const { buildingId, targets, title, body, emailHtml } = req.body as {
      buildingId: string;
      targets: { type: 'building'|'unit'|'resident'|'vendor'; id?: string };
      title: string; 
      body: string; 
      emailHtml?: string;
    };

    if (!buildingId || !targets || !title || !body) {
      res.status(400).json({ error: 'Missing required parameters' });
      return;
    }

    console.log(`Sending enhanced notification to building ${buildingId}, targets: ${targets.type}`);

    // Resolve recipients (uids)
    let uids: string[] = [];
    if (targets.type === 'building') {
      const snap = await db.collection(`buildings/${buildingId}/members`).get();
      uids = snap.docs.map(d => d.id);
    } else if (targets.type === 'resident' && targets.id) {
      uids = [targets.id];
    } else if (targets.type === 'unit' && targets.id) {
      const unit = await db.doc(`buildings/${buildingId}/units/${targets.id}`).get();
      uids = (unit.get('residentUids') || []) as string[];
    } else if (targets.type === 'vendor' && targets.id) {
      // For vendors, we might need to implement vendor-specific notification logic
      console.log(`Vendor notification not yet implemented for ${targets.id}`);
      uids = [];
    }

    // Gather device tokens & emails
    const tokens: string[] = [];
    const emails: string[] = [];
    const memberData: any[] = [];

    for (const uid of uids) {
      const mref = db.collection(`buildings/${buildingId}/members`).doc(uid);
      const m = await mref.get();
      
      if (m.exists) {
        const member = m.data();
        const email = member?.email;
        if (email) emails.push(email);
        
        // Get device tokens
        const tSnap = await mref.collection('deviceTokens').get();
        tSnap.forEach(t => tokens.push(t.id));
        
        memberData.push({
          uid,
          email,
          role: member?.role,
          unitNumber: member?.unitNumber
        });
      }
    }

    console.log(`Found ${tokens.length} device tokens and ${emails.length} emails`);

    // Push notifications (FCM)
    let pushResults = { success: 0, failed: 0 };
    if (tokens.length > 0) {
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens,
          notification: { title, body },
          data: {
            type: 'announcement',
            buildingId,
            timestamp: new Date().toISOString()
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'vaadly_notifications',
              priority: 'high'
            }
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
                alert: { title, body }
              }
            }
          }
        });
        
        pushResults = {
          success: response.successCount,
          failed: response.failureCount
        };
        
        console.log(`Push notifications sent: ${response.successCount} success, ${response.failureCount} failed`);
      } catch (error) {
        console.error('Error sending push notifications:', error);
        pushResults = { success: 0, failed: tokens.length };
      }
    }

    // Email notifications (SendGrid)
    let emailResults = { success: 0, failed: 0 };
    if (emails.length > 0 && emailHtml) {
      try {
        const sgApiKey = process.env.SENDGRID_API_KEY as string;
        const from = process.env.EMAIL_FROM || 'no-reply@vaadly.app';
        
        if (!sgApiKey) {
          console.warn('SendGrid API key not configured, skipping email notifications');
          emailResults = { success: 0, failed: emails.length };
        } else {
          const emailResponse = await fetch('https://api.sendgrid.com/v3/mail/send', {
            method: 'POST',
            headers: { 
              'Authorization': `Bearer ${sgApiKey}`, 
              'Content-Type': 'application/json' 
            },
            body: JSON.stringify({
              personalizations: emails.map(e => ({ to: [{ email: e }] })),
              from: { email: from, name: 'Vaadly Building Management' },
              subject: title,
              content: [{ type: 'text/html', value: emailHtml }]
            })
          });

          if (emailResponse.ok) {
            emailResults = { success: emails.length, failed: 0 };
            console.log(`Email notifications sent successfully to ${emails.length} recipients`);
          } else {
            const errorText = await emailResponse.text();
            console.error('SendGrid API error:', errorText);
            emailResults = { success: 0, failed: emails.length };
          }
        }
      } catch (error) {
        console.error('Error sending email notifications:', error);
        emailResults = { success: 0, failed: emails.length };
      }
    }

    // Log announcement in Firestore
    let announcementId: string | null = null;
    try {
      const announcementRef = await db.collection(`buildings/${buildingId}/announcements`).add({
        title,
        body,
        targets: targets,
        recipients: {
          total: uids.length,
          push: pushResults.success,
          email: emailResults.success
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: req.body.createdBy || 'system'
      });
      announcementId = announcementRef.id;
    } catch (error) {
      console.error('Error creating announcement:', error);
    }

    // Create audit log
    try {
      await db.collection(`buildings/${buildingId}/audit`).add({
        event: 'notification_sent',
        announcementId,
        targets: targets,
        title,
        body,
        recipients: uids.length,
        pushResults,
        emailResults,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        userId: req.body.createdBy || 'system'
      });
    } catch (error) {
      console.error('Error creating audit log:', error);
    }

    res.json({
      success: true,
      message: 'Enhanced notification sent successfully',
      results: {
        recipients: uids.length,
        push: pushResults,
        email: emailResults,
        announcementId
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error in enhanced notification:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Helper function to send targeted notifications
export async function sendTargetedNotification(
  buildingId: string,
  targets: { type: 'building'|'unit'|'resident'|'vendor'; id?: string },
  title: string,
  body: string,
  emailHtml?: string,
  createdBy?: string
) {
  try {
    const response = await fetch(`https://your-region-your-project.cloudfunctions.net/notifyEnhanced`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        buildingId,
        targets,
        title,
        body,
        emailHtml,
        createdBy
      })
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
    console.error('Error calling notification function:', error);
    throw error;
  }
}

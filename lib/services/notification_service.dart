import 'dart:convert';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/payment.dart';
import '../core/models/lease.dart';
import '../core/models/resident.dart';
import '../core/services/firebase_service.dart';

enum NotificationType {
  paymentReminder, // תזכורת תשלום
  paymentOverdue, // תשלום באיחור
  paymentReceived, // תשלום התקבל
  leaseExpiring, // חוזה פג תוקף
  leaseRenewal, // חידוש חוזה
  maintenanceRequest, // בקשת תחזוקה
  systemAlert, // התראת מערכת
}

class NotificationService {
  // Email configuration - in production, these should come from Firebase Remote Config
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _senderEmail =
      'vaadly@gmail.com'; // Replace with your email
  static const String _senderPassword =
      'your_app_password_here'; // Replace with app password
  static const String _senderName = 'Vaadly - ניהול נכסים';

  // WhatsApp Business API configuration (optional)
  static const String _whatsappApiUrl =
      'https://graph.facebook.com/v18.0/YOUR_PHONE_NUMBER_ID/messages';
  static const String _whatsappToken = 'YOUR_WHATSAPP_TOKEN';

  /// Initialize notification service
  static Future<void> initialize() async {
    try {
      await FirebaseService.initialize();
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Send payment reminder email
  static Future<bool> sendPaymentReminder({
    required Payment payment,
    required String recipientEmail,
    String? recipientName,
  }) async {
    try {
      final resident = await _getResidentInfo(payment.residentId);
      final subject = 'תזכורת תשלום - ${payment.title}';

      final htmlBody = _buildPaymentReminderHtml(
        payment: payment,
        residentName: resident?.fullName ?? recipientName ?? 'שוכר יקר',
        daysUntilDue: payment.dueDate.difference(DateTime.now()).inDays,
      );

      final plainBody = _buildPaymentReminderPlain(
        payment: payment,
        residentName: resident?.fullName ?? recipientName ?? 'שוכר יקר',
        daysUntilDue: payment.dueDate.difference(DateTime.now()).inDays,
      );

      return await _sendEmail(
        to: recipientEmail,
        subject: subject,
        htmlBody: htmlBody,
        plainBody: plainBody,
      );
    } catch (e) {
      print('❌ Error sending payment reminder: $e');
      return false;
    }
  }

  /// Send overdue payment notification
  static Future<bool> sendOverduePaymentNotification({
    required Payment payment,
    required String recipientEmail,
    String? recipientName,
  }) async {
    try {
      final resident = await _getResidentInfo(payment.residentId);
      final subject = '⚠️ תשלום באיחור - ${payment.title}';
      final daysOverdue = DateTime.now().difference(payment.dueDate).inDays;

      final htmlBody = _buildOverduePaymentHtml(
        payment: payment,
        residentName: resident?.fullName ?? recipientName ?? 'שוכר יקר',
        daysOverdue: daysOverdue,
      );

      final plainBody = _buildOverduePaymentPlain(
        payment: payment,
        residentName: resident?.fullName ?? recipientName ?? 'שוכר יקר',
        daysOverdue: daysOverdue,
      );

      return await _sendEmail(
        to: recipientEmail,
        subject: subject,
        htmlBody: htmlBody,
        plainBody: plainBody,
        priority: true,
      );
    } catch (e) {
      print('❌ Error sending overdue payment notification: $e');
      return false;
    }
  }

  /// Send payment confirmation
  static Future<bool> sendPaymentConfirmation({
    required Payment payment,
    required String recipientEmail,
    String? recipientName,
  }) async {
    try {
      final resident = await _getResidentInfo(payment.residentId);
      final subject = '✅ תשלום התקבל - ${payment.title}';

      final htmlBody = _buildPaymentConfirmationHtml(
        payment: payment,
        residentName: resident?.fullName ?? recipientName ?? 'שוכר יקר',
      );

      final plainBody = _buildPaymentConfirmationPlain(
        payment: payment,
        residentName: resident?.fullName ?? recipientName ?? 'שוכר יקר',
      );

      return await _sendEmail(
        to: recipientEmail,
        subject: subject,
        htmlBody: htmlBody,
        plainBody: plainBody,
      );
    } catch (e) {
      print('❌ Error sending payment confirmation: $e');
      return false;
    }
  }

  /// Send lease expiration notice
  static Future<bool> sendLeaseExpirationNotice({
    required Lease lease,
    required String recipientEmail,
    String? recipientName,
  }) async {
    try {
      final resident = await _getResidentInfo(lease.tenantId);
      const subject = '📋 התראה: חוזה השכירות פג תוקף בקרוב';
      final daysUntilExpiry = lease.endDate.difference(DateTime.now()).inDays;

      final htmlBody = _buildLeaseExpirationHtml(
        lease: lease,
        residentName: resident?.fullName ?? recipientName ?? 'שוכר יקר',
        daysUntilExpiry: daysUntilExpiry,
      );

      final plainBody = _buildLeaseExpirationPlain(
        lease: lease,
        residentName: resident?.fullName ?? recipientName ?? 'שוכר יקר',
        daysUntilExpiry: daysUntilExpiry,
      );

      return await _sendEmail(
        to: recipientEmail,
        subject: subject,
        htmlBody: htmlBody,
        plainBody: plainBody,
        priority: true,
      );
    } catch (e) {
      print('❌ Error sending lease expiration notice: $e');
      return false;
    }
  }

  /// Send bulk notifications to all overdue payments
  static Future<List<bool>> sendBulkOverdueNotifications(
      List<Payment> overduePayments) async {
    try {
      print(
          '📧 Sending bulk overdue notifications to ${overduePayments.length} payments...');

      final results = <bool>[];

      for (final payment in overduePayments) {
        if (payment.residentId != null) {
          final resident = await _getResidentInfo(payment.residentId);
          if (resident != null && resident.email.isNotEmpty) {
            final success = await sendOverduePaymentNotification(
              payment: payment,
              recipientEmail: resident.email,
              recipientName: resident.fullName,
            );
            results.add(success);

            // Add delay between emails to avoid spam detection
            await Future.delayed(const Duration(seconds: 2));
          } else {
            results.add(false);
          }
        } else {
          results.add(false);
        }
      }

      final successCount = results.where((r) => r).length;
      print(
          '✅ Sent $successCount/${overduePayments.length} overdue notifications');

      return results;
    } catch (e) {
      print('❌ Error sending bulk overdue notifications: $e');
      return [];
    }
  }

  /// Schedule automatic reminder notifications
  static Future<void> scheduleAutomaticReminders(String buildingId) async {
    try {
      print('⏰ Scheduling automatic reminders for building $buildingId...');

      // In a real app, this would integrate with a job scheduler like Firebase Functions
      // For now, we'll create the logic that would be called by a cron job

      final reminderConfig = {
        'buildingId': buildingId,
        'enabled': true,
        'reminderDaysBefore': [
          7,
          3,
          1
        ], // Send reminders 7, 3, and 1 days before due date
        'overdueReminderDays': [
          1,
          7,
          14
        ], // Send overdue notices 1, 7, and 14 days after due date
        'leaseExpirationDays': [
          90,
          60,
          30,
          14
        ], // Send lease expiration notices
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseService.addDocument(
        'buildings/$buildingId/notification_config',
        reminderConfig,
      );

      print('✅ Automatic reminders scheduled');
    } catch (e) {
      print('❌ Error scheduling automatic reminders: $e');
    }
  }

  /// Send WhatsApp notification (requires WhatsApp Business API)
  static Future<bool> sendWhatsAppNotification({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $_whatsappToken',
        'Content-Type': 'application/json',
      };

      final body = {
        'messaging_product': 'whatsapp',
        'to': phoneNumber,
        'type': 'text',
        'text': {
          'body': message,
        },
      };

      final response = await http.post(
        Uri.parse(_whatsappApiUrl),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('✅ WhatsApp message sent successfully');
        return true;
      } else {
        print('❌ WhatsApp API error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending WhatsApp notification: $e');
      return false;
    }
  }

  // Private helper methods
  static Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    required String plainBody,
    bool priority = false,
  }) async {
    try {
      final smtpServer = gmail(_senderEmail, _senderPassword);

      final message = Message()
        ..from = const Address(_senderEmail, _senderName)
        ..recipients.add(to)
        ..subject = subject
        ..text = plainBody
        ..html = htmlBody;

      if (priority) {
        message.headers['X-Priority'] = '1';
        message.headers['X-MSMail-Priority'] = 'High';
        message.headers['Importance'] = 'High';
      }

      final sendReport = await send(message, smtpServer);
      print('✅ Email sent to $to: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('❌ Error sending email to $to: $e');
      return false;
    }
  }

  static Future<Resident?> _getResidentInfo(String? residentId) async {
    if (residentId == null) return null;

    try {
      // This would need to be implemented based on your resident service
      // For now, return null and use fallback name
      return null;
    } catch (e) {
      print('❌ Error getting resident info: $e');
      return null;
    }
  }

  // HTML email templates
  static String _buildPaymentReminderHtml({
    required Payment payment,
    required String residentName,
    required int daysUntilDue,
  }) {
    final dueText = daysUntilDue > 0
        ? 'בעוד $daysUntilDue ימים'
        : daysUntilDue == 0
            ? 'היום'
            : 'לפני ${-daysUntilDue} ימים';

    return '''
<!DOCTYPE html>
<html dir="rtl" lang="he">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>תזכורת תשלום</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #2196F3; color: white; padding: 20px; border-radius: 10px 10px 0 0; text-align: center; }
        .content { padding: 30px; }
        .amount { font-size: 24px; font-weight: bold; color: #2196F3; text-align: center; margin: 20px 0; }
        .button { display: inline-block; background-color: #4CAF50; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { background-color: #f0f0f0; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>תזכורת תשלום</h1>
        </div>
        <div class="content">
            <p>שלום $residentName,</p>
            <p>זוהי תזכורת ידידותית לתשלום הבא:</p>
            
            <div style="background-color: #f9f9f9; padding: 20px; border-radius: 5px; margin: 20px 0;">
                <h3>${payment.title}</h3>
                <p><strong>סכום:</strong> ₪${payment.amount.toStringAsFixed(2)}</p>
                <p><strong>תאריך יעד:</strong> ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year} ($dueText)</p>
                ${payment.description != null ? '<p><strong>פירוט:</strong> ${payment.description}</p>' : ''}
            </div>
            
            <div class="amount">₪${payment.amount.toStringAsFixed(2)}</div>
            
            <div style="text-align: center;">
                <a href="https://your-payment-link.com" class="button">שלם עכשיו</a>
            </div>
            
            <p>אם כבר שילמת, נא להתעלם מהודעה זו.</p>
            <p>לשאלות נוספות, ניתן ליצור קשר דרך המערכת או בטלפון.</p>
            
            <p>בברכה,<br>צוות Vaadly</p>
        </div>
        <div class="footer">
            <p>זוהי הודעה אוטומטית ממערכת ניהול הנכסים Vaadly</p>
        </div>
    </div>
</body>
</html>
''';
  }

  static String _buildOverduePaymentHtml({
    required Payment payment,
    required String residentName,
    required int daysOverdue,
  }) {
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="he">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>תשלום באיחור</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #f44336; color: white; padding: 20px; border-radius: 10px 10px 0 0; text-align: center; }
        .content { padding: 30px; }
        .amount { font-size: 24px; font-weight: bold; color: #f44336; text-align: center; margin: 20px 0; }
        .warning { background-color: #ffebee; border-left: 4px solid #f44336; padding: 15px; margin: 20px 0; }
        .button { display: inline-block; background-color: #f44336; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { background-color: #f0f0f0; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚠️ תשלום באיחור</h1>
        </div>
        <div class="content">
            <p>שלום $residentName,</p>
            <p>התשלום הבא באיחור של $daysOverdue ימים:</p>
            
            <div class="warning">
                <h3>${payment.title}</h3>
                <p><strong>סכום:</strong> ₪${payment.amount.toStringAsFixed(2)}</p>
                <p><strong>תאריך יעד שעבר:</strong> ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}</p>
                <p><strong>ימי איחור:</strong> $daysOverdue ימים</p>
                ${payment.description != null ? '<p><strong>פירוט:</strong> ${payment.description}</p>' : ''}
            </div>
            
            <div class="amount">₪${payment.amount.toStringAsFixed(2)}</div>
            
            <div style="text-align: center;">
                <a href="https://your-payment-link.com" class="button">שלם מיידית</a>
            </div>
            
            <p><strong>חשוב:</strong> תשלום באיחור עלול לגרור קנסות נוספים. אנא שלם בהקדם האפשרי.</p>
            <p>לבעיות בתשלום או לתיאום פריסה, אנא צרו קשר בהקדם.</p>
            
            <p>בברכה,<br>צוות Vaadly</p>
        </div>
        <div class="footer">
            <p>זוהי הודעה אוטומטית ממערכת ניהול הנכסים Vaadly</p>
        </div>
    </div>
</body>
</html>
''';
  }

  static String _buildPaymentConfirmationHtml({
    required Payment payment,
    required String residentName,
  }) {
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="he">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>אישור תשלום</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #4CAF50; color: white; padding: 20px; border-radius: 10px 10px 0 0; text-align: center; }
        .content { padding: 30px; }
        .amount { font-size: 24px; font-weight: bold; color: #4CAF50; text-align: center; margin: 20px 0; }
        .success { background-color: #e8f5e8; border-left: 4px solid #4CAF50; padding: 15px; margin: 20px 0; }
        .footer { background-color: #f0f0f0; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>✅ תשלום התקבל</h1>
        </div>
        <div class="content">
            <p>שלום $residentName,</p>
            <p>תשלומך התקבל בהצלחה!</p>
            
            <div class="success">
                <h3>${payment.title}</h3>
                <p><strong>סכום שולם:</strong> ₪${payment.amount.toStringAsFixed(2)}</p>
                <p><strong>תאריך תשלום:</strong> ${payment.paidDate?.day}/${payment.paidDate?.month}/${payment.paidDate?.year}</p>
                <p><strong>מזהה תשלום:</strong> ${payment.id}</p>
                ${payment.paymentReference != null ? '<p><strong>אסמכתא:</strong> ${payment.paymentReference}</p>' : ''}
            </div>
            
            <div class="amount">₪${payment.amount.toStringAsFixed(2)}</div>
            
            <p>תודה על התשלום במועד!</p>
            <p>קבלה מפורטת זמינה במערכת או ניתנת להורדה מהקישור למטה.</p>
            
            <p>בברכה,<br>צוות Vaadly</p>
        </div>
        <div class="footer">
            <p>זוהי הודעה אוטומטית ממערכת ניהול הנכסים Vaadly</p>
        </div>
    </div>
</body>
</html>
''';
  }

  static String _buildLeaseExpirationHtml({
    required Lease lease,
    required String residentName,
    required int daysUntilExpiry,
  }) {
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="he">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>חוזה פג תוקף</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background-color: #FF9800; color: white; padding: 20px; border-radius: 10px 10px 0 0; text-align: center; }
        .content { padding: 30px; }
        .notice { background-color: #fff3e0; border-left: 4px solid #FF9800; padding: 15px; margin: 20px 0; }
        .button { display: inline-block; background-color: #FF9800; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { background-color: #f0f0f0; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📋 התראת חוזה</h1>
        </div>
        <div class="content">
            <p>שלום $residentName,</p>
            <p>חוזה השכירות שלך עומד לפוג בעוד $daysUntilExpiry ימים:</p>
            
            <div class="notice">
                <h3>${lease.title}</h3>
                <p><strong>יחידה:</strong> ${lease.unitId}</p>
                <p><strong>תאריך תפוגה:</strong> ${lease.endDate.day}/${lease.endDate.month}/${lease.endDate.year}</p>
                <p><strong>שכירות חודשית:</strong> ₪${lease.monthlyRent.toStringAsFixed(2)}</p>
                <p><strong>ימים עד תפוגה:</strong> $daysUntilExpiry ימים</p>
            </div>
            
            <p>אנא צרו קשר בהקדם לתיאום חידוש החוזה או להודעה על כוונת לעזוב.</p>
            
            <div style="text-align: center;">
                <a href="https://your-renewal-link.com" class="button">צור קשר לחידוש</a>
            </div>
            
            <p><strong>חשוב:</strong> חוזים שלא מחודשים בזמן עלולים לגרור לבעיות משפטיות או פיצויים.</p>
            
            <p>בברכה,<br>צוות Vaadly</p>
        </div>
        <div class="footer">
            <p>זוהי הודעה אוטומטית ממערכת ניהול הנכסים Vaadly</p>
        </div>
    </div>
</body>
</html>
''';
  }

  // Plain text templates (fallback for email clients that don't support HTML)
  static String _buildPaymentReminderPlain({
    required Payment payment,
    required String residentName,
    required int daysUntilDue,
  }) {
    final dueText = daysUntilDue > 0
        ? 'בעוד $daysUntilDue ימים'
        : daysUntilDue == 0
            ? 'היום'
            : 'לפני ${-daysUntilDue} ימים';

    return '''
שלום $residentName,

זוהי תזכורת ידידותית לתשלום הבא:

${payment.title}
סכום: ₪${payment.amount.toStringAsFixed(2)}
תאריך יעד: ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year} ($dueText)
${payment.description != null ? 'פירוט: ${payment.description}' : ''}

אם כבר שילמת, נא להתעלם מהודעה זו.
לשאלות נוספות, ניתן ליצור קשר דרך המערכת או בטלפון.

בברכה,
צוות Vaadly

זוהי הודעה אוטומטית ממערכת ניהול הנכסים Vaadly
''';
  }

  static String _buildOverduePaymentPlain({
    required Payment payment,
    required String residentName,
    required int daysOverdue,
  }) {
    return '''
שלום $residentName,

התשלום הבא באיחור של $daysOverdue ימים:

${payment.title}
סכום: ₪${payment.amount.toStringAsFixed(2)}
תאריך יעד שעבר: ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}
ימי איחור: $daysOverdue ימים
${payment.description != null ? 'פירוט: ${payment.description}' : ''}

חשוב: תשלום באיחור עלול לגרור קנסות נוספים. אנא שלם בהקדם האפשרי.
לבעיות בתשלום או לתיאום פריסה, אנא צרו קשר בהקדם.

בברכה,
צוות Vaadly

זוהי הודעה אוטומטית ממערכת ניהול הנכסים Vaadly
''';
  }

  static String _buildPaymentConfirmationPlain({
    required Payment payment,
    required String residentName,
  }) {
    return '''
שלום $residentName,

תשלומך התקבל בהצלחה!

${payment.title}
סכום שולם: ₪${payment.amount.toStringAsFixed(2)}
תאריך תשלום: ${payment.paidDate?.day}/${payment.paidDate?.month}/${payment.paidDate?.year}
מזהה תשלום: ${payment.id}
${payment.paymentReference != null ? 'אסמכתא: ${payment.paymentReference}' : ''}

תודה על התשלום במועד!
קבלה מפורטת זמינה במערכת.

בברכה,
צוות Vaadly

זוהי הודעה אוטומטית ממערכת ניהול הנכסים Vaadly
''';
  }

  static String _buildLeaseExpirationPlain({
    required Lease lease,
    required String residentName,
    required int daysUntilExpiry,
  }) {
    return '''
שלום $residentName,

חוזה השכירות שלך עומד לפוג בעוד $daysUntilExpiry ימים:

${lease.title}
יחידה: ${lease.unitId}
תאריך תפוגה: ${lease.endDate.day}/${lease.endDate.month}/${lease.endDate.year}
שכירות חודשית: ₪${lease.monthlyRent.toStringAsFixed(2)}
ימים עד תפוגה: $daysUntilExpiry ימים

אנא צרו קשר בהקדם לתיאום חידוש החוזה או להודעה על כוונת לעזוב.

חשוב: חוזים שלא מחודשים בזמן עלולים לגרור לבעיות משפטיות או פיצויים.

בברכה,
צוות Vaadly

זוהי הודעה אוטומטית ממערכת ניהול הנכסים Vaadly
''';
  }
}

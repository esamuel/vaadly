import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FCMTokenManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Request notification permissions and register FCM token
  static Future<bool> requestPermissionsAndRegister({
    required String buildingId,
    required String uid,
  }) async {
    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          await registerToken(buildingId: buildingId, uid: uid, token: token);
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
      return false;
    }
  }

  /// Register FCM token for a specific user in a building
  static Future<void> registerToken({
    required String buildingId,
    required String uid,
    required String token,
  }) async {
    try {
      final tokenRef = _firestore
          .doc('buildings/$buildingId/members/$uid/deviceTokens/$token');

      await tokenRef.set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
        'appVersion': _getAppVersion(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print(
            'FCM token registered successfully for user $uid in building $buildingId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token: $e');
      }
      rethrow;
    }
  }

  /// Unregister FCM token (e.g., on logout)
  static Future<void> unregisterToken({
    required String buildingId,
    required String uid,
    required String token,
  }) async {
    try {
      final tokenRef = _firestore
          .doc('buildings/$buildingId/members/$uid/deviceTokens/$token');

      await tokenRef.delete();

      if (kDebugMode) {
        print(
            'FCM token unregistered successfully for user $uid in building $buildingId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unregistering FCM token: $e');
      }
      rethrow;
    }
  }

  /// Get all registered tokens for a user
  static Future<List<String>> getRegisteredTokens({
    required String buildingId,
    required String uid,
  }) async {
    try {
      final tokensSnapshot = await _firestore
          .collection('buildings/$buildingId/members/$uid/deviceTokens')
          .get();

      return tokensSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting registered tokens: $e');
      }
      return [];
    }
  }

  /// Clean up old tokens (remove tokens older than 30 days)
  static Future<void> cleanupOldTokens({
    required String buildingId,
    required String uid,
  }) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final cutoffTimestamp = Timestamp.fromDate(thirtyDaysAgo);

      final oldTokensSnapshot = await _firestore
          .collection('buildings/$buildingId/members/$uid/deviceTokens')
          .where('lastSeen', isLessThan: cutoffTimestamp)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldTokensSnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (oldTokensSnapshot.docs.isNotEmpty) {
        await batch.commit();
        if (kDebugMode) {
          print('Cleaned up ${oldTokensSnapshot.docs.length} old FCM tokens');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old tokens: $e');
      }
    }
  }

  /// Update last seen timestamp for a token
  static Future<void> updateTokenLastSeen({
    required String buildingId,
    required String uid,
    required String token,
  }) async {
    try {
      final tokenRef = _firestore
          .doc('buildings/$buildingId/members/$uid/deviceTokens/$token');

      await tokenRef.update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating token last seen: $e');
      }
    }
  }

  /// Get platform information
  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'macos';
    if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'linux';
    return 'unknown';
  }

  /// Get app version (placeholder - implement based on your app)
  static String _getAppVersion() {
    // TODO: Implement based on your app's version system
    return '1.0.0';
  }

  /// Set up FCM message handlers
  static void setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
      }

      // TODO: Show in-app notification banner
      // You can use flutter_local_notifications or a custom banner
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
        print('Message data: ${message.data}');
      }

      // TODO: Navigate to specific screen based on message data
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

// This needs to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }

  // TODO: Handle background message processing
  // Note: This function must be top-level and cannot be a class method
}

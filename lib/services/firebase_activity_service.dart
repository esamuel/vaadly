import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log a building activity event
  static Future<void> logActivity({
    required String buildingId,
    required String type, // e.g., 'resident_added', 'vendor_added', 'maintenance_created'
    required String title,
    String? subtitle,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _firestore.collection('building_activities').add({
        'buildingId': buildingId,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'extra': extra ?? {},
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Best-effort logging; don't throw
      // ignore: avoid_print
      print('❌ Error logging activity: $e');
    }
  }

  // Stream recent activities for a building (most recent first)
  static Stream<List<Map<String, dynamic>>> streamRecentActivities(String buildingId, {int limit = 10}) {
    return _firestore
        .collection('building_activities')
        .where('buildingId', isEqualTo: buildingId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}


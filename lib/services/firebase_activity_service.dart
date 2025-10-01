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
        // Use server timestamp for reliable ordering
        'createdAt': FieldValue.serverTimestamp(),
        // Also store a numeric millis field for client-side sort fallbacks
        'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Best-effort logging; don't throw
      // ignore: avoid_print
      print('❌ Error logging activity: $e');
    }
  }

  // Stream recent activities for a building (most recent first)
  static Stream<List<Map<String, dynamic>>> streamRecentActivities(String buildingId, {int limit = 10}) {
    // Avoid ordering at the server to handle mixed types from older records
    return _firestore
        .collection('building_activities')
        .where('buildingId', isEqualTo: buildingId)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
          items.sort((a, b) {
            int am = 0, bm = 0;
            final av = a['createdAt'];
            final bv = b['createdAt'];
            if (a['createdAtMillis'] is int) am = a['createdAtMillis'] as int;
            if (b['createdAtMillis'] is int) bm = b['createdAtMillis'] as int;
            if (am == 0 && av != null) {
              // Try parse
              if (av is Timestamp) {
                am = (av as Timestamp).millisecondsSinceEpoch;
              } else if (av is String) {
                try { am = DateTime.parse(av).millisecondsSinceEpoch; } catch (_) {}
              }
            }
            if (bm == 0 && bv != null) {
              if (bv is Timestamp) {
                bm = (bv as Timestamp).millisecondsSinceEpoch;
              } else if (bv is String) {
                try { bm = DateTime.parse(bv).millisecondsSinceEpoch; } catch (_) {}
              }
            }
            return bm.compareTo(am); // desc
          });
          if (items.length > limit) return items.sublist(0, limit);
          return items;
        });
  }

  // One-off migration: populate userName in asset assignment activities
  static Future<int> migrateActivityUserNames(String buildingId) async {
    try {
      final coll = _firestore.collection('building_activities');
      final snap = await coll.where('buildingId', isEqualTo: buildingId).get();
      int updated = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['type'] != 'asset_assigned') continue;
        final extra = (data['extra'] as Map?)?.cast<String, dynamic>() ?? {};
        final existingName = extra['userName'] as String?;
        final userId = extra['userId'] as String?;
        if ((existingName == null || existingName.isEmpty) && userId != null && userId.isNotEmpty) {
          try {
            final res = await _firestore.collection('residents').doc(userId).get();
            if (res.exists) {
              final r = res.data()!;
              final first = (r['firstName'] ?? '').toString();
              final last = (r['lastName'] ?? '').toString();
              final fullName = (first + ' ' + last).trim();
              if (fullName.isNotEmpty) {
                final newSubtitle = 'מס׳ ${extra['number'] ?? ''}, לדייר $fullName';
                await doc.reference.update({
                  'subtitle': newSubtitle,
                  'extra.userName': fullName,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                updated++;
              }
            }
          } catch (_) {}
        }
      }
      return updated;
    } catch (e) {
      print('❌ migrateActivityUserNames error: $e');
      return 0;
    }
  }
}

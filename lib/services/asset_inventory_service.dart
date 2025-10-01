import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_activity_service.dart';

class AssetInventoryService {
  static String typeLabel(String key) {
    switch (key) {
      case 'storage':
        return 'מחסן';
      case 'parking':
        return 'חניה';
      default:
        return 'נכס';
    }
  }

  static final _db = FirebaseFirestore.instance;

  // Seed storages and parking spots for a building (numbered 1..N)
  static Future<void> seedInventoryForBuilding({
    required String buildingId,
    required int storageCount,
    required int parkingCount,
  }) async {
    final batch = _db.batch();

    // Storages
    if (storageCount > 0) {
      final storagesCol =
          _db.collection('buildings').doc(buildingId).collection('storages');
      for (int i = 1; i <= storageCount; i++) {
        final id = _formatId('s', i);
        final ref = storagesCol.doc(id);
        batch.set(
            ref,
            {
              'number': i.toString(),
              'label': 'מחסן ${_pad(i)}',
              'status': 'available',
              'assignedToUserId': null,
              'assignedToUnitId': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'type': 'storage',
            },
            SetOptions(merge: true));
      }
    }

    // Parking
    if (parkingCount > 0) {
      final parkingCol =
          _db.collection('buildings').doc(buildingId).collection('parking');
      for (int i = 1; i <= parkingCount; i++) {
        final id = _formatId('p', i);
        final ref = parkingCol.doc(id);
        batch.set(
            ref,
            {
              'number': i.toString(),
              'label': 'חניה ${_pad(i)}',
              'status': 'available',
              'assignedToUserId': null,
              'assignedToUnitId': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'type': 'parking',
            },
            SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  // Assign/unassign storage
  static Future<void> assignStorage({
    required String buildingId,
    required String number, // e.g. '7'
    required String userId,
    String? userName,
    String? unitId,
  }) async {
    final docId = _formatId('s', int.parse(number));
    final ref = _db
        .collection('buildings')
        .doc(buildingId)
        .collection('storages')
        .doc(docId);
    await ref.set({
      'status': 'assigned',
      'assignedToUserId': userId,
      'assignedToUnitId': unitId,
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Log activity (best-effort)
    await FirebaseActivityService.logActivity(
      buildingId: buildingId,
      type: 'asset_assigned',
      title: '${typeLabel('storage')} הוקצה',
      subtitle: userName != null && userName.isNotEmpty
          ? 'מס׳ $number, לדייר $userName'
          : 'מס׳ $number, למשתמש $userId',
      extra: {
        'number': number,
        'userId': userId,
        'userName': userName,
        'unitId': unitId,
        'assetType': 'storage'
      },
    );
  }

  static Future<void> unassignStorage({
    required String buildingId,
    required String number,
  }) async {
    final docId = _formatId('s', int.parse(number));
    final ref = _db
        .collection('buildings')
        .doc(buildingId)
        .collection('storages')
        .doc(docId);
    await ref.set({
      'status': 'available',
      'assignedToUserId': null,
      'assignedToUnitId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await FirebaseActivityService.logActivity(
      buildingId: buildingId,
      type: 'asset_unassigned',
      title: '${typeLabel('storage')} בוטלה הקצאה',
      subtitle: 'מס׳ $number',
      extra: {'number': number, 'assetType': 'storage'},
    );
  }

  // Assign/unassign parking
  static Future<void> assignParking({
    required String buildingId,
    required String number,
    required String userId,
    String? userName,
    String? unitId,
  }) async {
    final docId = _formatId('p', int.parse(number));
    final ref = _db
        .collection('buildings')
        .doc(buildingId)
        .collection('parking')
        .doc(docId);
    await ref.set({
      'status': 'assigned',
      'assignedToUserId': userId,
      'assignedToUnitId': unitId,
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await FirebaseActivityService.logActivity(
      buildingId: buildingId,
      type: 'asset_assigned',
      title: '${typeLabel('parking')} הוקצה',
      subtitle: userName != null && userName.isNotEmpty
          ? 'מס׳ $number, לדייר $userName'
          : 'מס׳ $number, למשתמש $userId',
      extra: {
        'number': number,
        'userId': userId,
        'userName': userName,
        'unitId': unitId,
        'assetType': 'parking'
      },
    );
  }

  static Future<void> unassignParking({
    required String buildingId,
    required String number,
  }) async {
    final docId = _formatId('p', int.parse(number));
    final ref = _db
        .collection('buildings')
        .doc(buildingId)
        .collection('parking')
        .doc(docId);
    await ref.set({
      'status': 'available',
      'assignedToUserId': null,
      'assignedToUnitId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await FirebaseActivityService.logActivity(
      buildingId: buildingId,
      type: 'asset_unassigned',
      title: '${typeLabel('parking')} בוטלה הקצאה',
      subtitle: 'מס׳ $number',
      extra: {'number': number, 'assetType': 'parking'},
    );
  }

  // Streams
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamStorages(
      String buildingId) {
    return _db
        .collection('buildings')
        .doc(buildingId)
        .collection('storages')
        .orderBy('number')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamParking(
      String buildingId) {
    return _db
        .collection('buildings')
        .doc(buildingId)
        .collection('parking')
        .orderBy('number')
        .snapshots();
  }

  static String _formatId(String prefix, int i) => '$prefix-${_pad(i)}';
  static String _pad(int i) => i.toString().padLeft(3, '0');
}

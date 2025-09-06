import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class BuildingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Building? _currentBuilding;
  List<BuildingMember> _members = [];
  List<Unit> _units = [];
  bool _isLoading = false;
  String? _error;

  Building? get currentBuilding => _currentBuilding;
  List<BuildingMember> get members => _members;
  List<Unit> get units => _units;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBuilding(String buildingId) async {
    try {
      _setLoading(true);
      _setError(null);

      final doc =
          await _firestore.collection('buildings').doc(buildingId).get();
      if (doc.exists) {
        _currentBuilding = Building.fromFirestore(doc);
        await _loadMembers(buildingId);
        await _loadUnits(buildingId);
      } else {
        _setError('Building not found');
      }
    } catch (e) {
      _setError('Failed to load building: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadMembers(String buildingId) async {
    try {
      final query = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('members')
          .where('isActive', isEqualTo: true)
          .get();

      _members =
          query.docs.map((doc) => BuildingMember.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load members: $e');
    }
  }

  Future<void> _loadUnits(String buildingId) async {
    try {
      final query = await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('units')
          .orderBy('number')
          .get();

      _units = query.docs.map((doc) => Unit.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load units: $e');
    }
  }

  Future<void> addMember(BuildingMember member) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(member.buildingId)
          .collection('members')
          .doc(member.uid)
          .set(member.toMap());

      _members.add(member);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add member: $e');
    }
  }

  Future<void> updateMember(BuildingMember member) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(member.buildingId)
          .collection('members')
          .doc(member.uid)
          .update(member.toMap());

      final index = _members.indexWhere((m) => m.uid == member.uid);
      if (index != -1) {
        _members[index] = member;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update member: $e');
    }
  }

  Future<void> addUnit(Unit unit) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(unit.buildingId)
          .collection('units')
          .doc(unit.id)
          .set(unit.toMap());

      _units.add(unit);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add unit: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

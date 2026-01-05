import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants.dart';
import '../../models/models.dart';

/// Remote data source for Firestore operations
abstract class FirestoreDataSource {
  /// Hauler operations
  Future<HaulerModel?> getHauler(String haulerId);
  Future<void> createHauler(HaulerModel hauler);
  Future<void> updateHauler(String haulerId, Map<String, dynamic> data);
  Stream<HaulerModel?> streamHauler(String haulerId);

  /// Event operations
  Future<void> saveEvent(HaulerEventModel event);
  Stream<List<HaulerEventModel>> streamCycleEvents(String cycleId);

  /// Telemetry operations
  Future<void> saveTelemetry(TelemetryModel telemetry);

  /// Cycle operations
  Future<void> createCycle(CycleModel cycle);
  Future<void> updateCycle(CycleModel cycle);
  Future<CycleModel?> getCycle(String cycleId);
  Stream<CycleModel?> streamCurrentCycle(String haulerId);

  /// Loader operations
  Stream<List<LoaderModel>> streamLoaders();
  Future<LoaderModel?> getLoader(String loaderId);
}

/// Implementation of FirestoreDataSource
class FirestoreDataSourceImpl implements FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _haulerRef(String haulerId) {
    return _firestore.collection(AppConstants.collectionHaulers).doc(haulerId);
  }

  // ============ Hauler Operations ============

  @override
  Future<HaulerModel?> getHauler(String haulerId) async {
    final doc = await _haulerRef(haulerId).get();
    if (doc.exists && doc.data() != null) {
      return HaulerModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<void> createHauler(HaulerModel hauler) async {
    await _haulerRef(hauler.id).set(hauler.toMap());
  }

  @override
  Future<void> updateHauler(String haulerId, Map<String, dynamic> data) async {
    data['deviceTime'] = DateTime.now().toIso8601String();
    await _haulerRef(haulerId).update(data);
  }

  @override
  Stream<HaulerModel?> streamHauler(String haulerId) {
    return _haulerRef(haulerId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return HaulerModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // ============ Event Operations ============

  @override
  Future<void> saveEvent(HaulerEventModel event) async {
    final eventData = event.toMap();
    eventData['serverTime'] = FieldValue.serverTimestamp();
    
    await _firestore
        .collection(AppConstants.collectionHaulerEvents)
        .doc(event.dedupKey)
        .set(eventData, SetOptions(merge: true));
  }

  @override
  Stream<List<HaulerEventModel>> streamCycleEvents(String cycleId) {
    return _firestore
        .collection(AppConstants.collectionHaulerEvents)
        .where('cycleId', isEqualTo: cycleId)
        .orderBy('seq')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HaulerEventModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============ Telemetry Operations ============

  @override
  Future<void> saveTelemetry(TelemetryModel telemetry) async {
    final data = telemetry.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    
    await _firestore
        .collection(AppConstants.collectionTelemetry)
        .doc(telemetry.id)
        .set(data);
  }

  // ============ Cycle Operations ============

  @override
  Future<void> createCycle(CycleModel cycle) async {
    await _firestore
        .collection(AppConstants.collectionCycles)
        .doc(cycle.id)
        .set(cycle.toMap());
  }

  @override
  Future<void> updateCycle(CycleModel cycle) async {
    await _firestore
        .collection(AppConstants.collectionCycles)
        .doc(cycle.id)
        .update(cycle.toMap());
  }

  @override
  Future<CycleModel?> getCycle(String cycleId) async {
    final doc = await _firestore
        .collection(AppConstants.collectionCycles)
        .doc(cycleId)
        .get();

    if (doc.exists && doc.data() != null) {
      return CycleModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Stream<CycleModel?> streamCurrentCycle(String haulerId) {
    return _firestore
        .collection(AppConstants.collectionCycles)
        .where('haulerId', isEqualTo: haulerId)
        .where('completed', isEqualTo: false)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return CycleModel.fromMap(doc.data(), doc.id);
        });
  }

  // ============ Loader Operations ============

  @override
  Stream<List<LoaderModel>> streamLoaders() {
    return _firestore
        .collection(AppConstants.collectionLoaders)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoaderModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<LoaderModel?> getLoader(String loaderId) async {
    final doc = await _firestore
        .collection(AppConstants.collectionLoaders)
        .doc(loaderId)
        .get();

    if (doc.exists && doc.data() != null) {
      return LoaderModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}



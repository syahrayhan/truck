import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants.dart';
import '../../domain/entities/ping_result.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../datasources/datasources.dart';

/// Implementation of ConnectivityRepository with ping-based sync strategy
class ConnectivityRepositoryImpl implements ConnectivityRepository {
  final OfflineQueueDataSource offlineQueue;
  final FirestoreDataSource firestoreDataSource;
  final FirebaseFirestore _firestore;
  final PingService _pingService;
  
  bool _isOnline = true;
  PingResult? _currentPing;
  
  final StreamController<bool> _connectivityController = 
      StreamController<bool>.broadcast();
  final StreamController<PingResult> _pingStreamController =
      StreamController<PingResult>.broadcast();

  StreamSubscription<PingResult>? _pingSubscription;

  ConnectivityRepositoryImpl({
    required this.offlineQueue,
    required this.firestoreDataSource,
    FirebaseFirestore? firestore,
    PingService? pingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _pingService = pingService ?? PingService() {
    _initConnectivity();
  }

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      _isOnline = results.isNotEmpty && 
                  results.first != ConnectivityResult.none;
      _connectivityController.add(_isOnline);
      
      if (_isOnline) {
        // Start ping monitoring when online
        startPingMonitoring();
      } else {
        // Stop ping monitoring when offline
        stopPingMonitoring();
        _currentPing = PingResult.offline();
        _pingStreamController.add(_currentPing!);
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      _isOnline = result.isNotEmpty && result.first != ConnectivityResult.none;
      _connectivityController.add(_isOnline);
      
      if (_isOnline) {
        startPingMonitoring();
      }
    });
  }

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get connectivityStream => _connectivityController.stream;

  @override
  PingResult? get currentPing => _currentPing;

  @override
  Stream<PingResult> get pingStream => _pingStreamController.stream;

  @override
  ConnectionQuality get connectionQuality => 
      _currentPing?.quality ?? ConnectionQuality.offline;

  @override
  SyncStrategy get currentSyncStrategy =>
      _currentPing?.syncStrategy ?? SyncStrategy.queue;

  @override
  void startPingMonitoring() {
    _pingSubscription?.cancel();
    _pingSubscription = _pingService.pingStream.listen((ping) {
      _currentPing = ping;
      _pingStreamController.add(ping);
      
      // Trigger sync based on new ping result
      _handlePingBasedSync(ping);
    });
    _pingService.startMonitoring();
  }

  @override
  void stopPingMonitoring() {
    _pingService.stopMonitoring();
    _pingSubscription?.cancel();
    _pingSubscription = null;
  }

  @override
  Future<PingResult> measurePing() async {
    final result = await _pingService.ping();
    _currentPing = result;
    _pingStreamController.add(result);
    return result;
  }

  /// Simple sync based on flowchart: Check ping, if good then sync
  void _handlePingBasedSync(PingResult ping) {
    // Simple logic: If ping >= good, sync pending items
    if (_isPingGood(ping)) {
      _processOfflineQueue();
    }
    // If ping not good, do nothing (items stay in queue)
  }

  /// Check if ping is good enough for sync (>= good quality)
  bool _isPingGood(PingResult ping) {
    if (!ping.isReachable) return false;
    // Ping is good if quality is excellent, good, or fair
    return ping.quality == ConnectionQuality.excellent ||
           ping.quality == ConnectionQuality.good ||
           ping.quality == ConnectionQuality.fair;
  }

  @override
  Future<void> syncOfflineData() async {
    await _processOfflineQueue();
  }

  @override
  Future<void> syncWithStrategy({bool force = false}) async {
    if (force) {
      await _processOfflineQueue();
      return;
    }

    // Simple logic: Only sync if ping is good
    if (_currentPing != null && _isPingGood(_currentPing!)) {
      await _processOfflineQueue();
    }
  }

  @override
  Future<int> get pendingQueueCount => offlineQueue.queueSize;

  /// Simple sync process following flowchart:
  /// 1. Get pending items from local DB
  /// 2. Sync each item to server
  /// 3. If success: Remove from Hive
  /// 4. If fail: Item stays in queue (will retry on next sync)
  Future<void> _processOfflineQueue() async {
    // Get pending events from local DB
    final items = await offlineQueue.getPendingItems();
    
    // Process each item
    for (final item in items) {
      try {
        // Sync to server
        await _syncItem(item);
        
        // Success: Remove item from Hive
        await offlineQueue.remove(item.queueKey);
      } catch (e) {
        // Fail: Item stays in queue (will retry on next sync cycle)
        // No retry count limit - will keep retrying until success
      }
    }
  }

  Future<void> _syncItem(QueueItemData item) async {
    switch (item.type) {
      case QueueItemType.event:
        await _firestore
            .collection(AppConstants.collectionHaulerEvents)
            .doc(item.data['dedupKey'] as String?)
            .set(item.data, SetOptions(merge: true));
        break;
        
      case QueueItemType.telemetry:
        await _firestore
            .collection(AppConstants.collectionTelemetry)
            .doc(item.id)
            .set(item.data);
        break;
        
      case QueueItemType.intent:
        await _firestore
            .collection('intents')
            .doc(item.id)
            .set(item.data);
        break;
        
      case QueueItemType.haulerUpdate:
        final haulerId = item.data['haulerId'] as String;
        final update = item.data['update'] as Map<String, dynamic>;
        await _firestore
            .collection(AppConstants.collectionHaulers)
            .doc(haulerId)
            .update(update);
        break;
    }
  }

  void dispose() {
    stopPingMonitoring();
    _pingService.dispose();
    _connectivityController.close();
    _pingStreamController.close();
  }
}

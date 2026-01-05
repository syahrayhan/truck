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
  Timer? _batchSyncTimer;
  
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

  void _handlePingBasedSync(PingResult ping) {
    final strategy = ping.syncStrategy;
    
    switch (strategy) {
      case SyncStrategy.immediate:
        // Cancel batch timer and sync immediately
        _batchSyncTimer?.cancel();
        _processOfflineQueue();
        break;
        
      case SyncStrategy.batched:
      case SyncStrategy.delayed:
        // Setup batch timer if not already running
        _setupBatchTimer(Duration(milliseconds: strategy.delayMs));
        break;
        
      case SyncStrategy.criticalOnly:
        // Only sync critical items
        _processCriticalItemsOnly();
        break;
        
      case SyncStrategy.queue:
        // Don't sync, just queue
        _batchSyncTimer?.cancel();
        break;
    }
  }

  void _setupBatchTimer(Duration delay) {
    if (_batchSyncTimer?.isActive ?? false) return;
    
    _batchSyncTimer = Timer(delay, () {
      _processOfflineQueue();
    });
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

    final strategy = currentSyncStrategy;
    
    switch (strategy) {
      case SyncStrategy.immediate:
      case SyncStrategy.batched:
      case SyncStrategy.delayed:
        await _processOfflineQueue();
        break;
        
      case SyncStrategy.criticalOnly:
        await _processCriticalItemsOnly();
        break;
        
      case SyncStrategy.queue:
        // Don't sync, connection too poor
        break;
    }
  }

  @override
  Future<int> get pendingQueueCount => offlineQueue.queueSize;

  Future<void> _processCriticalItemsOnly() async {
    final items = await offlineQueue.getPendingItems();
    
    // Only process status change events (critical)
    final criticalItems = items.where((item) => 
        item.type == QueueItemType.event || 
        item.type == QueueItemType.haulerUpdate
    ).toList();
    
    for (final item in criticalItems) {
      if (!item.shouldRetry) {
        await offlineQueue.remove(item.queueKey);
        continue;
      }

      try {
        await _syncItem(item);
        await offlineQueue.remove(item.queueKey);
      } catch (e) {
        await offlineQueue.incrementRetry(item.queueKey);
      }
    }
  }

  Future<void> _processOfflineQueue() async {
    final items = await offlineQueue.getPendingItems();
    
    for (final item in items) {
      if (!item.shouldRetry) {
        await offlineQueue.remove(item.queueKey);
        continue;
      }

      try {
        await _syncItem(item);
        await offlineQueue.remove(item.queueKey);
      } catch (e) {
        await offlineQueue.incrementRetry(item.queueKey);
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
    _batchSyncTimer?.cancel();
    stopPingMonitoring();
    _pingService.dispose();
    _connectivityController.close();
    _pingStreamController.close();
  }
}

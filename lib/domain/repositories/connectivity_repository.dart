import '../entities/ping_result.dart';

/// Abstract repository for Connectivity operations
abstract class ConnectivityRepository {
  /// Check if online
  bool get isOnline;

  /// Stream connectivity changes
  Stream<bool> get connectivityStream;

  /// Current ping result
  PingResult? get currentPing;

  /// Stream of ping results
  Stream<PingResult> get pingStream;

  /// Current connection quality
  ConnectionQuality get connectionQuality;

  /// Current sync strategy based on connection quality
  SyncStrategy get currentSyncStrategy;

  /// Sync offline data
  Future<void> syncOfflineData();

  /// Sync with strategy (based on ping quality)
  Future<void> syncWithStrategy({bool force = false});

  /// Get pending queue count
  Future<int> get pendingQueueCount;

  /// Start ping monitoring
  void startPingMonitoring();

  /// Stop ping monitoring
  void stopPingMonitoring();

  /// Perform single ping measurement
  Future<PingResult> measurePing();
}



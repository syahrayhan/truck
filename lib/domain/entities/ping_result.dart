import 'package:equatable/equatable.dart';

/// Connection quality based on ping and TTL
enum ConnectionQuality {
  excellent,  // ping < 50ms
  good,       // ping 50-100ms
  fair,       // ping 100-200ms
  poor,       // ping 200-500ms
  critical,   // ping > 500ms or timeout
  offline,    // no connection
}

extension ConnectionQualityExt on ConnectionQuality {
  String get displayName {
    switch (this) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.critical:
        return 'Critical';
      case ConnectionQuality.offline:
        return 'Offline';
    }
  }

  /// Sync strategy based on connection quality
  SyncStrategy get syncStrategy {
    switch (this) {
      case ConnectionQuality.excellent:
      case ConnectionQuality.good:
        return SyncStrategy.immediate;
      case ConnectionQuality.fair:
        return SyncStrategy.batched;
      case ConnectionQuality.poor:
        return SyncStrategy.delayed;
      case ConnectionQuality.critical:
        return SyncStrategy.criticalOnly;
      case ConnectionQuality.offline:
        return SyncStrategy.queue;
    }
  }
}

/// Sync strategy enum
enum SyncStrategy {
  immediate,    // Sync immediately, no batching
  batched,      // Batch sync every 5 seconds
  delayed,      // Batch sync every 15 seconds
  criticalOnly, // Only sync critical events (status changes)
  queue,        // Queue everything for later
}

extension SyncStrategyExt on SyncStrategy {
  String get description {
    switch (this) {
      case SyncStrategy.immediate:
        return 'Syncing immediately';
      case SyncStrategy.batched:
        return 'Batching every 5s';
      case SyncStrategy.delayed:
        return 'Batching every 15s';
      case SyncStrategy.criticalOnly:
        return 'Critical events only';
      case SyncStrategy.queue:
        return 'Queued for later';
    }
  }

  /// Delay in milliseconds before syncing
  int get delayMs {
    switch (this) {
      case SyncStrategy.immediate:
        return 0;
      case SyncStrategy.batched:
        return 5000;
      case SyncStrategy.delayed:
        return 15000;
      case SyncStrategy.criticalOnly:
        return 0;
      case SyncStrategy.queue:
        return -1; // Indicates queue mode
    }
  }
}

/// Ping result entity
class PingResult extends Equatable {
  final int pingMs;
  final int? ttl;
  final DateTime timestamp;
  final bool isReachable;
  final String? error;

  const PingResult({
    required this.pingMs,
    this.ttl,
    required this.timestamp,
    required this.isReachable,
    this.error,
  });

  factory PingResult.offline() {
    return PingResult(
      pingMs: -1,
      ttl: null,
      timestamp: DateTime.now(),
      isReachable: false,
      error: 'Network unreachable',
    );
  }

  factory PingResult.timeout() {
    return PingResult(
      pingMs: 9999,
      ttl: null,
      timestamp: DateTime.now(),
      isReachable: false,
      error: 'Request timeout',
    );
  }

  /// Get connection quality based on ping
  ConnectionQuality get quality {
    if (!isReachable) return ConnectionQuality.offline;
    
    if (pingMs < 50) return ConnectionQuality.excellent;
    if (pingMs < 100) return ConnectionQuality.good;
    if (pingMs < 200) return ConnectionQuality.fair;
    if (pingMs < 500) return ConnectionQuality.poor;
    return ConnectionQuality.critical;
  }

  /// Get sync strategy based on connection quality
  SyncStrategy get syncStrategy => quality.syncStrategy;

  /// Check if connection is suitable for sync
  bool get canSync => isReachable && quality != ConnectionQuality.critical;

  /// Check if should batch sync
  bool get shouldBatch => 
      quality == ConnectionQuality.fair || 
      quality == ConnectionQuality.poor;

  @override
  List<Object?> get props => [pingMs, ttl, timestamp, isReachable, error];

  @override
  String toString() {
    if (!isReachable) return 'Offline';
    return '${pingMs}ms${ttl != null ? ' (TTL: $ttl)' : ''}';
  }
}


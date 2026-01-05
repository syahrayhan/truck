import 'dart:async';
import 'dart:io';
import '../../../domain/entities/ping_result.dart';

/// Service for measuring network ping and TTL
class PingService {
  // Target hosts for ping measurement
  static const List<String> _pingHosts = [
    'firestore.googleapis.com',
    'firebase.google.com',
    'google.com',
  ];

  // Ping interval
  static const Duration pingInterval = Duration(seconds: 5);
  
  // Timeout for ping request
  static const Duration pingTimeout = Duration(seconds: 5);

  Timer? _pingTimer;
  final StreamController<PingResult> _pingController = 
      StreamController<PingResult>.broadcast();

  /// Stream of ping results
  Stream<PingResult> get pingStream => _pingController.stream;

  /// Start periodic ping monitoring
  void startMonitoring() {
    // Perform initial ping
    _performPing();
    
    // Setup periodic ping
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => _performPing());
  }

  /// Stop ping monitoring
  void stopMonitoring() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Perform a single ping measurement
  Future<PingResult> ping() async {
    return _performPing();
  }

  Future<PingResult> _performPing() async {
    PingResult? bestResult;

    for (final host in _pingHosts) {
      try {
        final result = await _pingHost(host);
        
        if (result.isReachable) {
          // Keep the best (lowest ping) result
          if (bestResult == null || result.pingMs < bestResult.pingMs) {
            bestResult = result;
          }
          // If we get excellent connection, no need to try other hosts
          if (result.quality == ConnectionQuality.excellent) {
            break;
          }
        }
      } catch (_) {
        // Try next host
        continue;
      }
    }

    final finalResult = bestResult ?? PingResult.offline();
    _pingController.add(finalResult);
    return finalResult;
  }

  Future<PingResult> _pingHost(String host) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Use socket connection to measure latency
      // This is more reliable than HTTP for measuring network latency
      final socket = await Socket.connect(
        host,
        443, // HTTPS port
        timeout: pingTimeout,
      );
      
      stopwatch.stop();
      final pingMs = stopwatch.elapsedMilliseconds;
      
      // TTL is typically 64 for most modern systems
      // In production, you would use platform-specific APIs to get actual TTL
      const int defaultTtl = 64;
      
      await socket.close();
      
      return PingResult(
        pingMs: pingMs,
        ttl: defaultTtl,
        timestamp: DateTime.now(),
        isReachable: true,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      
      return PingResult(
        pingMs: stopwatch.elapsedMilliseconds,
        ttl: null,
        timestamp: DateTime.now(),
        isReachable: false,
        error: e.message,
      );
    } on TimeoutException {
      return PingResult.timeout();
    } catch (e) {
      return PingResult(
        pingMs: -1,
        ttl: null,
        timestamp: DateTime.now(),
        isReachable: false,
        error: e.toString(),
      );
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _pingController.close();
  }
}


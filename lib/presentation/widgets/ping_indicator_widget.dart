import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ping_result.dart';
import '../bloc/bloc.dart';

/// Widget to display ping, TTL, and connection quality
class PingIndicatorWidget extends StatelessWidget {
  final bool compact;

  const PingIndicatorWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HaulerBloc, HaulerState>(
      buildWhen: (previous, current) => 
          previous.pingResult != current.pingResult,
      builder: (context, state) {
        final ping = state.pingResult;
        final quality = state.connectionQuality;

        if (compact) {
          return _CompactPingIndicator(
            ping: ping,
            quality: quality,
            onTap: () => context.read<HaulerBloc>().add(const RefreshPing()),
          );
        }

        return _ExpandedPingIndicator(
          ping: ping,
          quality: quality,
          syncStrategy: state.syncStrategy,
          onRefresh: () => context.read<HaulerBloc>().add(const RefreshPing()),
        );
      },
    );
  }
}

/// Compact ping indicator for top bar
class _CompactPingIndicator extends StatelessWidget {
  final PingResult? ping;
  final ConnectionQuality quality;
  final VoidCallback onTap;

  const _CompactPingIndicator({
    required this.ping,
    required this.quality,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getQualityColor(quality).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getQualityColor(quality).withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SignalBars(quality: quality),
            const SizedBox(width: 6),
            Text(
              ping?.isReachable == true 
                  ? '${ping!.pingMs}ms' 
                  : 'Offline',
              style: TextStyle(
                color: _getQualityColor(quality),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanded ping indicator with details
class _ExpandedPingIndicator extends StatelessWidget {
  final PingResult? ping;
  final ConnectionQuality quality;
  final SyncStrategy syncStrategy;
  final VoidCallback onRefresh;

  const _ExpandedPingIndicator({
    required this.ping,
    required this.quality,
    required this.syncStrategy,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getQualityColor(quality).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              _SignalBars(quality: quality, size: 16),
              const SizedBox(width: 8),
              Text(
                'Network Status',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRefresh,
                child: Icon(
                  Icons.refresh,
                  color: Colors.white.withOpacity(0.5),
                  size: 18,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Ping value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ping?.isReachable == true ? '${ping!.pingMs}' : '--',
                style: TextStyle(
                  color: _getQualityColor(quality),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'ms',
                  style: TextStyle(
                    color: _getQualityColor(quality).withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // TTL badge
              if (ping?.ttl != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TTL: ${ping!.ttl}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Quality label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getQualityColor(quality).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              quality.displayName.toUpperCase(),
              style: TextStyle(
                color: _getQualityColor(quality),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Sync strategy
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getSyncIcon(syncStrategy),
                  color: _getSyncColor(syncStrategy),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Mode',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        syncStrategy.description,
                        style: TextStyle(
                          color: _getSyncColor(syncStrategy),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSyncIcon(SyncStrategy strategy) {
    switch (strategy) {
      case SyncStrategy.immediate:
        return Icons.flash_on;
      case SyncStrategy.batched:
        return Icons.timer;
      case SyncStrategy.delayed:
        return Icons.hourglass_empty;
      case SyncStrategy.criticalOnly:
        return Icons.priority_high;
      case SyncStrategy.queue:
        return Icons.cloud_off;
    }
  }

  Color _getSyncColor(SyncStrategy strategy) {
    switch (strategy) {
      case SyncStrategy.immediate:
        return const Color(0xFF4CAF50);
      case SyncStrategy.batched:
        return const Color(0xFF8BC34A);
      case SyncStrategy.delayed:
        return const Color(0xFFFFB74D);
      case SyncStrategy.criticalOnly:
        return const Color(0xFFFF9800);
      case SyncStrategy.queue:
        return const Color(0xFFF44336);
    }
  }
}

/// Signal bars indicator
class _SignalBars extends StatelessWidget {
  final ConnectionQuality quality;
  final double size;

  const _SignalBars({
    required this.quality,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bars = _getBarCount(quality);
    final color = _getQualityColor(quality);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isActive = index < bars;
        final barHeight = (index + 1) * (size / 4);
        
        return Container(
          width: size / 5,
          height: barHeight,
          margin: EdgeInsets.only(right: index < 3 ? 2 : 0),
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  int _getBarCount(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 4;
      case ConnectionQuality.good:
        return 3;
      case ConnectionQuality.fair:
        return 2;
      case ConnectionQuality.poor:
        return 1;
      case ConnectionQuality.critical:
      case ConnectionQuality.offline:
        return 0;
    }
  }
}

Color _getQualityColor(ConnectionQuality quality) {
  switch (quality) {
    case ConnectionQuality.excellent:
      return const Color(0xFF4CAF50);
    case ConnectionQuality.good:
      return const Color(0xFF8BC34A);
    case ConnectionQuality.fair:
      return const Color(0xFFFFB74D);
    case ConnectionQuality.poor:
      return const Color(0xFFFF9800);
    case ConnectionQuality.critical:
      return const Color(0xFFF44336);
    case ConnectionQuality.offline:
      return const Color(0xFF9E9E9E);
  }
}


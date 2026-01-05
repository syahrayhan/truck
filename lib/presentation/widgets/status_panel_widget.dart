import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../domain/entities/ping_result.dart';
import '../bloc/bloc.dart';

/// Status panel showing current state and controls
class StatusPanelWidget extends StatelessWidget {
  const StatusPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HaulerBloc, HaulerState>(
      builder: (context, haulerState) {
        return BlocBuilder<SimulationBloc, SimulationState>(
          builder: (context, simState) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Server correction warning
                  if (haulerState.serverCorrected)
                    _ServerCorrectionBanner(
                      onDismiss: () {
                        context.read<HaulerBloc>().add(const ClearServerCorrection());
                      },
                    ),
                  
                  // Status header
                  _StatusHeader(state: haulerState),
                  
                  const SizedBox(height: 16),
                  
                  // Cycle progress
                  _CycleProgress(status: haulerState.currentStatus),
                  
                  const SizedBox(height: 20),
                  
                  // Control buttons
                  _ControlButtons(
                    haulerState: haulerState,
                    isSimulating: simState.isSimulating,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sync status
                  _SyncStatus(state: haulerState),
                  
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Server correction warning banner
class _ServerCorrectionBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const _ServerCorrectionBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sync_problem,
            color: Color(0xFFFFB74D),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Status corrected by server',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close,
              color: Color(0xFFFFB74D),
              size: 18,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Status header showing current status
class _StatusHeader extends StatelessWidget {
  final HaulerState state;

  const _StatusHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final status = state.currentStatus;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getStatusColor(status),
                width: 2,
              ),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(status),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Body up indicator
          _BodyUpIndicator(isUp: state.bodyUp),
        ],
      ),
    );
  }

  Color _getStatusColor(HaulerStatus status) {
    switch (status) {
      case HaulerStatus.standby:
        return Colors.grey;
      case HaulerStatus.queuing:
        return const Color(0xFF2196F3);
      case HaulerStatus.spotting:
        return const Color(0xFF9C27B0);
      case HaulerStatus.loading:
        return const Color(0xFF4CAF50);
      case HaulerStatus.haulingLoad:
        return const Color(0xFFFF9800);
      case HaulerStatus.dumping:
        return const Color(0xFFF44336);
      case HaulerStatus.haulingEmpty:
        return const Color(0xFF00BCD4);
    }
  }

  IconData _getStatusIcon(HaulerStatus status) {
    switch (status) {
      case HaulerStatus.standby:
        return Icons.pause_circle_outline;
      case HaulerStatus.queuing:
        return Icons.queue;
      case HaulerStatus.spotting:
        return Icons.my_location;
      case HaulerStatus.loading:
        return Icons.download;
      case HaulerStatus.haulingLoad:
        return Icons.local_shipping;
      case HaulerStatus.dumping:
        return Icons.upload;
      case HaulerStatus.haulingEmpty:
        return Icons.replay;
    }
  }

  String _getStatusDescription(HaulerStatus status) {
    switch (status) {
      case HaulerStatus.standby:
        return 'Truck idle, waiting for assignment';
      case HaulerStatus.queuing:
        return 'Waiting in queue at loader';
      case HaulerStatus.spotting:
        return 'Positioning at loading point';
      case HaulerStatus.loading:
        return 'Material being loaded';
      case HaulerStatus.haulingLoad:
        return 'Transporting load to dump point';
      case HaulerStatus.dumping:
        return 'Unloading material';
      case HaulerStatus.haulingEmpty:
        return 'Returning to loader';
    }
  }
}

/// Body up/down indicator
class _BodyUpIndicator extends StatelessWidget {
  final bool isUp;

  const _BodyUpIndicator({required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUp 
            ? const Color(0xFFF44336).withOpacity(0.2)
            : const Color(0xFF4CAF50).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUp ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            color: isUp ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isUp ? 'UP' : 'DOWN',
            style: TextStyle(
              color: isUp ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cycle progress indicator
class _CycleProgress extends StatelessWidget {
  final HaulerStatus status;

  const _CycleProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      HaulerStatus.queuing,
      HaulerStatus.spotting,
      HaulerStatus.loading,
      HaulerStatus.haulingLoad,
      HaulerStatus.dumping,
      HaulerStatus.haulingEmpty,
    ];
    
    final currentIndex = steps.indexOf(status);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector
            final stepIndex = index ~/ 2;
            final isCompleted = currentIndex > stepIndex;
            return Expanded(
              child: Container(
                height: 3,
                color: isCompleted 
                    ? const Color(0xFF4CAF50) 
                    : Colors.white24,
              ),
            );
          } else {
            // Step dot
            final stepIndex = index ~/ 2;
            final step = steps[stepIndex];
            final isCurrent = status == step;
            final isCompleted = currentIndex > stepIndex;
            
            return _StepDot(
              label: _getShortLabel(step),
              isCurrent: isCurrent,
              isCompleted: isCompleted,
            );
          }
        }),
      ),
    );
  }

  String _getShortLabel(HaulerStatus status) {
    switch (status) {
      case HaulerStatus.queuing:
        return 'Q';
      case HaulerStatus.spotting:
        return 'S';
      case HaulerStatus.loading:
        return 'L';
      case HaulerStatus.haulingLoad:
        return 'H';
      case HaulerStatus.dumping:
        return 'D';
      case HaulerStatus.haulingEmpty:
        return 'R';
      default:
        return '?';
    }
  }
}

/// Step dot in progress indicator
class _StepDot extends StatelessWidget {
  final String label;
  final bool isCurrent;
  final bool isCompleted;

  const _StepDot({
    required this.label,
    required this.isCurrent,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCurrent 
            ? const Color(0xFF4CAF50)
            : isCompleted 
                ? const Color(0xFF4CAF50).withOpacity(0.3)
                : Colors.white12,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent || isCompleted 
              ? const Color(0xFF4CAF50)
              : Colors.white24,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted && !isCurrent
            ? const Icon(
                Icons.check,
                color: Color(0xFF4CAF50),
                size: 14,
              )
            : Text(
                label,
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Control buttons
class _ControlButtons extends StatelessWidget {
  final HaulerState haulerState;
  final bool isSimulating;

  const _ControlButtons({
    required this.haulerState,
    required this.isSimulating,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Start/Stop simulation
          Expanded(
            child: _ControlButton(
              icon: isSimulating ? Icons.stop : Icons.play_arrow,
              label: isSimulating ? 'Stop' : 'Start Simulation',
              color: isSimulating 
                  ? const Color(0xFFF44336)
                  : const Color(0xFF4CAF50),
              onPressed: () {
                final simBloc = context.read<SimulationBloc>();
                if (isSimulating) {
                  simBloc.add(const StopSimulation());
                } else {
                  simBloc.add(const StartSimulation());
                }
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Body up/down toggle
          Expanded(
            child: _ControlButton(
              icon: haulerState.bodyUp ? Icons.arrow_downward : Icons.arrow_upward,
              label: haulerState.bodyUp ? 'Lower Body' : 'Raise Body',
              color: const Color(0xFFFF9800),
              onPressed: () {
                context.read<HaulerBloc>().add(const ToggleBodyUp());
              },
              enabled: haulerState.currentStatus == HaulerStatus.haulingLoad ||
                       haulerState.currentStatus == HaulerStatus.dumping,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual control button
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color.withOpacity(0.2) : Colors.white12,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? color : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? color : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sync status indicator with ping info
class _SyncStatus extends StatelessWidget {
  final HaulerState state;

  const _SyncStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final ping = state.pingResult;
    final quality = state.connectionQuality;
    final strategy = state.syncStrategy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Signal strength indicator
            _SignalStrengthIcon(quality: quality),
            const SizedBox(width: 12),
            
            // Ping info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ping?.isReachable == true 
                            ? '${ping!.pingMs}ms' 
                            : 'Offline',
                        style: TextStyle(
                          color: _getQualityColor(quality),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ping?.ttl != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TTL ${ping!.ttl}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${quality.displayName} • ${strategy.description}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            // Refresh button
            GestureDetector(
              onTap: () => context.read<HaulerBloc>().add(const RefreshPing()),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white54,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}

/// Signal strength icon widget
class _SignalStrengthIcon extends StatelessWidget {
  final ConnectionQuality quality;

  const _SignalStrengthIcon({required this.quality});

  @override
  Widget build(BuildContext context) {
    final bars = _getBarCount(quality);
    final color = _getColor(quality);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (index) {
            final isActive = index < bars;
            final barHeight = 4.0 + (index * 2);
            
            return Container(
              width: 3,
              height: barHeight,
              margin: EdgeInsets.only(right: index < 3 ? 1 : 0),
              decoration: BoxDecoration(
                color: isActive ? color : color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
      ),
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

  Color _getColor(ConnectionQuality quality) {
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
}



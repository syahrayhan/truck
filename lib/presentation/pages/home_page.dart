import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

/// Main home page with map and controls
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showEventLog = false;

  @override
  void initState() {
    super.initState();
    // Initialize hauler after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final haulerBloc = context.read<HaulerBloc>();
      haulerBloc.add(InitializeHauler(haulerId: haulerBloc.state.haulerId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: BlocBuilder<HaulerBloc, HaulerState>(
        builder: (context, state) {
          if (state.isLoading && !state.isInitialized) {
            return const LoadingScreen();
          }

          if (state.errorMessage != null) {
            return ErrorScreen(message: state.errorMessage!);
          }

          return Stack(
            children: [
              // Map
              const Positioned.fill(
                child: HaulerMapWidget(),
              ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopBar(
                  showEventLog: _showEventLog,
                  onToggleEventLog: () {
                    setState(() => _showEventLog = !_showEventLog);
                  },
                ),
              ),

              // Event log (when visible)
              if (_showEventLog)
                const Positioned(
                  top: 120,
                  left: 16,
                  right: 16,
                  bottom: 280,
                  child: EventLogWidget(),
                ),

              // Bottom status panel
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: StatusPanelWidget(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Top bar with hauler info and controls
class TopBar extends StatelessWidget {
  final bool showEventLog;
  final VoidCallback onToggleEventLog;

  const TopBar({
    super.key,
    required this.showEventLog,
    required this.onToggleEventLog,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    return BlocBuilder<HaulerBloc, HaulerState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.only(
            top: mediaQuery.padding.top + 8,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF1A1A2E).withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Hauler ID badge
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0F3460),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Color(0xFFE94560),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'HAULER ${state.haulerId.substring(0, 4).toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Ping indicator
              const PingIndicatorWidget(compact: true),
              
              const SizedBox(width: 8),
              
              // Cycle indicator
              if (state.currentCycle != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'CYCLE ACTIVE',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Event log toggle
              IconButton(
                onPressed: onToggleEventLog,
                icon: Icon(
                  showEventLog ? Icons.terminal : Icons.terminal,
                  color: showEventLog ? const Color(0xFF58A6FF) : Colors.white54,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: showEventLog 
                      ? const Color(0xFF58A6FF).withOpacity(0.2)
                      : Colors.white12,
                ),
              ),
              
              // Settings
              IconButton(
                onPressed: () => _showSettingsSheet(context),
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white54,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SettingsSheet(),
    );
  }
}

/// Settings bottom sheet
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HaulerBloc, HaulerState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Manual status controls (for testing)
              const Text(
                'Manual Status Control (Debug)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HaulerStatus.values.map((status) {
                  final isCurrent = state.currentStatus == status;
                  return FilterChip(
                    label: Text(
                      status.code,
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    selected: isCurrent,
                    onSelected: isCurrent ? null : (_) {
                      context.read<HaulerBloc>().add(
                        ManualTransition(targetStatus: status),
                      );
                      Navigator.pop(context);
                    },
                    backgroundColor: const Color(0xFF16213E),
                    selectedColor: const Color(0xFF4CAF50),
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Sync button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<HaulerBloc>().add(const SyncOfflineData());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sync completed'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Force Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3460),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }
}

/// Loading screen
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F23),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated truck icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(50 * (value - 0.5), 0),
                  child: child,
                );
              },
              child: const Icon(
                Icons.local_shipping,
                color: Color(0xFFE94560),
                size: 64,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Hauler Truck',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Mining Operations System',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            
            const SizedBox(height: 40),
            
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFFE94560)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Initializing...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen
class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F23),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFF44336),
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Initialization Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final bloc = context.read<HaulerBloc>();
                bloc.add(InitializeHauler(haulerId: bloc.state.haulerId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}



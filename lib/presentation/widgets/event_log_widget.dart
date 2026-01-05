import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';

/// Event log widget for debugging and monitoring
class EventLogWidget extends StatelessWidget {
  const EventLogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HaulerBloc, HaulerState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF30363D),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF161B22),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.terminal,
                      color: Color(0xFF8B949E),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Event Log',
                      style: TextStyle(
                        color: Color(0xFFC9D1D9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        context.read<HaulerBloc>().add(const ClearEventLog());
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Color(0xFF58A6FF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Log entries
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.eventLog.length,
                  itemBuilder: (context, index) {
                    final log = state.eventLog[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: _getLogColor(log),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('Error') || log.contains('failed')) {
      return const Color(0xFFF85149);
    }
    if (log.contains('corrected') || log.contains('Warning')) {
      return const Color(0xFFD29922);
    }
    if (log.contains('started') || log.contains('completed')) {
      return const Color(0xFF3FB950);
    }
    if (log.contains('Status:')) {
      return const Color(0xFF58A6FF);
    }
    return const Color(0xFF8B949E);
  }
}



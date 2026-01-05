part of 'simulation_bloc.dart';

/// Base event for SimulationBloc
abstract class SimulationEvent extends Equatable {
  const SimulationEvent();

  @override
  List<Object?> get props => [];
}

/// Start simulation
class StartSimulation extends SimulationEvent {
  const StartSimulation();
}

/// Stop simulation
class StopSimulation extends SimulationEvent {
  const StopSimulation();
}

/// Simulation tick (internal)
class SimulationTick extends SimulationEvent {
  const SimulationTick();
}



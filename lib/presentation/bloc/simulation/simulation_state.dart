part of 'simulation_bloc.dart';

/// Simulation phases
enum SimulationPhase {
  idle,
  movingToLoader,
  atLoader,
  movingToDump,
  atDump,
  returningToLoader,
}

/// State for SimulationBloc
class SimulationState extends Equatable {
  final bool isSimulating;
  final SimulationPhase phase;
  final int phaseDelayCounter;
  final GeoLocation? targetLocation;

  const SimulationState({
    this.isSimulating = false,
    this.phase = SimulationPhase.idle,
    this.phaseDelayCounter = 0,
    this.targetLocation,
  });

  SimulationState copyWith({
    bool? isSimulating,
    SimulationPhase? phase,
    int? phaseDelayCounter,
    GeoLocation? targetLocation,
  }) {
    return SimulationState(
      isSimulating: isSimulating ?? this.isSimulating,
      phase: phase ?? this.phase,
      phaseDelayCounter: phaseDelayCounter ?? this.phaseDelayCounter,
      targetLocation: targetLocation ?? this.targetLocation,
    );
  }

  @override
  List<Object?> get props => [isSimulating, phase, phaseDelayCounter, targetLocation];
}



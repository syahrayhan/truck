import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/entities.dart';
import '../hauler/hauler_bloc.dart';

part 'simulation_event.dart';
part 'simulation_state.dart';

/// BLoC for managing simulation state
class SimulationBloc extends Bloc<SimulationEvent, SimulationState> {
  final HaulerBloc haulerBloc;
  
  Timer? _mainTimer;
  bool _isProcessing = false;

  SimulationBloc({required this.haulerBloc}) : super(const SimulationState()) {
    on<StartSimulation>(_onStartSimulation);
    on<StopSimulation>(_onStopSimulation);
    on<SimulationTick>(_onSimulationTick);
  }

  Future<void> _onStartSimulation(
    StartSimulation event,
    Emitter<SimulationState> emit,
  ) async {
    if (state.isSimulating) return;
    
    // Initialize hauler if needed
    if (!haulerBloc.state.isInitialized) {
      haulerBloc.add(InitializeHauler(haulerId: haulerBloc.state.haulerId));
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Check for loader
    if (haulerBloc.state.selectedLoader == null) {
      haulerBloc.add(const AddEventLog(message: 'Cannot simulate: no loader available'));
      return;
    }
    
    // Start cycle if in standby
    if (haulerBloc.state.currentStatus == HaulerStatus.standby) {
      haulerBloc.add(const StartCycleEvent());
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    emit(state.copyWith(
      isSimulating: true,
      phase: SimulationPhase.movingToLoader,
      phaseDelayCounter: 0,
    ));
    
    haulerBloc.add(const AddEventLog(message: 'Simulation started'));
    haulerBloc.add(AddEventLog(message: 'Target loader: ${haulerBloc.state.selectedLoader!.name}'));
    
    // Start timer
    _mainTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => add(const SimulationTick()),
    );
  }

  Future<void> _onStopSimulation(
    StopSimulation event,
    Emitter<SimulationState> emit,
  ) async {
    _mainTimer?.cancel();
    _mainTimer = null;
    
    emit(const SimulationState());
    haulerBloc.add(const AddEventLog(message: 'Simulation stopped'));
  }

  Future<void> _onSimulationTick(
    SimulationTick event,
    Emitter<SimulationState> emit,
  ) async {
    if (!state.isSimulating || _isProcessing) return;
    _isProcessing = true;
    
    try {
      final haulerState = haulerBloc.state;
      final status = haulerState.currentStatus;
      final loader = haulerState.selectedLoader;
      final dumpPoint = haulerState.dumpPoint;
      final location = haulerState.hauler?.location;
      
      if (loader == null || dumpPoint == null) {
        _isProcessing = false;
        return;
      }

      switch (state.phase) {
        case SimulationPhase.idle:
          break;
          
        case SimulationPhase.movingToLoader:
          if (location != null && _isNearLocation(location, loader.location, loader.radius)) {
            emit(state.copyWith(
              phase: SimulationPhase.atLoader,
              phaseDelayCounter: 0,
            ));
          } else {
            await _moveTowards(loader.location);
          }
          break;
          
        case SimulationPhase.atLoader:
          final newCounter = state.phaseDelayCounter + 1;
          emit(state.copyWith(phaseDelayCounter: newCounter));
          
          if (status == HaulerStatus.queuing && newCounter > 7) {
            haulerBloc.add(const ForceTransition(
              targetStatus: HaulerStatus.spotting,
              cause: TransitionCause.enteredLoaderRadius,
            ));
          } else if (status == HaulerStatus.spotting && newCounter > 10) {
            haulerBloc.add(const ForceTransition(
              targetStatus: HaulerStatus.loading,
              cause: TransitionCause.loaderConfirmed,
            ));
          } else if (status == HaulerStatus.loading && newCounter > 60) {
            haulerBloc.add(const CompleteLoading());
            emit(state.copyWith(
              phase: SimulationPhase.movingToDump,
              phaseDelayCounter: 0,
            ));
          } else if (status == HaulerStatus.haulingLoad) {
            emit(state.copyWith(
              phase: SimulationPhase.movingToDump,
              phaseDelayCounter: 0,
            ));
          }
          break;
          
        case SimulationPhase.movingToDump:
          if (location != null && _isNearLocation(location, dumpPoint.location, dumpPoint.radius)) {
            emit(state.copyWith(
              phase: SimulationPhase.atDump,
              phaseDelayCounter: 0,
            ));
          } else {
            await _moveTowards(dumpPoint.location);
          }
          break;
          
        case SimulationPhase.atDump:
          final newCounter = state.phaseDelayCounter + 1;
          emit(state.copyWith(phaseDelayCounter: newCounter));
          
          if (status == HaulerStatus.haulingLoad && newCounter > 7) {
            if (haulerState.hauler?.bodyUp != true) {
              haulerBloc.add(const SetBodyUp(isUp: true));
            }
          } else if (status == HaulerStatus.dumping && newCounter > 57) {
            if (haulerState.hauler?.bodyUp == true) {
              haulerBloc.add(const SetBodyUp(isUp: false));
            }
            emit(state.copyWith(
              phase: SimulationPhase.returningToLoader,
              phaseDelayCounter: 0,
            ));
          } else if (status == HaulerStatus.haulingEmpty) {
            emit(state.copyWith(
              phase: SimulationPhase.returningToLoader,
              phaseDelayCounter: 0,
            ));
          }
          break;
          
        case SimulationPhase.returningToLoader:
          if (location != null && _isNearLocation(location, loader.location, loader.radius)) {
            if (status == HaulerStatus.haulingEmpty) {
              haulerBloc.add(const ForceTransition(
                targetStatus: HaulerStatus.queuing,
                cause: TransitionCause.enteredLoaderRadius,
              ));
            }
            emit(state.copyWith(
              phase: SimulationPhase.atLoader,
              phaseDelayCounter: 0,
            ));
          } else {
            await _moveTowards(loader.location);
          }
          break;
      }
    } catch (e) {
      // Log error but continue simulation
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _moveTowards(GeoLocation target) async {
    final current = haulerBloc.state.hauler?.location;
    
    if (current == null) {
      // Set initial position near target
      final startPos = GeoLocation(
        lat: target.lat - 0.002,
        lng: target.lng - 0.002,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      haulerBloc.add(UpdateLocation(location: startPos));
      return;
    }
    
    final distance = current.distanceTo(target);
    
    if (distance < 10) {
      // Close enough, snap to target
      haulerBloc.add(UpdateLocation(location: target.copyWith(
        accuracy: 8.0 + math.Random().nextDouble() * 4,
        timestamp: DateTime.now(),
      )));
      return;
    }
    
    // Move towards target
    const speed = 25.0;
    final ratio = math.min(speed / distance, 1.0);
    
    final newLat = current.lat + (target.lat - current.lat) * ratio;
    final newLng = current.lng + (target.lng - current.lng) * ratio;
    
    final newLocation = GeoLocation(
      lat: newLat,
      lng: newLng,
      accuracy: 8.0 + math.Random().nextDouble() * 4,
      timestamp: DateTime.now(),
    );
    
    haulerBloc.add(UpdateLocation(location: newLocation));
  }

  bool _isNearLocation(GeoLocation current, GeoLocation target, double radius) {
    return current.distanceTo(target) <= radius;
  }

  @override
  Future<void> close() {
    _mainTimer?.cancel();
    return super.close();
  }
}



part of 'hauler_bloc.dart';

/// Base event for HaulerBloc
abstract class HaulerEvent extends Equatable {
  const HaulerEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the hauler
class InitializeHauler extends HaulerEvent {
  final String haulerId;

  const InitializeHauler({required this.haulerId});

  @override
  List<Object?> get props => [haulerId];
}

/// Select a loader
class SelectLoader extends HaulerEvent {
  final LoaderEntity loader;

  const SelectLoader({required this.loader});

  @override
  List<Object?> get props => [loader];
}

/// Set dump point
class SetDumpPoint extends HaulerEvent {
  final GeoLocation location;

  const SetDumpPoint({required this.location});

  @override
  List<Object?> get props => [location];
}

/// Start a new cycle
class StartCycleEvent extends HaulerEvent {
  const StartCycleEvent();
}

/// Complete current cycle
class CompleteCycleEvent extends HaulerEvent {
  const CompleteCycleEvent();
}

/// Update hauler location
class UpdateLocation extends HaulerEvent {
  final GeoLocation location;

  const UpdateLocation({required this.location});

  @override
  List<Object?> get props => [location];
}

/// Toggle body up/down
class ToggleBodyUp extends HaulerEvent {
  const ToggleBodyUp();
}

/// Set body state
class SetBodyUp extends HaulerEvent {
  final bool isUp;

  const SetBodyUp({required this.isUp});

  @override
  List<Object?> get props => [isUp];
}

/// Request manual transition
class ManualTransition extends HaulerEvent {
  final HaulerStatus targetStatus;

  const ManualTransition({required this.targetStatus});

  @override
  List<Object?> get props => [targetStatus];
}

/// Process auto transitions
class ProcessAutoTransitions extends HaulerEvent {
  const ProcessAutoTransitions();
}

/// Complete loading phase
class CompleteLoading extends HaulerEvent {
  const CompleteLoading();
}

/// Force transition (for simulation)
class ForceTransition extends HaulerEvent {
  final HaulerStatus targetStatus;
  final TransitionCause cause;

  const ForceTransition({
    required this.targetStatus,
    required this.cause,
  });

  @override
  List<Object?> get props => [targetStatus, cause];
}

/// Loaders updated from stream
class LoadersUpdated extends HaulerEvent {
  final List<LoaderEntity> loaders;

  const LoadersUpdated({required this.loaders});

  @override
  List<Object?> get props => [loaders];
}

/// Server correction detected
class ServerCorrectionDetected extends HaulerEvent {
  const ServerCorrectionDetected();
}

/// Hauler updated from server stream
class HaulerUpdatedFromServer extends HaulerEvent {
  final HaulerEntity serverHauler;

  const HaulerUpdatedFromServer({required this.serverHauler});

  @override
  List<Object?> get props => [serverHauler];
}

/// Clear server correction flag
class ClearServerCorrection extends HaulerEvent {
  const ClearServerCorrection();
}

/// Sync offline data
class SyncOfflineData extends HaulerEvent {
  const SyncOfflineData();
}

/// Add event log
class AddEventLog extends HaulerEvent {
  final String message;

  const AddEventLog({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Clear event log
class ClearEventLog extends HaulerEvent {
  const ClearEventLog();
}

/// Internal: Connectivity changed
class _ConnectivityChanged extends HaulerEvent {
  final bool isOnline;

  const _ConnectivityChanged({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}

/// Internal: Ping result updated
class _PingUpdated extends HaulerEvent {
  final PingResult pingResult;

  const _PingUpdated({required this.pingResult});

  @override
  List<Object?> get props => [pingResult];
}

/// Refresh ping manually
class RefreshPing extends HaulerEvent {
  const RefreshPing();
}



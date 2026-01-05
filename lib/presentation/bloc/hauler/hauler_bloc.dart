import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants.dart';
import '../../../core/state_machine.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';

part 'hauler_event.dart';
part 'hauler_state.dart';

/// BLoC for managing hauler state
class HaulerBloc extends Bloc<HaulerEvent, HaulerState> {
  final HaulerRepository haulerRepository;
  final CycleRepository cycleRepository;
  final LoaderRepository loaderRepository;
  final LocationRepository locationRepository;
  final ConnectivityRepository connectivityRepository;
  
  final _uuid = const Uuid();
  
  StreamSubscription<List<LoaderEntity>>? _loadersSubscription;
  StreamSubscription<HaulerEntity?>? _haulerSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<PingResult>? _pingSubscription;

  HaulerBloc({
    required String haulerId,
    required this.haulerRepository,
    required this.cycleRepository,
    required this.loaderRepository,
    required this.locationRepository,
    required this.connectivityRepository,
  }) : super(HaulerState.initial(haulerId)) {
    on<InitializeHauler>(_onInitialize);
    on<_ConnectivityChanged>(_onConnectivityChanged);
    on<_PingUpdated>(_onPingUpdated);
    on<RefreshPing>(_onRefreshPing);
    on<SelectLoader>(_onSelectLoader);
    on<SetDumpPoint>(_onSetDumpPoint);
    on<StartCycleEvent>(_onStartCycle);
    on<CompleteCycleEvent>(_onCompleteCycle);
    on<UpdateLocation>(_onUpdateLocation);
    on<ToggleBodyUp>(_onToggleBodyUp);
    on<SetBodyUp>(_onSetBodyUp);
    on<ManualTransition>(_onManualTransition);
    on<ProcessAutoTransitions>(_onProcessAutoTransitions);
    on<CompleteLoading>(_onCompleteLoading);
    on<ForceTransition>(_onForceTransition);
    on<LoadersUpdated>(_onLoadersUpdated);
    on<ServerCorrectionDetected>(_onServerCorrectionDetected);
    on<ClearServerCorrection>(_onClearServerCorrection);
    on<SyncOfflineData>(_onSyncOfflineData);
    on<AddEventLog>(_onAddEventLog);
    on<ClearEventLog>(_onClearEventLog);
    on<HaulerUpdatedFromServer>(_onHaulerUpdatedFromServer);
  }

  Future<void> _onInitialize(
    InitializeHauler event,
    Emitter<HaulerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Initialize location service
      await locationRepository.initialize();
      
      // Get or create hauler
      final haulerResult = await haulerRepository.getOrCreateHauler(event.haulerId);
      
      if (haulerResult.isLeft()) {
        final failure = haulerResult.fold((l) => l, (r) => throw Exception('Unexpected Right'));
        emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ));
      } else {
        final hauler = haulerResult.fold((l) => throw Exception('Unexpected Left'), (r) => r);
        
        // Setup streams
        _setupLoadersStream();
        _setupHaulerStream(event.haulerId);
        _setupConnectivityStream();
        _setupPingStream();
        
        emit(state.copyWith(
          hauler: hauler,
          eventSeq: hauler.eventSeq,
          isInitialized: true,
          isLoading: false,
        ));
        
        _addLog('System initialized');
        _addLog('Ping monitoring started');
        _addLog('Waiting for loader from Firestore...');
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Initialization failed: $e',
      ));
    }
  }

  void _setupLoadersStream() {
    _loadersSubscription = loaderRepository.streamLoaders().listen(
      (loaders) {
        add(LoadersUpdated(loaders: loaders));
      },
    );
  }

  void _setupHaulerStream(String haulerId) {
    _haulerSubscription?.cancel();
    _haulerSubscription = haulerRepository.streamHauler(haulerId).listen(
      (serverHauler) {
        if (serverHauler != null) {
          add(HaulerUpdatedFromServer(serverHauler: serverHauler));
        }
      },
      onError: (error) {
        _addLog('Error in hauler stream: $error');
      },
    );
  }

  Future<void> _onHaulerUpdatedFromServer(
    HaulerUpdatedFromServer event,
    Emitter<HaulerState> emit,
  ) async {
    final serverHauler = event.serverHauler;
    
    if (state.hauler == null) {
      // First time receiving hauler from server
      emit(state.copyWith(
        hauler: serverHauler,
        eventSeq: serverHauler.eventSeq,
      ));
      return;
    }
    
    // Check if server status differs from local status
    final localStatus = state.hauler!.currentStatus;
    final serverStatus = serverHauler.currentStatus;
    final localSeq = state.hauler!.eventSeq;
    final serverSeq = serverHauler.eventSeq;
    
    // If server has newer status or different status, apply server correction
    if (serverSeq > localSeq || 
        (serverSeq == localSeq && serverStatus != localStatus)) {
      // Server has updated status - apply correction
      add(const ServerCorrectionDetected());
      
      // Update local state to match server
      final updatedHauler = state.hauler!.copyWith(
        currentStatus: serverStatus,
        lastStatusChangeAt: serverHauler.lastStatusChangeAt,
        eventSeq: serverSeq,
        cycleId: serverHauler.cycleId,
        assignedLoaderId: serverHauler.assignedLoaderId,
        location: serverHauler.location,
        bodyUp: serverHauler.bodyUp,
        online: serverHauler.online,
      );
      
      // Emit updated state
      emit(state.copyWith(
        hauler: updatedHauler,
        eventSeq: serverSeq,
      ));
      
      if (serverStatus != localStatus) {
        _addLog('Server correction: ${localStatus.code} → ${serverStatus.code}');
      }
    } else if (serverSeq < localSeq) {
      // Local has newer status - this is normal, local update will sync
      // Just update other fields that might have changed
      final updatedHauler = state.hauler!.copyWith(
        location: serverHauler.location,
        bodyUp: serverHauler.bodyUp,
        online: serverHauler.online,
        cycleId: serverHauler.cycleId,
        assignedLoaderId: serverHauler.assignedLoaderId,
      );
      
      emit(state.copyWith(hauler: updatedHauler));
    }
  }

  void _setupConnectivityStream() {
    _connectivitySubscription = connectivityRepository.connectivityStream.listen(
      (isOnline) {
        add(_ConnectivityChanged(isOnline: isOnline));
      },
    );
  }

  void _setupPingStream() {
    // Start ping monitoring
    connectivityRepository.startPingMonitoring();
    
    _pingSubscription = connectivityRepository.pingStream.listen(
      (pingResult) {
        add(_PingUpdated(pingResult: pingResult));
      },
    );
  }

  Future<void> _onPingUpdated(
    _PingUpdated event,
    Emitter<HaulerState> emit,
  ) async {
    final ping = event.pingResult;
    final previousQuality = state.connectionQuality;
    
    emit(state.copyWith(
      pingResult: ping,
      isOnline: ping.isReachable,
    ));

    // Log quality changes
    if (ping.quality != previousQuality) {
      _addLog('Connection: ${ping.quality.displayName} (${ping.pingMs}ms)');
      _addLog('Sync strategy: ${ping.syncStrategy.description}');
    }
  }

  Future<void> _onRefreshPing(
    RefreshPing event,
    Emitter<HaulerState> emit,
  ) async {
    _addLog('Measuring ping...');
    final ping = await connectivityRepository.measurePing();
    emit(state.copyWith(
      pingResult: ping,
      isOnline: ping.isReachable,
    ));
    _addLog('Ping: ${ping.pingMs}ms - ${ping.quality.displayName}');
  }

  Future<void> _onSelectLoader(
    SelectLoader event,
    Emitter<HaulerState> emit,
  ) async {
    final loader = event.loader;
    _addLog('Selected loader: ${loader.name}');
    
    // Create dump point relative to loader
    final dumpPoint = DumpPointEntity(
      id: 'dump-${loader.id}',
      name: 'Dump Point',
      location: GeoLocation(
        lat: loader.location.lat + 0.005,
        lng: loader.location.lng + 0.005,
        accuracy: 5.0,
      ),
      radius: AppConstants.dumpPointRadius,
    );
    
    emit(state.copyWith(
      selectedLoader: loader,
      dumpPoint: dumpPoint,
    ));
  }

  Future<void> _onSetDumpPoint(
    SetDumpPoint event,
    Emitter<HaulerState> emit,
  ) async {
    final dumpPoint = DumpPointEntity(
      id: 'dump-custom',
      name: 'Custom Dump Point',
      location: event.location,
      radius: AppConstants.dumpPointRadius,
    );
    
    emit(state.copyWith(dumpPoint: dumpPoint));
    _addLog('Dump point set at ${event.location.lat}, ${event.location.lng}');
  }

  Future<void> _onStartCycle(
    StartCycleEvent event,
    Emitter<HaulerState> emit,
  ) async {
    if (state.selectedLoader == null) {
      _addLog('Cannot start cycle: no loader selected');
      return;
    }
    
    if (state.dumpPoint == null) {
      _addLog('Cannot start cycle: no dump point set');
      return;
    }
    
    if (state.currentStatus != HaulerStatus.standby) {
      _addLog('Cannot start cycle: not in standby');
      return;
    }
    
    final cycleId = _uuid.v4();
    final cycle = CycleEntity.start(
      id: cycleId,
      haulerId: state.haulerId,
      loaderId: state.selectedLoader!.id,
      loaderLocation: state.selectedLoader!.location,
      dumpLocation: state.dumpPoint!.location,
    );
    
    final result = await cycleRepository.createCycle(cycle);
    
    if (result.isLeft()) {
      final failure = result.fold((l) => l, (r) => throw Exception('Unexpected Right'));
      _addLog('Failed to start cycle: ${failure.message}');
    } else {
      emit(state.copyWith(currentCycle: cycle));
      
      // Transition to queuing
      await _updateHaulerStatus(
        HaulerStatus.queuing,
        TransitionCause.systemInit,
        emit,
      );
      
      _addLog('Cycle started: $cycleId');
    }
  }

  Future<void> _onCompleteCycle(
    CompleteCycleEvent event,
    Emitter<HaulerState> emit,
  ) async {
    if (state.currentCycle == null) return;
    
    final completedCycle = state.currentCycle!.complete();
    await cycleRepository.updateCycle(completedCycle);
    
    await _updateHaulerStatus(
      HaulerStatus.standby,
      TransitionCause.cycleComplete,
      emit,
    );
    
    emit(state.copyWith(currentCycle: completedCycle));
    _addLog('Cycle completed');
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<HaulerState> emit,
  ) async {
    if (state.hauler == null) return;
    
    final updatedHauler = state.hauler!.copyWith(location: event.location);
    emit(state.copyWith(hauler: updatedHauler));
    
    // Update Firestore occasionally
    await haulerRepository.updateLocation(state.haulerId, event.location);
    
    // Process auto transitions
    add(const ProcessAutoTransitions());
  }

  Future<void> _onToggleBodyUp(
    ToggleBodyUp event,
    Emitter<HaulerState> emit,
  ) async {
    add(SetBodyUp(isUp: !state.bodyUp));
  }

  Future<void> _onSetBodyUp(
    SetBodyUp event,
    Emitter<HaulerState> emit,
  ) async {
    if (state.hauler == null) return;
    
    final updatedHauler = state.hauler!.copyWith(bodyUp: event.isUp);
    emit(state.copyWith(hauler: updatedHauler));
    
    await haulerRepository.updateBodyUp(state.haulerId, event.isUp);
    
    _addLog('Body ${event.isUp ? "UP" : "DOWN"}');
    
    // Process auto transitions
    add(const ProcessAutoTransitions());
  }

  Future<void> _onManualTransition(
    ManualTransition event,
    Emitter<HaulerState> emit,
  ) async {
    if (state.hauler == null) return;
    
    final currentStatus = state.currentStatus;
    final targetStatus = event.targetStatus;
    
    if (!HaulerStateMachine.canTransition(currentStatus, targetStatus)) {
      _addLog('Transition from ${currentStatus.code} to ${targetStatus.code} not allowed');
      return;
    }
    
    await _updateHaulerStatus(targetStatus, TransitionCause.manualOverride, emit);
    _addLog('Manual transition to ${targetStatus.displayName}');
  }

  Future<void> _onProcessAutoTransitions(
    ProcessAutoTransitions event,
    Emitter<HaulerState> emit,
  ) async {
    if (state.hauler == null || state.currentCycle == null) return;
    
    final currentStatus = state.currentStatus;
    final location = state.hauler?.location;
    
    if (location == null) return;
    
    final loader = state.selectedLoader;
    final dumpPoint = state.dumpPoint;
    
    if (loader == null || dumpPoint == null) return;
    
    final inLoaderRadius = location.distanceTo(loader.location) <= loader.radius;
    final inDumpRadius = location.distanceTo(dumpPoint.location) <= dumpPoint.radius;
    
    // T1: QUEUING/HAULING_EMPTY → SPOTTING
    if ((currentStatus == HaulerStatus.queuing || 
         currentStatus == HaulerStatus.haulingEmpty) && inLoaderRadius) {
      if (currentStatus == HaulerStatus.haulingEmpty) {
        await _updateHaulerStatus(HaulerStatus.queuing, TransitionCause.cycleComplete, emit);
      }
      await _updateHaulerStatus(HaulerStatus.spotting, TransitionCause.enteredLoaderRadius, emit);
    }
    // SPOTTING → LOADING
    else if (currentStatus == HaulerStatus.spotting && inLoaderRadius) {
      await _updateHaulerStatus(HaulerStatus.loading, TransitionCause.loaderConfirmed, emit);
    }
    // T2: HAULING_LOAD → DUMPING
    else if (currentStatus == HaulerStatus.haulingLoad && inDumpRadius && state.bodyUp) {
      await _updateHaulerStatus(HaulerStatus.dumping, TransitionCause.bodyUp, emit);
    }
    // DUMPING → HAULING_EMPTY
    else if (currentStatus == HaulerStatus.dumping && !state.bodyUp) {
      await _updateHaulerStatus(HaulerStatus.haulingEmpty, TransitionCause.bodyDown, emit);
    }
  }

  Future<void> _onCompleteLoading(
    CompleteLoading event,
    Emitter<HaulerState> emit,
  ) async {
    if (state.currentStatus != HaulerStatus.loading) return;
    await _updateHaulerStatus(HaulerStatus.haulingLoad, TransitionCause.loadingComplete, emit);
  }

  Future<void> _onForceTransition(
    ForceTransition event,
    Emitter<HaulerState> emit,
  ) async {
    await _updateHaulerStatus(event.targetStatus, event.cause, emit);
  }

  Future<void> _onLoadersUpdated(
    LoadersUpdated event,
    Emitter<HaulerState> emit,
  ) async {
    _addLog('Received ${event.loaders.length} loader(s) from Firestore');
    
    emit(state.copyWith(availableLoaders: event.loaders));
    
    // Auto-select first loader if none selected
    if (state.selectedLoader == null && event.loaders.isNotEmpty) {
      add(SelectLoader(loader: event.loaders.first));
    }
    
    // Update selected loader if it changed
    if (state.selectedLoader != null) {
      final updated = event.loaders.where((l) => l.id == state.selectedLoader!.id).firstOrNull;
      if (updated != null && updated.waitingTruck != state.selectedLoader!.waitingTruck) {
        emit(state.copyWith(selectedLoader: updated));
        _addLog('Loader ${updated.name}: waitingTruck = ${updated.waitingTruck}');
      }
    }
  }

  Future<void> _onServerCorrectionDetected(
    ServerCorrectionDetected event,
    Emitter<HaulerState> emit,
  ) async {
    emit(state.copyWith(serverCorrected: true));
    _addLog('Server correction applied');
  }

  Future<void> _onClearServerCorrection(
    ClearServerCorrection event,
    Emitter<HaulerState> emit,
  ) async {
    emit(state.copyWith(serverCorrected: false));
  }

  Future<void> _onSyncOfflineData(
    SyncOfflineData event,
    Emitter<HaulerState> emit,
  ) async {
    await connectivityRepository.syncOfflineData();
    _addLog('Offline data synced');
  }

  Future<void> _onAddEventLog(
    AddEventLog event,
    Emitter<HaulerState> emit,
  ) async {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final newLog = '[$timestamp] ${event.message}';
    final eventLog = [newLog, ...state.eventLog];
    if (eventLog.length > 100) {
      eventLog.removeLast();
    }
    emit(state.copyWith(eventLog: eventLog));
  }

  Future<void> _onClearEventLog(
    ClearEventLog event,
    Emitter<HaulerState> emit,
  ) async {
    emit(state.copyWith(eventLog: []));
  }

  Future<void> _onConnectivityChanged(
    _ConnectivityChanged event,
    Emitter<HaulerState> emit,
  ) async {
    emit(state.copyWith(isOnline: event.isOnline));
  }

  Future<void> _updateHaulerStatus(
    HaulerStatus newStatus,
    TransitionCause cause,
    Emitter<HaulerState> emit,
  ) async {
    final previousStatus = state.hauler?.currentStatus;
    final now = DateTime.now();
    final newSeq = state.eventSeq + 1;
    
    // Create event
    final event = HaulerEventEntity.create(
      id: _uuid.v4(),
      haulerId: state.haulerId,
      cycleId: state.currentCycle?.id ?? 'no-cycle',
      fromStatus: previousStatus,
      toStatus: newStatus,
      cause: cause,
      seq: newSeq,
      metadata: {
        'location': state.hauler?.location?.let((l) => {'lat': l.lat, 'lng': l.lng}),
        'bodyUp': state.hauler?.bodyUp,
      },
    );
    
    // Save event
    await haulerRepository.saveEvent(event);
    
    // Update local hauler
    final updatedHauler = state.hauler?.copyWith(
      currentStatus: newStatus,
      lastStatusChangeAt: now,
      deviceTime: now,
      cycleId: state.currentCycle?.id,
      eventSeq: newSeq,
    );
    
    // Update Firestore
    if (updatedHauler != null) {
      await haulerRepository.updateHauler(state.haulerId, {
        'currentStatus': newStatus.code,
        'lastStatusChangeAt': now.toIso8601String(),
        'cycleId': state.currentCycle?.id,
        'eventSeq': newSeq,
      });
    }
    
    // Update cycle steps
    CycleEntity? updatedCycle;
    if (state.currentCycle != null) {
      final step = CycleStepEntity.enter(newStatus, state.hauler?.location);
      updatedCycle = state.currentCycle!.addStep(step);
      await cycleRepository.updateCycle(updatedCycle);
    }
    
    emit(state.copyWith(
      hauler: updatedHauler,
      currentCycle: updatedCycle ?? state.currentCycle,
      eventSeq: newSeq,
    ));
    
    _addLog('Status: ${newStatus.displayName}');
  }

  void _addLog(String message) {
    add(AddEventLog(message: message));
  }

  @override
  Future<void> close() {
    _loadersSubscription?.cancel();
    _haulerSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _pingSubscription?.cancel();
    connectivityRepository.stopPingMonitoring();
    return super.close();
  }
}

/// Extension to add let functionality
extension LetExtension<T> on T {
  R let<R>(R Function(T) block) => block(this);
}



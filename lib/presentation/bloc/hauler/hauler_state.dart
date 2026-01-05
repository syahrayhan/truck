part of 'hauler_bloc.dart';

/// State for HaulerBloc
class HaulerState extends Equatable {
  final String haulerId;
  final HaulerEntity? hauler;
  final CycleEntity? currentCycle;
  final LoaderEntity? selectedLoader;
  final DumpPointEntity? dumpPoint;
  final List<LoaderEntity> availableLoaders;
  final List<String> eventLog;
  final bool isInitialized;
  final bool isLoading;
  final String? errorMessage;
  final bool serverCorrected;
  final bool isOnline;
  final int eventSeq;
  final PingResult? pingResult;

  const HaulerState({
    required this.haulerId,
    this.hauler,
    this.currentCycle,
    this.selectedLoader,
    this.dumpPoint,
    this.availableLoaders = const [],
    this.eventLog = const [],
    this.isInitialized = false,
    this.isLoading = true,
    this.errorMessage,
    this.serverCorrected = false,
    this.isOnline = true,
    this.eventSeq = 0,
    this.pingResult,
  });

  factory HaulerState.initial(String haulerId) {
    return HaulerState(haulerId: haulerId);
  }

  HaulerStatus get currentStatus => 
      hauler?.currentStatus ?? HaulerStatus.standby;

  GeoLocation? get currentLocation => hauler?.location;

  bool get bodyUp => hauler?.bodyUp ?? false;

  bool get hasLoader => selectedLoader != null;

  bool get isInCycle => currentCycle != null && !currentCycle!.completed;

  /// Get connection quality from ping result
  ConnectionQuality get connectionQuality =>
      pingResult?.quality ?? ConnectionQuality.offline;

  /// Get current sync strategy
  SyncStrategy get syncStrategy =>
      pingResult?.syncStrategy ?? SyncStrategy.queue;

  /// Get ping in milliseconds (-1 if offline)
  int get pingMs => pingResult?.pingMs ?? -1;

  /// Get TTL (null if not available)
  int? get ttl => pingResult?.ttl;

  HaulerState copyWith({
    String? haulerId,
    HaulerEntity? hauler,
    CycleEntity? currentCycle,
    LoaderEntity? selectedLoader,
    DumpPointEntity? dumpPoint,
    List<LoaderEntity>? availableLoaders,
    List<String>? eventLog,
    bool? isInitialized,
    bool? isLoading,
    String? errorMessage,
    bool? serverCorrected,
    bool? isOnline,
    int? eventSeq,
    PingResult? pingResult,
  }) {
    return HaulerState(
      haulerId: haulerId ?? this.haulerId,
      hauler: hauler ?? this.hauler,
      currentCycle: currentCycle ?? this.currentCycle,
      selectedLoader: selectedLoader ?? this.selectedLoader,
      dumpPoint: dumpPoint ?? this.dumpPoint,
      availableLoaders: availableLoaders ?? this.availableLoaders,
      eventLog: eventLog ?? this.eventLog,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      serverCorrected: serverCorrected ?? this.serverCorrected,
      isOnline: isOnline ?? this.isOnline,
      eventSeq: eventSeq ?? this.eventSeq,
      pingResult: pingResult ?? this.pingResult,
    );
  }

  @override
  List<Object?> get props => [
    haulerId, hauler, currentCycle, selectedLoader, dumpPoint,
    availableLoaders, eventLog, isInitialized, isLoading,
    errorMessage, serverCorrected, isOnline, eventSeq, pingResult,
  ];
}



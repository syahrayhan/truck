/// Application-wide constants for Hauler Truck Mining Operations
class AppConstants {
  // Collection names
  static const String collectionHaulers = 'haulers';
  static const String collectionHaulerEvents = 'hauler_events';
  static const String collectionTelemetry = 'telemetry';
  static const String collectionCycles = 'cycles';
  static const String collectionLoaders = 'loaders';

  // Radius thresholds (meters)
  static const double loaderRadius = 50.0;
  static const double dumpPointRadius = 40.0;
  static const double gpsAccuracyThreshold = 50.0;

  // Telemetry intervals
  static const Duration telemetryInterval = Duration(seconds: 2);
  static const Duration locationUpdateInterval = Duration(seconds: 1);
  static const Duration syncRetryInterval = Duration(seconds: 5);

  // Simulation
  static const double simulationSpeedMps = 10.0; // meters per second
  static const Duration simulationStepInterval = Duration(milliseconds: 500);

  // Offline queue
  static const String offlineQueueBox = 'offline_queue';
  static const String settingsBox = 'settings';
  static const int maxQueueRetries = 5;
}

/// Hauler status states following the mining cycle
enum HaulerStatus {
  standby('STANDBY', 'Menunggu Penugasan'),
  queuing('QUEUING', 'Mengantri di Loader'),
  spotting('SPOTTING', 'Positioning di Loader'),
  loading('LOADING', 'Proses Pemuatan'),
  haulingLoad('HAULING_LOAD', 'Mengangkut Muatan'),
  dumping('DUMPING', 'Proses Pembongkaran'),
  haulingEmpty('HAULING_EMPTY', 'Kembali ke Loader');

  const HaulerStatus(this.code, this.displayName);
  
  final String code;
  final String displayName;

  static HaulerStatus fromCode(String code) {
    return HaulerStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => HaulerStatus.standby,
    );
  }

  bool get isActive => this != HaulerStatus.standby;
  
  bool get canAcceptLoad => 
    this == HaulerStatus.queuing || 
    this == HaulerStatus.spotting;
}

/// Event causes for transitions
enum TransitionCause {
  systemInit('SYSTEM_INIT'),
  loaderReady('LOADER_READY'),
  enteredLoaderRadius('ENTERED_LOADER_RADIUS'),
  loaderConfirmed('LOADER_CONFIRMED'),
  loadingComplete('LOADING_COMPLETE'),
  enteredDumpRadius('ENTERED_DUMP_RADIUS'),
  bodyUp('BODY_UP'),
  dumpingComplete('DUMPING_COMPLETE'),
  bodyDown('BODY_DOWN'),
  cycleComplete('CYCLE_COMPLETE'),
  manualOverride('MANUAL_OVERRIDE'),
  serverCorrection('SERVER_CORRECTION'),
  timeout('TIMEOUT'),
  error('ERROR');

  const TransitionCause(this.code);
  final String code;

  static TransitionCause fromCode(String code) {
    return TransitionCause.values.firstWhere(
      (c) => c.code == code,
      orElse: () => TransitionCause.error,
    );
  }
}

/// Intent types that client can send to server
enum IntentType {
  requestSpotting('REQUEST_SPOTTING'),
  confirmLoading('CONFIRM_LOADING'),
  startHauling('START_HAULING'),
  requestDumping('REQUEST_DUMPING'),
  completeDumping('COMPLETE_DUMPING'),
  returnToQueue('RETURN_TO_QUEUE'),
  goStandby('GO_STANDBY');

  const IntentType(this.code);
  final String code;
}


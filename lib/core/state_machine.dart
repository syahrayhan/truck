import 'constants.dart';

/// State machine for Hauler status transitions
/// Implements allowed transitions with guards for validation
class HaulerStateMachine {
  /// Defines allowed transitions from each status
  static final Map<HaulerStatus, Set<HaulerStatus>> _allowedTransitions = {
    HaulerStatus.standby: {
      HaulerStatus.queuing,
    },
    HaulerStatus.queuing: {
      HaulerStatus.spotting,
      HaulerStatus.standby,
    },
    HaulerStatus.spotting: {
      HaulerStatus.loading,
      HaulerStatus.queuing,
      HaulerStatus.standby,
    },
    HaulerStatus.loading: {
      HaulerStatus.haulingLoad,
      HaulerStatus.standby,
    },
    HaulerStatus.haulingLoad: {
      HaulerStatus.dumping,
      HaulerStatus.standby,
    },
    HaulerStatus.dumping: {
      HaulerStatus.haulingEmpty,
      HaulerStatus.standby,
    },
    HaulerStatus.haulingEmpty: {
      HaulerStatus.queuing,
      HaulerStatus.standby,
    },
  };

  /// Check if transition is allowed
  static bool canTransition(HaulerStatus from, HaulerStatus to) {
    final allowed = _allowedTransitions[from];
    return allowed?.contains(to) ?? false;
  }

  /// Get next status in the normal cycle
  static HaulerStatus? getNextInCycle(HaulerStatus current) {
    switch (current) {
      case HaulerStatus.standby:
        return HaulerStatus.queuing;
      case HaulerStatus.queuing:
        return HaulerStatus.spotting;
      case HaulerStatus.spotting:
        return HaulerStatus.loading;
      case HaulerStatus.loading:
        return HaulerStatus.haulingLoad;
      case HaulerStatus.haulingLoad:
        return HaulerStatus.dumping;
      case HaulerStatus.dumping:
        return HaulerStatus.haulingEmpty;
      case HaulerStatus.haulingEmpty:
        return HaulerStatus.queuing; // Cycle repeats
    }
  }

  /// Get all allowed transitions from a status
  static Set<HaulerStatus> getAllowedTransitions(HaulerStatus from) {
    return _allowedTransitions[from] ?? {};
  }
}

/// Transition guard conditions
class TransitionGuard {
  final HaulerStatus from;
  final HaulerStatus to;
  final bool Function(TransitionContext) condition;
  final String description;

  const TransitionGuard({
    required this.from,
    required this.to,
    required this.condition,
    required this.description,
  });
}

/// Context for evaluating transition guards
class TransitionContext {
  final double? haulerLat;
  final double? haulerLng;
  final double? gpsAccuracy;
  final double? loaderLat;
  final double? loaderLng;
  final double? dumpLat;
  final double? dumpLng;
  final bool? loaderWaitingTruck;
  final bool? bodyUp;
  final HaulerStatus currentStatus;
  final DateTime deviceTime;

  TransitionContext({
    this.haulerLat,
    this.haulerLng,
    this.gpsAccuracy,
    this.loaderLat,
    this.loaderLng,
    this.dumpLat,
    this.dumpLng,
    this.loaderWaitingTruck,
    this.bodyUp,
    required this.currentStatus,
    required this.deviceTime,
  });

  /// Check if hauler is within loader radius
  bool get isInLoaderRadius {
    if (haulerLat == null || haulerLng == null || 
        loaderLat == null || loaderLng == null) {
      return false;
    }
    final distance = _calculateDistance(
      haulerLat!, haulerLng!, loaderLat!, loaderLng!
    );
    return distance <= AppConstants.loaderRadius;
  }

  /// Check if hauler is within dump point radius
  bool get isInDumpRadius {
    if (haulerLat == null || haulerLng == null || 
        dumpLat == null || dumpLng == null) {
      return false;
    }
    final distance = _calculateDistance(
      haulerLat!, haulerLng!, dumpLat!, dumpLng!
    );
    return distance <= AppConstants.dumpPointRadius;
  }

  /// Check if GPS accuracy is acceptable
  bool get hasAcceptableGpsAccuracy {
    return gpsAccuracy == null || 
           gpsAccuracy! <= AppConstants.gpsAccuracyThreshold;
  }

  /// Calculate haversine distance between two points
  static double _calculateDistance(
    double lat1, double lon1, double lat2, double lon2
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  static double _sin(double x) => _taylorSin(x);
  static double _cos(double x) => _taylorSin(x + 3.14159265359 / 2);
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }
  static double _atan(double x) {
    // Taylor series approximation
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 3.14159265359 / 2 - _atan(1 / x);
    }
    double result = 0;
    double term = x;
    for (int n = 0; n < 20; n++) {
      result += term / (2 * n + 1) * (n % 2 == 0 ? 1 : -1);
      term *= x * x;
    }
    return result;
  }
  static double _taylorSin(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159265359) x -= 2 * 3.14159265359;
    while (x < -3.14159265359) x += 2 * 3.14159265359;
    double result = 0;
    double term = x;
    for (int n = 0; n < 15; n++) {
      result += term;
      term *= -x * x / ((2 * n + 2) * (2 * n + 3));
    }
    return result;
  }
}

/// Transition guards registry
class TransitionGuards {
  static final List<TransitionGuard> guards = [
    // T1: QUEUING → SPOTTING
    TransitionGuard(
      from: HaulerStatus.queuing,
      to: HaulerStatus.spotting,
      condition: (ctx) => 
        ctx.isInLoaderRadius && 
        ctx.loaderWaitingTruck == true &&
        ctx.hasAcceptableGpsAccuracy,
      description: 'Hauler in loader radius, loader waiting, GPS accurate',
    ),
    
    // SPOTTING → LOADING
    TransitionGuard(
      from: HaulerStatus.spotting,
      to: HaulerStatus.loading,
      condition: (ctx) => ctx.isInLoaderRadius,
      description: 'Hauler positioned at loader',
    ),
    
    // LOADING → HAULING_LOAD
    TransitionGuard(
      from: HaulerStatus.loading,
      to: HaulerStatus.haulingLoad,
      condition: (ctx) => true, // Triggered by loader confirmation
      description: 'Loading complete confirmed',
    ),
    
    // T2: HAULING_LOAD → DUMPING
    TransitionGuard(
      from: HaulerStatus.haulingLoad,
      to: HaulerStatus.dumping,
      condition: (ctx) => 
        ctx.isInDumpRadius && 
        ctx.bodyUp == true &&
        ctx.hasAcceptableGpsAccuracy,
      description: 'At dump point with body raised',
    ),
    
    // DUMPING → HAULING_EMPTY
    TransitionGuard(
      from: HaulerStatus.dumping,
      to: HaulerStatus.haulingEmpty,
      condition: (ctx) => ctx.bodyUp == false,
      description: 'Dumping complete, body lowered',
    ),
    
    // HAULING_EMPTY → QUEUING (cycle restart)
    TransitionGuard(
      from: HaulerStatus.haulingEmpty,
      to: HaulerStatus.queuing,
      condition: (ctx) => ctx.isInLoaderRadius,
      description: 'Returned to loader area',
    ),
  ];

  /// Check if transition passes guard conditions
  static bool checkGuard(TransitionContext context, HaulerStatus to) {
    final guard = guards.firstWhere(
      (g) => g.from == context.currentStatus && g.to == to,
      orElse: () => TransitionGuard(
        from: context.currentStatus,
        to: to,
        condition: (_) => true,
        description: 'Default allow',
      ),
    );
    return guard.condition(context);
  }

  /// Get guard description for a transition
  static String? getGuardDescription(HaulerStatus from, HaulerStatus to) {
    try {
      return guards.firstWhere(
        (g) => g.from == from && g.to == to,
      ).description;
    } catch (_) {
      return null;
    }
  }
}


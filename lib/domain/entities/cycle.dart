import 'package:equatable/equatable.dart';
import 'geo_location.dart';
import '../../core/constants.dart';

/// Domain entity for Cycle
class CycleEntity extends Equatable {
  final String id;
  final String haulerId;
  final String? loaderId;
  final GeoLocation? loaderLocation;
  final GeoLocation? dumpLocation;
  final double dumpRadius;
  final List<CycleStepEntity> steps;
  final bool completed;
  final List<String> anomalies;
  final DateTime startedAt;
  final DateTime? completedAt;

  const CycleEntity({
    required this.id,
    required this.haulerId,
    this.loaderId,
    this.loaderLocation,
    this.dumpLocation,
    this.dumpRadius = AppConstants.dumpPointRadius,
    this.steps = const [],
    this.completed = false,
    this.anomalies = const [],
    required this.startedAt,
    this.completedAt,
  });

  factory CycleEntity.start({
    required String id,
    required String haulerId,
    String? loaderId,
    GeoLocation? loaderLocation,
    GeoLocation? dumpLocation,
  }) {
    return CycleEntity(
      id: id,
      haulerId: haulerId,
      loaderId: loaderId,
      loaderLocation: loaderLocation,
      dumpLocation: dumpLocation,
      startedAt: DateTime.now(),
    );
  }

  CycleEntity copyWith({
    String? id,
    String? haulerId,
    String? loaderId,
    GeoLocation? loaderLocation,
    GeoLocation? dumpLocation,
    double? dumpRadius,
    List<CycleStepEntity>? steps,
    bool? completed,
    List<String>? anomalies,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return CycleEntity(
      id: id ?? this.id,
      haulerId: haulerId ?? this.haulerId,
      loaderId: loaderId ?? this.loaderId,
      loaderLocation: loaderLocation ?? this.loaderLocation,
      dumpLocation: dumpLocation ?? this.dumpLocation,
      dumpRadius: dumpRadius ?? this.dumpRadius,
      steps: steps ?? this.steps,
      completed: completed ?? this.completed,
      anomalies: anomalies ?? this.anomalies,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  CycleEntity addStep(CycleStepEntity step) {
    return copyWith(steps: [...steps, step]);
  }

  CycleEntity addAnomaly(String anomaly) {
    return copyWith(anomalies: [...anomalies, anomaly]);
  }

  CycleEntity complete() {
    return copyWith(completed: true, completedAt: DateTime.now());
  }

  @override
  List<Object?> get props => [
    id, haulerId, loaderId, loaderLocation, dumpLocation,
    dumpRadius, steps, completed, anomalies, startedAt, completedAt
  ];
}

/// Individual step in a cycle
class CycleStepEntity extends Equatable {
  final HaulerStatus status;
  final DateTime enteredAt;
  final DateTime? exitedAt;
  final GeoLocation? location;
  final int durationSeconds;

  const CycleStepEntity({
    required this.status,
    required this.enteredAt,
    this.exitedAt,
    this.location,
    this.durationSeconds = 0,
  });

  factory CycleStepEntity.enter(HaulerStatus status, GeoLocation? location) {
    return CycleStepEntity(
      status: status,
      enteredAt: DateTime.now(),
      location: location,
    );
  }

  CycleStepEntity exit() {
    final now = DateTime.now();
    return CycleStepEntity(
      status: status,
      enteredAt: enteredAt,
      exitedAt: now,
      location: location,
      durationSeconds: now.difference(enteredAt).inSeconds,
    );
  }

  @override
  List<Object?> get props => [status, enteredAt, exitedAt, location, durationSeconds];
}



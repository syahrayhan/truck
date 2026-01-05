import '../../core/constants.dart';
import '../../domain/entities/entities.dart';
import 'geo_location_model.dart';

/// Data model for Cycle with JSON serialization
class CycleModel extends CycleEntity {
  const CycleModel({
    required super.id,
    required super.haulerId,
    super.loaderId,
    super.loaderLocation,
    super.dumpLocation,
    super.dumpRadius,
    super.steps,
    super.completed,
    super.anomalies,
    required super.startedAt,
    super.completedAt,
  });

  factory CycleModel.fromMap(Map<String, dynamic> map, String docId) {
    return CycleModel(
      id: docId,
      haulerId: map['haulerId'] as String,
      loaderId: map['loaderId'] as String?,
      loaderLocation: map['loaderLocation'] != null
          ? GeoLocationModel.fromMap(map['loaderLocation'] as Map<String, dynamic>)
          : null,
      dumpLocation: map['dumpLocation'] != null
          ? GeoLocationModel.fromMap(map['dumpLocation'] as Map<String, dynamic>)
          : null,
      dumpRadius: (map['dumpRadius'] as num?)?.toDouble() ?? AppConstants.dumpPointRadius,
      steps: (map['steps'] as List<dynamic>?)
              ?.map((s) => CycleStepModel.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      completed: map['completed'] as bool? ?? false,
      anomalies: (map['anomalies'] as List<dynamic>?)
              ?.map((a) => a as String)
              .toList() ??
          [],
      startedAt: DateTime.parse(map['startedAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'haulerId': haulerId,
      if (loaderId != null) 'loaderId': loaderId,
      if (loaderLocation != null) 'loaderLocation': GeoLocationModel.fromEntity(loaderLocation!).toMap(),
      if (dumpLocation != null) 'dumpLocation': GeoLocationModel.fromEntity(dumpLocation!).toMap(),
      'dumpRadius': dumpRadius,
      'steps': steps.map((s) => CycleStepModel.fromEntity(s).toMap()).toList(),
      'completed': completed,
      'anomalies': anomalies,
      'startedAt': startedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  factory CycleModel.fromEntity(CycleEntity entity) {
    return CycleModel(
      id: entity.id,
      haulerId: entity.haulerId,
      loaderId: entity.loaderId,
      loaderLocation: entity.loaderLocation,
      dumpLocation: entity.dumpLocation,
      dumpRadius: entity.dumpRadius,
      steps: entity.steps,
      completed: entity.completed,
      anomalies: entity.anomalies,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
    );
  }

  CycleEntity toEntity() {
    return CycleEntity(
      id: id,
      haulerId: haulerId,
      loaderId: loaderId,
      loaderLocation: loaderLocation,
      dumpLocation: dumpLocation,
      dumpRadius: dumpRadius,
      steps: steps,
      completed: completed,
      anomalies: anomalies,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }
}

/// Data model for CycleStep with JSON serialization
class CycleStepModel extends CycleStepEntity {
  const CycleStepModel({
    required super.status,
    required super.enteredAt,
    super.exitedAt,
    super.location,
    super.durationSeconds,
  });

  factory CycleStepModel.fromMap(Map<String, dynamic> map) {
    return CycleStepModel(
      status: HaulerStatus.fromCode(map['status'] as String),
      enteredAt: DateTime.parse(map['enteredAt'] as String),
      exitedAt: map['exitedAt'] != null
          ? DateTime.parse(map['exitedAt'] as String)
          : null,
      location: map['location'] != null
          ? GeoLocationModel.fromMap(map['location'] as Map<String, dynamic>)
          : null,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.code,
      'enteredAt': enteredAt.toIso8601String(),
      if (exitedAt != null) 'exitedAt': exitedAt!.toIso8601String(),
      if (location != null) 'location': GeoLocationModel.fromEntity(location!).toMap(),
      'durationSeconds': durationSeconds,
    };
  }

  factory CycleStepModel.fromEntity(CycleStepEntity entity) {
    return CycleStepModel(
      status: entity.status,
      enteredAt: entity.enteredAt,
      exitedAt: entity.exitedAt,
      location: entity.location,
      durationSeconds: entity.durationSeconds,
    );
  }
}



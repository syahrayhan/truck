import '../../core/constants.dart';
import '../../domain/entities/entities.dart';
import 'geo_location_model.dart';

/// Data model for Hauler with JSON serialization
class HaulerModel extends HaulerEntity {
  const HaulerModel({
    required super.id,
    required super.currentStatus,
    required super.lastStatusChangeAt,
    super.location,
    super.bodyUp,
    super.online,
    required super.deviceTime,
    super.cycleId,
    super.assignedLoaderId,
    super.eventSeq,
  });

  factory HaulerModel.fromMap(Map<String, dynamic> map, String docId) {
    return HaulerModel(
      id: docId,
      currentStatus: HaulerStatus.fromCode(map['currentStatus'] as String? ?? 'STANDBY'),
      lastStatusChangeAt: map['lastStatusChangeAt'] != null
          ? DateTime.parse(map['lastStatusChangeAt'] as String)
          : DateTime.now(),
      location: map['location'] != null
          ? GeoLocationModel.fromMap(map['location'] as Map<String, dynamic>)
          : null,
      bodyUp: map['bodyUp'] as bool? ?? false,
      online: map['online'] as bool? ?? true,
      deviceTime: map['deviceTime'] != null
          ? DateTime.parse(map['deviceTime'] as String)
          : DateTime.now(),
      cycleId: map['cycleId'] as String?,
      assignedLoaderId: map['assignedLoaderId'] as String?,
      eventSeq: map['eventSeq'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStatus': currentStatus.code,
      'lastStatusChangeAt': lastStatusChangeAt.toIso8601String(),
      if (location != null) 'location': GeoLocationModel.fromEntity(location!).toMap(),
      'bodyUp': bodyUp,
      'online': online,
      'deviceTime': deviceTime.toIso8601String(),
      if (cycleId != null) 'cycleId': cycleId,
      if (assignedLoaderId != null) 'assignedLoaderId': assignedLoaderId,
      'eventSeq': eventSeq,
    };
  }

  factory HaulerModel.fromEntity(HaulerEntity entity) {
    return HaulerModel(
      id: entity.id,
      currentStatus: entity.currentStatus,
      lastStatusChangeAt: entity.lastStatusChangeAt,
      location: entity.location,
      bodyUp: entity.bodyUp,
      online: entity.online,
      deviceTime: entity.deviceTime,
      cycleId: entity.cycleId,
      assignedLoaderId: entity.assignedLoaderId,
      eventSeq: entity.eventSeq,
    );
  }

  HaulerEntity toEntity() {
    return HaulerEntity(
      id: id,
      currentStatus: currentStatus,
      lastStatusChangeAt: lastStatusChangeAt,
      location: location,
      bodyUp: bodyUp,
      online: online,
      deviceTime: deviceTime,
      cycleId: cycleId,
      assignedLoaderId: assignedLoaderId,
      eventSeq: eventSeq,
    );
  }

  factory HaulerModel.initial(String id) {
    final now = DateTime.now();
    return HaulerModel(
      id: id,
      currentStatus: HaulerStatus.standby,
      lastStatusChangeAt: now,
      deviceTime: now,
    );
  }
}



import '../../core/constants.dart';
import '../../domain/entities/entities.dart';

/// Data model for HaulerEvent with JSON serialization
class HaulerEventModel extends HaulerEventEntity {
  const HaulerEventModel({
    required super.id,
    required super.haulerId,
    required super.cycleId,
    super.fromStatus,
    super.toStatus,
    required super.cause,
    required super.deviceTime,
    super.serverTime,
    required super.seq,
    required super.dedupKey,
    super.metadata,
    super.synced,
  });

  factory HaulerEventModel.fromMap(Map<String, dynamic> map, String docId) {
    return HaulerEventModel(
      id: docId,
      haulerId: map['haulerId'] as String,
      cycleId: map['cycleId'] as String,
      fromStatus: map['fromStatus'] != null
          ? HaulerStatus.fromCode(map['fromStatus'] as String)
          : null,
      toStatus: map['toStatus'] != null
          ? HaulerStatus.fromCode(map['toStatus'] as String)
          : null,
      cause: TransitionCause.fromCode(map['cause'] as String? ?? 'ERROR'),
      deviceTime: DateTime.parse(map['deviceTime'] as String),
      serverTime: map['serverTime'] != null
          ? DateTime.parse(map['serverTime'] as String)
          : null,
      seq: map['seq'] as int? ?? 0,
      dedupKey: map['dedupKey'] as String? ?? docId,
      metadata: map['metadata'] as Map<String, dynamic>?,
      synced: map['synced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'haulerId': haulerId,
      'cycleId': cycleId,
      if (fromStatus != null) 'fromStatus': fromStatus!.code,
      if (toStatus != null) 'toStatus': toStatus!.code,
      'cause': cause.code,
      'deviceTime': deviceTime.toIso8601String(),
      if (serverTime != null) 'serverTime': serverTime!.toIso8601String(),
      'seq': seq,
      'dedupKey': dedupKey,
      if (metadata != null) 'metadata': metadata,
      'synced': synced,
    };
  }

  factory HaulerEventModel.fromEntity(HaulerEventEntity entity) {
    return HaulerEventModel(
      id: entity.id,
      haulerId: entity.haulerId,
      cycleId: entity.cycleId,
      fromStatus: entity.fromStatus,
      toStatus: entity.toStatus,
      cause: entity.cause,
      deviceTime: entity.deviceTime,
      serverTime: entity.serverTime,
      seq: entity.seq,
      dedupKey: entity.dedupKey,
      metadata: entity.metadata,
      synced: entity.synced,
    );
  }

  HaulerEventEntity toEntity() {
    return HaulerEventEntity(
      id: id,
      haulerId: haulerId,
      cycleId: cycleId,
      fromStatus: fromStatus,
      toStatus: toStatus,
      cause: cause,
      deviceTime: deviceTime,
      serverTime: serverTime,
      seq: seq,
      dedupKey: dedupKey,
      metadata: metadata,
      synced: synced,
    );
  }
}



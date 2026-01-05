import 'package:equatable/equatable.dart';
import '../../core/constants.dart';

/// Domain entity for Hauler Event (event-sourcing)
class HaulerEventEntity extends Equatable {
  final String id;
  final String haulerId;
  final String cycleId;
  final HaulerStatus? fromStatus;
  final HaulerStatus? toStatus;
  final TransitionCause cause;
  final DateTime deviceTime;
  final DateTime? serverTime;
  final int seq;
  final String dedupKey;
  final Map<String, dynamic>? metadata;
  final bool synced;

  const HaulerEventEntity({
    required this.id,
    required this.haulerId,
    required this.cycleId,
    this.fromStatus,
    this.toStatus,
    required this.cause,
    required this.deviceTime,
    this.serverTime,
    required this.seq,
    required this.dedupKey,
    this.metadata,
    this.synced = false,
  });

  factory HaulerEventEntity.create({
    required String id,
    required String haulerId,
    required String cycleId,
    required HaulerStatus? fromStatus,
    required HaulerStatus? toStatus,
    required TransitionCause cause,
    required int seq,
    Map<String, dynamic>? metadata,
  }) {
    final deviceTime = DateTime.now();
    return HaulerEventEntity(
      id: id,
      haulerId: haulerId,
      cycleId: cycleId,
      fromStatus: fromStatus,
      toStatus: toStatus,
      cause: cause,
      deviceTime: deviceTime,
      seq: seq,
      dedupKey: '${haulerId}_${cycleId}_${seq}_${cause.code}',
      metadata: metadata,
      synced: false,
    );
  }

  HaulerEventEntity copyWith({
    String? id,
    String? haulerId,
    String? cycleId,
    HaulerStatus? fromStatus,
    HaulerStatus? toStatus,
    TransitionCause? cause,
    DateTime? deviceTime,
    DateTime? serverTime,
    int? seq,
    String? dedupKey,
    Map<String, dynamic>? metadata,
    bool? synced,
  }) {
    return HaulerEventEntity(
      id: id ?? this.id,
      haulerId: haulerId ?? this.haulerId,
      cycleId: cycleId ?? this.cycleId,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      cause: cause ?? this.cause,
      deviceTime: deviceTime ?? this.deviceTime,
      serverTime: serverTime ?? this.serverTime,
      seq: seq ?? this.seq,
      dedupKey: dedupKey ?? this.dedupKey,
      metadata: metadata ?? this.metadata,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [
    id, haulerId, cycleId, fromStatus, toStatus, cause,
    deviceTime, serverTime, seq, dedupKey, metadata, synced
  ];

  @override
  String toString() => 'HaulerEventEntity($id, ${fromStatus?.code} → ${toStatus?.code})';
}



import 'package:equatable/equatable.dart';
import 'geo_location.dart';
import '../../core/constants.dart';

/// Domain entity for Hauler (Truck)
class HaulerEntity extends Equatable {
  final String id;
  final HaulerStatus currentStatus;
  final DateTime lastStatusChangeAt;
  final GeoLocation? location;
  final bool bodyUp;
  final bool online;
  final DateTime deviceTime;
  final String? cycleId;
  final String? assignedLoaderId;
  final int eventSeq;

  const HaulerEntity({
    required this.id,
    required this.currentStatus,
    required this.lastStatusChangeAt,
    this.location,
    this.bodyUp = false,
    this.online = true,
    required this.deviceTime,
    this.cycleId,
    this.assignedLoaderId,
    this.eventSeq = 0,
  });

  factory HaulerEntity.initial(String id) {
    final now = DateTime.now();
    return HaulerEntity(
      id: id,
      currentStatus: HaulerStatus.standby,
      lastStatusChangeAt: now,
      deviceTime: now,
    );
  }

  HaulerEntity copyWith({
    String? id,
    HaulerStatus? currentStatus,
    DateTime? lastStatusChangeAt,
    GeoLocation? location,
    bool? bodyUp,
    bool? online,
    DateTime? deviceTime,
    String? cycleId,
    String? assignedLoaderId,
    int? eventSeq,
  }) {
    return HaulerEntity(
      id: id ?? this.id,
      currentStatus: currentStatus ?? this.currentStatus,
      lastStatusChangeAt: lastStatusChangeAt ?? this.lastStatusChangeAt,
      location: location ?? this.location,
      bodyUp: bodyUp ?? this.bodyUp,
      online: online ?? this.online,
      deviceTime: deviceTime ?? this.deviceTime,
      cycleId: cycleId ?? this.cycleId,
      assignedLoaderId: assignedLoaderId ?? this.assignedLoaderId,
      eventSeq: eventSeq ?? this.eventSeq,
    );
  }

  @override
  List<Object?> get props => [
    id, currentStatus, lastStatusChangeAt, location, 
    bodyUp, online, deviceTime, cycleId, assignedLoaderId, eventSeq
  ];

  @override
  String toString() => 'HaulerEntity($id, ${currentStatus.code})';
}



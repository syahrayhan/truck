import 'package:equatable/equatable.dart';
import 'geo_location.dart';

/// Domain entity for Telemetry data point
class TelemetryEntity extends Equatable {
  final String id;
  final String haulerId;
  final String cycleId;
  final double lat;
  final double lng;
  final double? accuracy;
  final bool bodyUp;
  final DateTime deviceTime;
  final DateTime? createdAt;
  final bool synced;

  const TelemetryEntity({
    required this.id,
    required this.haulerId,
    required this.cycleId,
    required this.lat,
    required this.lng,
    this.accuracy,
    required this.bodyUp,
    required this.deviceTime,
    this.createdAt,
    this.synced = false,
  });

  factory TelemetryEntity.create({
    required String id,
    required String haulerId,
    required String cycleId,
    required GeoLocation location,
    required bool bodyUp,
  }) {
    return TelemetryEntity(
      id: id,
      haulerId: haulerId,
      cycleId: cycleId,
      lat: location.lat,
      lng: location.lng,
      accuracy: location.accuracy,
      bodyUp: bodyUp,
      deviceTime: DateTime.now(),
      synced: false,
    );
  }

  GeoLocation get location => GeoLocation(
    lat: lat,
    lng: lng,
    accuracy: accuracy,
    timestamp: deviceTime,
  );

  @override
  List<Object?> get props => [
    id, haulerId, cycleId, lat, lng, accuracy, bodyUp, deviceTime, createdAt, synced
  ];

  @override
  String toString() => 'TelemetryEntity($haulerId, $lat, $lng)';
}



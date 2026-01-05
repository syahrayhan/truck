import '../../domain/entities/entities.dart';

/// Data model for Telemetry with JSON serialization
class TelemetryModel extends TelemetryEntity {
  const TelemetryModel({
    required super.id,
    required super.haulerId,
    required super.cycleId,
    required super.lat,
    required super.lng,
    super.accuracy,
    required super.bodyUp,
    required super.deviceTime,
    super.createdAt,
    super.synced,
  });

  factory TelemetryModel.fromMap(Map<String, dynamic> map, String docId) {
    return TelemetryModel(
      id: docId,
      haulerId: map['haulerId'] as String,
      cycleId: map['cycleId'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      accuracy: map['accuracy'] != null 
          ? (map['accuracy'] as num).toDouble() 
          : null,
      bodyUp: map['bodyUp'] as bool? ?? false,
      deviceTime: DateTime.parse(map['deviceTime'] as String),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      synced: map['synced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'haulerId': haulerId,
      'cycleId': cycleId,
      'lat': lat,
      'lng': lng,
      if (accuracy != null) 'accuracy': accuracy,
      'bodyUp': bodyUp,
      'deviceTime': deviceTime.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'synced': synced,
    };
  }

  factory TelemetryModel.fromEntity(TelemetryEntity entity) {
    return TelemetryModel(
      id: entity.id,
      haulerId: entity.haulerId,
      cycleId: entity.cycleId,
      lat: entity.lat,
      lng: entity.lng,
      accuracy: entity.accuracy,
      bodyUp: entity.bodyUp,
      deviceTime: entity.deviceTime,
      createdAt: entity.createdAt,
      synced: entity.synced,
    );
  }

  TelemetryEntity toEntity() {
    return TelemetryEntity(
      id: id,
      haulerId: haulerId,
      cycleId: cycleId,
      lat: lat,
      lng: lng,
      accuracy: accuracy,
      bodyUp: bodyUp,
      deviceTime: deviceTime,
      createdAt: createdAt,
      synced: synced,
    );
  }
}



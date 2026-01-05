import '../../domain/entities/geo_location.dart';

/// Data model for GeoLocation with JSON serialization
class GeoLocationModel extends GeoLocation {
  const GeoLocationModel({
    required super.lat,
    required super.lng,
    super.accuracy,
    super.timestamp,
  });

  factory GeoLocationModel.fromMap(Map<String, dynamic> map) {
    return GeoLocationModel(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      accuracy: map['accuracy'] != null 
          ? (map['accuracy'] as num).toDouble() 
          : null,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      if (accuracy != null) 'accuracy': accuracy,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  factory GeoLocationModel.fromEntity(GeoLocation entity) {
    return GeoLocationModel(
      lat: entity.lat,
      lng: entity.lng,
      accuracy: entity.accuracy,
      timestamp: entity.timestamp,
    );
  }

  GeoLocation toEntity() {
    return GeoLocation(
      lat: lat,
      lng: lng,
      accuracy: accuracy,
      timestamp: timestamp,
    );
  }
}



import '../../core/constants.dart';
import '../../domain/entities/entities.dart';
import 'geo_location_model.dart';

/// Data model for Loader with JSON serialization
class LoaderModel extends LoaderEntity {
  const LoaderModel({
    required super.id,
    required super.name,
    required super.location,
    super.waitingTruck,
    super.status,
    super.radius,
  });

  factory LoaderModel.fromMap(Map<String, dynamic> map, String docId) {
    // Support both 'radius' and 'radiusMeters' from loader_keruk app
    final radiusValue = (map['radiusMeters'] as num?)?.toDouble() 
        ?? (map['radius'] as num?)?.toDouble() 
        ?? AppConstants.loaderRadius;
    
    return LoaderModel(
      id: docId,
      name: map['name'] as String? ?? 'Loader $docId',
      location: GeoLocationModel.fromMap(map['location'] as Map<String, dynamic>),
      waitingTruck: map['waitingTruck'] as bool? ?? false,
      status: LoaderStatus.fromString(map['status'] as String?),
      radius: radiusValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': GeoLocationModel.fromEntity(location).toMap(),
      'waitingTruck': waitingTruck,
      'status': status.toApiString(),
      'radiusMeters': radius,
    };
  }

  factory LoaderModel.fromEntity(LoaderEntity entity) {
    return LoaderModel(
      id: entity.id,
      name: entity.name,
      location: entity.location,
      waitingTruck: entity.waitingTruck,
      status: entity.status,
      radius: entity.radius,
    );
  }

  LoaderEntity toEntity() {
    return LoaderEntity(
      id: id,
      name: name,
      location: location,
      waitingTruck: waitingTruck,
      status: status,
      radius: radius,
    );
  }
}



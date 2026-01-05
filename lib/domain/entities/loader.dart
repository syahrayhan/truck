import 'package:equatable/equatable.dart';
import 'geo_location.dart';
import '../../core/constants.dart';

/// Loader status enum for operational states
/// Synchronized with loader_keruk app
enum LoaderStatus {
  idle,
  waiting,
  operating,
  maintenance,
  offline,
  unknown;

  static LoaderStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'IDLE':
      case 'STANDBY':
        return LoaderStatus.idle;
      case 'WAITING':
        return LoaderStatus.waiting;
      case 'OPERATING':
      case 'ACTIVE':
        return LoaderStatus.operating;
      case 'MAINTENANCE':
      case 'MAINT':
        return LoaderStatus.maintenance;
      case 'OFFLINE':
        return LoaderStatus.offline;
      default:
        return LoaderStatus.unknown;
    }
  }

  String toApiString() {
    switch (this) {
      case LoaderStatus.idle:
        return 'IDLE';
      case LoaderStatus.waiting:
        return 'WAITING';
      case LoaderStatus.operating:
        return 'OPERATING';
      case LoaderStatus.maintenance:
        return 'MAINTENANCE';
      case LoaderStatus.offline:
        return 'OFFLINE';
      case LoaderStatus.unknown:
        return 'UNKNOWN';
    }
  }

  String get displayName {
    switch (this) {
      case LoaderStatus.idle:
        return 'Idle';
      case LoaderStatus.waiting:
        return 'Waiting';
      case LoaderStatus.operating:
        return 'Operating';
      case LoaderStatus.maintenance:
        return 'Maintenance';
      case LoaderStatus.offline:
        return 'Offline';
      case LoaderStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Domain entity for Loader
class LoaderEntity extends Equatable {
  final String id;
  final String name;
  final GeoLocation location;
  final bool waitingTruck;
  final LoaderStatus status;
  final double radius;

  const LoaderEntity({
    required this.id,
    required this.name,
    required this.location,
    this.waitingTruck = false,
    this.status = LoaderStatus.idle,
    this.radius = AppConstants.loaderRadius,
  });

  LoaderEntity copyWith({
    String? id,
    String? name,
    GeoLocation? location,
    bool? waitingTruck,
    LoaderStatus? status,
    double? radius,
  }) {
    return LoaderEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      waitingTruck: waitingTruck ?? this.waitingTruck,
      status: status ?? this.status,
      radius: radius ?? this.radius,
    );
  }

  @override
  List<Object?> get props => [id, name, location, waitingTruck, status, radius];
}



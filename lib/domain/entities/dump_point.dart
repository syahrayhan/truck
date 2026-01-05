import 'package:equatable/equatable.dart';
import 'geo_location.dart';
import '../../core/constants.dart';

/// Domain entity for Dump Point
class DumpPointEntity extends Equatable {
  final String id;
  final String name;
  final GeoLocation location;
  final double radius;
  final bool active;

  const DumpPointEntity({
    required this.id,
    required this.name,
    required this.location,
    this.radius = AppConstants.dumpPointRadius,
    this.active = true,
  });

  DumpPointEntity copyWith({
    String? id,
    String? name,
    GeoLocation? location,
    double? radius,
    bool? active,
  }) {
    return DumpPointEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [id, name, location, radius, active];
}



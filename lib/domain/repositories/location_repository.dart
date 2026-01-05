import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/entities.dart';

/// Abstract repository for Location operations
abstract class LocationRepository {
  /// Initialize location service and request permissions
  Future<Either<Failure, bool>> initialize();

  /// Get current location
  Future<Either<Failure, GeoLocation>> getCurrentLocation();

  /// Stream location updates
  Stream<GeoLocation> get locationStream;

  /// Get last known location
  GeoLocation? get lastLocation;

  /// Start continuous tracking
  Future<Either<Failure, void>> startTracking();

  /// Stop tracking
  Future<Either<Failure, void>> stopTracking();

  /// Check if location is within radius
  bool isWithinRadius(GeoLocation? location, GeoLocation center, double radius);

  /// Check if GPS accuracy is acceptable
  bool hasAcceptableAccuracy(GeoLocation? location);
}



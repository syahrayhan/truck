import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/location_repository.dart';

/// Implementation of LocationRepository
class LocationRepositoryImpl implements LocationRepository {
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<GeoLocation> _locationController = 
      StreamController<GeoLocation>.broadcast();
  
  GeoLocation? _lastLocation;
  bool _isTracking = false;

  @override
  Future<Either<Failure, bool>> initialize() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(LocationFailure(
          message: 'Location services are disabled',
        ));
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left(LocationFailure(
            message: 'Location permission denied',
          ));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left(LocationFailure(
          message: 'Location permission permanently denied',
        ));
      }

      return const Right(true);
    } catch (e) {
      return Left(LocationFailure(message: 'Failed to initialize location: $e'));
    }
  }

  @override
  Future<Either<Failure, GeoLocation>> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastLocation = GeoLocation(
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );

      return Right(_lastLocation!);
    } catch (e) {
      return Left(LocationFailure(message: 'Failed to get location: $e'));
    }
  }

  @override
  Stream<GeoLocation> get locationStream => _locationController.stream;

  @override
  GeoLocation? get lastLocation => _lastLocation;

  @override
  Future<Either<Failure, void>> startTracking() async {
    if (_isTracking) return const Right(null);

    final initResult = await initialize();
    if (initResult.isLeft()) {
      return initResult.fold(
        (failure) => Left(failure),
        (_) => const Right(null),
      );
    }

    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _lastLocation = GeoLocation(
          lat: position.latitude,
          lng: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        );
        _locationController.add(_lastLocation!);
      },
      onError: (error) {
        // Handle location errors
      },
    );

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> stopTracking() async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    return const Right(null);
  }

  @override
  bool isWithinRadius(GeoLocation? location, GeoLocation center, double radius) {
    if (location == null) return false;
    final distance = Geolocator.distanceBetween(
      location.lat,
      location.lng,
      center.lat,
      center.lng,
    );
    return distance <= radius;
  }

  @override
  bool hasAcceptableAccuracy(GeoLocation? location) {
    if (location == null) return false;
    return location.accuracy == null || 
           location.accuracy! <= AppConstants.gpsAccuracyThreshold;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}



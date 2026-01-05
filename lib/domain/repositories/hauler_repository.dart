import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/entities.dart';

/// Abstract repository for Hauler operations
abstract class HaulerRepository {
  /// Get or create hauler by ID
  Future<Either<Failure, HaulerEntity>> getOrCreateHauler(String haulerId);

  /// Stream hauler updates
  Stream<HaulerEntity?> streamHauler(String haulerId);

  /// Update hauler data
  Future<Either<Failure, void>> updateHauler(String haulerId, Map<String, dynamic> data);

  /// Update hauler location
  Future<Either<Failure, void>> updateLocation(String haulerId, GeoLocation location);

  /// Update body up/down status
  Future<Either<Failure, void>> updateBodyUp(String haulerId, bool bodyUp);

  /// Save hauler event
  Future<Either<Failure, void>> saveEvent(HaulerEventEntity event);

  /// Stream events for a cycle
  Stream<List<HaulerEventEntity>> streamCycleEvents(String cycleId);

  /// Save telemetry data
  Future<Either<Failure, void>> saveTelemetry(TelemetryEntity telemetry);
}



import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/hauler_repository.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../datasources/datasources.dart';
import '../models/models.dart';

/// Implementation of HaulerRepository with offline-first pattern
class HaulerRepositoryImpl implements HaulerRepository {
  final FirestoreDataSource remoteDataSource;
  final OfflineQueueDataSource offlineQueue;
  final ConnectivityRepository connectivityRepository;

  HaulerRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineQueue,
    required this.connectivityRepository,
  });

  @override
  Future<Either<Failure, HaulerEntity>> getOrCreateHauler(String haulerId) async {
    try {
      var hauler = await remoteDataSource.getHauler(haulerId);
      
      if (hauler == null) {
        hauler = HaulerModel.initial(haulerId);
        await remoteDataSource.createHauler(hauler);
      }
      
      return Right(hauler.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get hauler: $e'));
    }
  }

  @override
  Stream<HaulerEntity?> streamHauler(String haulerId) {
    return remoteDataSource.streamHauler(haulerId).map(
      (model) => model?.toEntity(),
    );
  }

  @override
  Future<Either<Failure, void>> updateHauler(String haulerId, Map<String, dynamic> data) async {
    // Offline-first: Save to local queue first (always)
    final queueKey = await offlineQueue.enqueue(QueueItemData.create(
      id: haulerId,
      type: QueueItemType.haulerUpdate,
      data: {'haulerId': haulerId, 'update': data},
    ));

    // Try sync to remote in background (if online)
    if (connectivityRepository.isOnline) {
      _syncInBackground(() async {
        try {
          await remoteDataSource.updateHauler(haulerId, data);
          // Remove from queue after successful sync
          await offlineQueue.remove(queueKey);
        } catch (e) {
          // Keep in queue, will be synced later by ConnectivityRepository
        }
      });
    }

    // Always return success (optimistic update)
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateLocation(String haulerId, GeoLocation location) async {
    return updateHauler(haulerId, {
      'location': GeoLocationModel.fromEntity(location).toMap(),
      'online': true,
    });
  }

  @override
  Future<Either<Failure, void>> updateBodyUp(String haulerId, bool bodyUp) async {
    return updateHauler(haulerId, {'bodyUp': bodyUp});
  }

  @override
  Future<Either<Failure, void>> saveEvent(HaulerEventEntity event) async {
    // Offline-first: Save to local queue first (always)
    final queueKey = await offlineQueue.enqueue(QueueItemData.create(
      id: event.id,
      type: QueueItemType.event,
      data: HaulerEventModel.fromEntity(event).toMap(),
    ));

    // Try sync to remote in background (if online)
    if (connectivityRepository.isOnline) {
      _syncInBackground(() async {
        try {
          await remoteDataSource.saveEvent(HaulerEventModel.fromEntity(event));
          // Remove from queue after successful sync
          await offlineQueue.remove(queueKey);
        } catch (e) {
          // Keep in queue, will be synced later by ConnectivityRepository
        }
      });
    }

    // Always return success (optimistic update)
    return const Right(null);
  }

  @override
  Stream<List<HaulerEventEntity>> streamCycleEvents(String cycleId) {
    return remoteDataSource.streamCycleEvents(cycleId).map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<Either<Failure, void>> saveTelemetry(TelemetryEntity telemetry) async {
    // Offline-first: Save to local queue first (always)
    final queueKey = await offlineQueue.enqueue(QueueItemData.create(
      id: telemetry.id,
      type: QueueItemType.telemetry,
      data: TelemetryModel.fromEntity(telemetry).toMap(),
    ));

    // Try sync to remote in background (if online)
    if (connectivityRepository.isOnline) {
      _syncInBackground(() async {
        try {
          await remoteDataSource.saveTelemetry(TelemetryModel.fromEntity(telemetry));
          // Remove from queue after successful sync
          await offlineQueue.remove(queueKey);
        } catch (e) {
          // Keep in queue, will be synced later by ConnectivityRepository
        }
      });
    }

    // Always return success (optimistic update)
    return const Right(null);
  }

  /// Helper method to sync in background without blocking
  void _syncInBackground(Future<void> Function() syncFunction) {
    // Fire and forget - don't await to avoid blocking
    syncFunction().catchError((_) {
      // Errors are handled in syncFunction
    });
  }
}



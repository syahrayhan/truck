import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/cycle_repository.dart';
import '../datasources/datasources.dart';
import '../models/models.dart';

/// Implementation of CycleRepository
class CycleRepositoryImpl implements CycleRepository {
  final FirestoreDataSource remoteDataSource;

  CycleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> createCycle(CycleEntity cycle) async {
    try {
      await remoteDataSource.createCycle(CycleModel.fromEntity(cycle));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create cycle: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCycle(CycleEntity cycle) async {
    try {
      await remoteDataSource.updateCycle(CycleModel.fromEntity(cycle));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update cycle: $e'));
    }
  }

  @override
  Future<Either<Failure, CycleEntity?>> getCycle(String cycleId) async {
    try {
      final model = await remoteDataSource.getCycle(cycleId);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get cycle: $e'));
    }
  }

  @override
  Stream<CycleEntity?> streamCurrentCycle(String haulerId) {
    return remoteDataSource.streamCurrentCycle(haulerId).map(
      (model) => model?.toEntity(),
    );
  }
}



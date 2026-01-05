import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/loader_repository.dart';
import '../datasources/datasources.dart';

/// Implementation of LoaderRepository
class LoaderRepositoryImpl implements LoaderRepository {
  final FirestoreDataSource remoteDataSource;

  LoaderRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<LoaderEntity>> streamLoaders() {
    return remoteDataSource.streamLoaders().map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<Either<Failure, LoaderEntity?>> getLoader(String loaderId) async {
    try {
      final model = await remoteDataSource.getLoader(loaderId);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get loader: $e'));
    }
  }
}



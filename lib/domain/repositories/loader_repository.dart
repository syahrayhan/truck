import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/entities.dart';

/// Abstract repository for Loader operations
abstract class LoaderRepository {
  /// Stream all loaders
  Stream<List<LoaderEntity>> streamLoaders();

  /// Get loader by ID
  Future<Either<Failure, LoaderEntity?>> getLoader(String loaderId);
}



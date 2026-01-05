import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/entities.dart';

/// Abstract repository for Cycle operations
abstract class CycleRepository {
  /// Create a new cycle
  Future<Either<Failure, void>> createCycle(CycleEntity cycle);

  /// Update cycle
  Future<Either<Failure, void>> updateCycle(CycleEntity cycle);

  /// Get cycle by ID
  Future<Either<Failure, CycleEntity?>> getCycle(String cycleId);

  /// Stream current cycle for hauler
  Stream<CycleEntity?> streamCurrentCycle(String haulerId);
}



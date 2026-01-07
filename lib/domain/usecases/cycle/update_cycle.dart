import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/cycle_repository.dart';

/// Use case to update cycle
class UpdateCycle implements UseCase<void, UpdateCycleParams> {
  final CycleRepository repository;

  UpdateCycle(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateCycleParams params) {
    return repository.updateCycle(params.cycle);
  }
}

class UpdateCycleParams extends Equatable {
  final CycleEntity cycle;

  const UpdateCycleParams({required this.cycle});

  @override
  List<Object?> get props => [cycle];
}


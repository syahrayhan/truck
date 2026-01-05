import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/cycle_repository.dart';

/// Use case to complete a cycle
class CompleteCycle implements UseCase<CycleEntity, CompleteCycleParams> {
  final CycleRepository repository;

  CompleteCycle(this.repository);

  @override
  Future<Either<Failure, CycleEntity>> call(CompleteCycleParams params) async {
    final completedCycle = params.cycle.complete();
    
    final result = await repository.updateCycle(completedCycle);
    return result.fold(
      (failure) => Left(failure),
      (_) => Right(completedCycle),
    );
  }
}

class CompleteCycleParams extends Equatable {
  final CycleEntity cycle;

  const CompleteCycleParams({required this.cycle});

  @override
  List<Object?> get props => [cycle];
}



import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/cycle_repository.dart';

/// Use case to start a new cycle
class StartCycle implements UseCase<CycleEntity, StartCycleParams> {
  final CycleRepository repository;

  StartCycle(this.repository);

  @override
  Future<Either<Failure, CycleEntity>> call(StartCycleParams params) async {
    final cycle = CycleEntity.start(
      id: params.cycleId,
      haulerId: params.haulerId,
      loaderId: params.loaderId,
      loaderLocation: params.loaderLocation,
      dumpLocation: params.dumpLocation,
    );

    final result = await repository.createCycle(cycle);
    return result.fold(
      (failure) => Left(failure),
      (_) => Right(cycle),
    );
  }
}

class StartCycleParams extends Equatable {
  final String cycleId;
  final String haulerId;
  final String? loaderId;
  final GeoLocation? loaderLocation;
  final GeoLocation? dumpLocation;

  const StartCycleParams({
    required this.cycleId,
    required this.haulerId,
    this.loaderId,
    this.loaderLocation,
    this.dumpLocation,
  });

  @override
  List<Object?> get props => [cycleId, haulerId, loaderId, loaderLocation, dumpLocation];
}



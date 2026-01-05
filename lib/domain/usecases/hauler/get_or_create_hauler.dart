import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/hauler_repository.dart';

/// Use case to get or create a hauler
class GetOrCreateHauler implements UseCase<HaulerEntity, GetOrCreateHaulerParams> {
  final HaulerRepository repository;

  GetOrCreateHauler(this.repository);

  @override
  Future<Either<Failure, HaulerEntity>> call(GetOrCreateHaulerParams params) {
    return repository.getOrCreateHauler(params.haulerId);
  }
}

class GetOrCreateHaulerParams extends Equatable {
  final String haulerId;

  const GetOrCreateHaulerParams({required this.haulerId});

  @override
  List<Object?> get props => [haulerId];
}



import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/hauler_repository.dart';

/// Use case to update body up/down status
class UpdateBodyUp implements UseCase<void, UpdateBodyUpParams> {
  final HaulerRepository repository;

  UpdateBodyUp(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateBodyUpParams params) {
    return repository.updateBodyUp(params.haulerId, params.bodyUp);
  }
}

class UpdateBodyUpParams extends Equatable {
  final String haulerId;
  final bool bodyUp;

  const UpdateBodyUpParams({
    required this.haulerId,
    required this.bodyUp,
  });

  @override
  List<Object?> get props => [haulerId, bodyUp];
}



import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/hauler_repository.dart';

/// Use case to update hauler data
class UpdateHauler implements UseCase<void, UpdateHaulerParams> {
  final HaulerRepository repository;

  UpdateHauler(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateHaulerParams params) {
    return repository.updateHauler(params.haulerId, params.data);
  }
}

class UpdateHaulerParams extends Equatable {
  final String haulerId;
  final Map<String, dynamic> data;

  const UpdateHaulerParams({
    required this.haulerId,
    required this.data,
  });

  @override
  List<Object?> get props => [haulerId, data];
}


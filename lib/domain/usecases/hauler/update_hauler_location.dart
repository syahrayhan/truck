import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/hauler_repository.dart';

/// Use case to update hauler location
class UpdateHaulerLocation implements UseCase<void, UpdateHaulerLocationParams> {
  final HaulerRepository repository;

  UpdateHaulerLocation(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateHaulerLocationParams params) {
    return repository.updateLocation(params.haulerId, params.location);
  }
}

class UpdateHaulerLocationParams extends Equatable {
  final String haulerId;
  final GeoLocation location;

  const UpdateHaulerLocationParams({
    required this.haulerId,
    required this.location,
  });

  @override
  List<Object?> get props => [haulerId, location];
}



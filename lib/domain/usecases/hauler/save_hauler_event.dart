import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/hauler_repository.dart';

/// Use case to save hauler event
class SaveHaulerEvent implements UseCase<void, SaveHaulerEventParams> {
  final HaulerRepository repository;

  SaveHaulerEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveHaulerEventParams params) {
    return repository.saveEvent(params.event);
  }
}

class SaveHaulerEventParams extends Equatable {
  final HaulerEventEntity event;

  const SaveHaulerEventParams({required this.event});

  @override
  List<Object?> get props => [event];
}


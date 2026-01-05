import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base use case interface
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}



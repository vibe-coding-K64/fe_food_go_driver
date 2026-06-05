import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class LogoutUseCase {
  Future<Either<Failure, void>> call();
}

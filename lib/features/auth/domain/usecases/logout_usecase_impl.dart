import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

class LogoutUseCaseImpl {
  final AuthRepository _authRepository;

  LogoutUseCaseImpl(this._authRepository);

  Future<Either<Failure, void>> call() {
    return _authRepository.logout();
  }
}

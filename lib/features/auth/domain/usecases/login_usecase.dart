import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_response.dart';

class LoginUseCase {
  final Future<Either<Failure, AuthResponse>> Function(String, String) _loginFn;

  LoginUseCase(this._loginFn);

  Future<Either<Failure, AuthResponse>> call(String email, String password) {
    return _loginFn(email, password);
  }
}

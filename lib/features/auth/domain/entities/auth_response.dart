import 'package:equatable/equatable.dart';
import 'auth_user.dart';

class AuthResponse extends Equatable {
  final String? token;
  final String? refreshToken;
  final int? expiresIn;
  final AuthUser? user;

  const AuthResponse({
    this.token,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });

  @override
  List<Object?> get props => [token, refreshToken, expiresIn, user];
}

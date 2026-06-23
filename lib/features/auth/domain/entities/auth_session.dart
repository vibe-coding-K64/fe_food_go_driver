import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  final String token;
  final String refreshToken;
  final int expiresIn;
  final String userId;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? photoUrl;

  const AuthSession({
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
    required this.userId,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.photoUrl,
  });

  bool get isValid => token.isNotEmpty && userId.isNotEmpty;

  @override
  List<Object?> get props => [
        token, refreshToken, expiresIn, userId,
        email, fullName, phoneNumber, photoUrl,
      ];
}

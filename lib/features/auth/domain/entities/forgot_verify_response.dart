import 'package:equatable/equatable.dart';

class ForgotVerifyResponse extends Equatable {
  final String tempToken;
  final int expiresIn;
  final String message;

  const ForgotVerifyResponse({
    required this.tempToken,
    required this.expiresIn,
    required this.message,
  });

  @override
  List<Object?> get props => [tempToken, expiresIn, message];
}

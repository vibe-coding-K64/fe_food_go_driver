import 'package:equatable/equatable.dart';

class ForgotOtpResponse extends Equatable {
  final String emailOrPhone;
  final String message;
  final int expiresInSeconds;

  const ForgotOtpResponse({
    required this.emailOrPhone,
    required this.message,
    required this.expiresInSeconds,
  });

  @override
  List<Object?> get props => [emailOrPhone, message, expiresInSeconds];
}

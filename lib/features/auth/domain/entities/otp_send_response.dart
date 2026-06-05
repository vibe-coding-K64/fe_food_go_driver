import 'package:equatable/equatable.dart';

class OtpSendResponse extends Equatable {
  final String emailOrPhone;
  final String otpCode;
  final int expiresInSeconds;
  final String message;

  const OtpSendResponse({
    required this.emailOrPhone,
    required this.otpCode,
    required this.expiresInSeconds,
    required this.message,
  });

  @override
  List<Object?> get props => [emailOrPhone, otpCode, expiresInSeconds, message];
}

import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

class RegisterFormSubmitted extends RegisterEvent {
  final String email;
  final String phoneNumber;
  final String password;
  final String fullName;

  const RegisterFormSubmitted({
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, phoneNumber, password, fullName];
}

class OtpSubmitted extends RegisterEvent {
  final String email;
  final String otpCode;

  const OtpSubmitted({
    required this.email,
    required this.otpCode,
  });

  @override
  List<Object?> get props => [email, otpCode];
}

class RegisterReset extends RegisterEvent {
  const RegisterReset();
}

class OtpResendRequested extends RegisterEvent {
  final String email;
  final String phoneNumber;
  final String password;
  final String fullName;

  const OtpResendRequested({
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, phoneNumber, password, fullName];
}

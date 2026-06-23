import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_user.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class OtpSent extends RegisterState {
  final String email;

  const OtpSent({required this.email});

  @override
  List<Object?> get props => [email];
}

class OtpVerifying extends RegisterState {
  final String email;

  const OtpVerifying({required this.email});

  @override
  List<Object?> get props => [email];
}

class RegisterSuccess extends RegisterState {
  final AuthUser user;

  const RegisterSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class RegisterFailure extends RegisterState {
  final String message;
  final String? email;
  final String? phone;
  final String? password;
  final String? fullName;

  const RegisterFailure({
    required this.message,
    this.email,
    this.phone,
    this.password,
    this.fullName,
  });

  @override
  List<Object?> get props => [message, email, phone, password, fullName];
}

class OtpFailure extends RegisterState {
  final String message;
  final String email;

  const OtpFailure({
    required this.message,
    required this.email,
  });

  @override
  List<Object?> get props => [message, email];
}

class OtpResending extends RegisterState {
  final String email;

  const OtpResending({required this.email});

  @override
  List<Object?> get props => [email];
}

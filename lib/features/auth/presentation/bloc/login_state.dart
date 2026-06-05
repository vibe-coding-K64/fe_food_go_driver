import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_user.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final AuthUser user;

  const LoginSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class SessionChecked extends LoginState {
  final AuthUser? user;

  const SessionChecked(this.user);

  @override
  List<Object?> get props => [user];
}

class SessionValidating extends LoginState {
  const SessionValidating();
}

class SessionValid extends LoginState {
  final AuthUser user;

  const SessionValid(this.user);

  @override
  List<Object?> get props => [user];
}

class SessionInvalid extends LoginState {
  final String message;

  const SessionInvalid(this.message);

  @override
  List<Object?> get props => [message];
}

part of 'forgot_password_bloc.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordSendOtpEvent extends ForgotPasswordEvent {
  final String emailOrPhone;

  const ForgotPasswordSendOtpEvent({required this.emailOrPhone});

  @override
  List<Object?> get props => [emailOrPhone];
}

class ForgotPasswordVerifyOtpEvent extends ForgotPasswordEvent {
  final String emailOrPhone;
  final String otpCode;

  const ForgotPasswordVerifyOtpEvent({
    required this.emailOrPhone,
    required this.otpCode,
  });

  @override
  List<Object?> get props => [emailOrPhone, otpCode];
}

class ForgotPasswordResetEvent extends ForgotPasswordEvent {
  final String tempToken;
  final String newPassword;

  const ForgotPasswordResetEvent({
    required this.tempToken,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [tempToken, newPassword];
}

class ForgotPasswordResendOtpEvent extends ForgotPasswordEvent {
  final String emailOrPhone;

  const ForgotPasswordResendOtpEvent({required this.emailOrPhone});

  @override
  List<Object?> get props => [emailOrPhone];
}

class ForgotPasswordCountdownTickEvent extends ForgotPasswordEvent {
  const ForgotPasswordCountdownTickEvent();
}

class ForgotPasswordResetAllEvent extends ForgotPasswordEvent {
  const ForgotPasswordResetAllEvent();
}

part of 'forgot_password_bloc.dart';

enum ForgotPasswordStep {
  inputEmail,
  inputOtp,
  inputNewPassword,
}

abstract class ForgotPasswordState extends Equatable {
  final ForgotPasswordStep currentStep;
  final String emailOrPhone;
  final String? tempToken;
  final int countdownSeconds;
  final bool canResend;

  const ForgotPasswordState({
    this.currentStep = ForgotPasswordStep.inputEmail,
    this.emailOrPhone = '',
    this.tempToken,
    this.countdownSeconds = 300,
    this.canResend = false,
  });

  @override
  List<Object?> get props => [
        currentStep,
        emailOrPhone,
        tempToken,
        countdownSeconds,
        canResend,
      ];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial() : super();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading({
    required super.currentStep,
    required super.emailOrPhone,
    super.tempToken,
    super.countdownSeconds,
    super.canResend,
  });
}

class ForgotPasswordOtpSent extends ForgotPasswordState {
  const ForgotPasswordOtpSent({
    required super.emailOrPhone,
    required super.countdownSeconds,
    super.canResend,
  }) : super(currentStep: ForgotPasswordStep.inputOtp);
}

class ForgotPasswordOtpVerified extends ForgotPasswordState {
  const ForgotPasswordOtpVerified({
    required super.emailOrPhone,
    required super.tempToken,
  }) : super(currentStep: ForgotPasswordStep.inputNewPassword);
}

class ForgotPasswordResetSuccess extends ForgotPasswordState {
  const ForgotPasswordResetSuccess() : super();
}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;

  const ForgotPasswordError({
    required this.message,
    required super.currentStep,
    required super.emailOrPhone,
    super.tempToken,
    super.countdownSeconds,
    super.canResend,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        message,
      ];
}

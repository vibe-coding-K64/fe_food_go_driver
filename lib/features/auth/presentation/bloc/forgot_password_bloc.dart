import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository _authRepository;
  Timer? _countdownTimer;

  ForgotPasswordBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const ForgotPasswordInitial()) {
    on<ForgotPasswordSendOtpEvent>(_onSendOtp);
    on<ForgotPasswordVerifyOtpEvent>(_onVerifyOtp);
    on<ForgotPasswordResetEvent>(_onResetPassword);
    on<ForgotPasswordResendOtpEvent>(_onResendOtp);
    on<ForgotPasswordCountdownTickEvent>(_onCountdownTick);
    on<ForgotPasswordResetAllEvent>(_onResetAll);
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const ForgotPasswordCountdownTickEvent()),
    );
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _onSendOtp(
    ForgotPasswordSendOtpEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading(
      currentStep: ForgotPasswordStep.inputEmail,
      emailOrPhone: event.emailOrPhone,
    ));

    final result = await _authRepository.sendForgotOtp(event.emailOrPhone);

    result.fold(
      (failure) {
        emit(ForgotPasswordError(
          message: failure.message,
          currentStep: ForgotPasswordStep.inputEmail,
          emailOrPhone: event.emailOrPhone,
        ));
      },
      (response) {
        final seconds = response.expiresInSeconds;
        _startCountdown(seconds);
        emit(ForgotPasswordOtpSent(
          emailOrPhone: event.emailOrPhone,
          countdownSeconds: seconds,
          canResend: false,
        ));
      },
    );
  }

  Future<void> _onVerifyOtp(
    ForgotPasswordVerifyOtpEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading(
      currentStep: ForgotPasswordStep.inputOtp,
      emailOrPhone: event.emailOrPhone,
    ));

    final result = await _authRepository.verifyForgotOtp(
      emailOrPhone: event.emailOrPhone,
      otpCode: event.otpCode,
    );

    result.fold(
      (failure) {
        emit(ForgotPasswordError(
          message: failure.message,
          currentStep: ForgotPasswordStep.inputOtp,
          emailOrPhone: event.emailOrPhone,
          canResend: state.canResend,
          countdownSeconds: state.countdownSeconds,
        ));
      },
      (response) {
        _stopCountdown();
        emit(ForgotPasswordOtpVerified(
          emailOrPhone: event.emailOrPhone,
          tempToken: response.tempToken,
        ));
      },
    );
  }

  Future<void> _onResetPassword(
    ForgotPasswordResetEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading(
      currentStep: ForgotPasswordStep.inputNewPassword,
      emailOrPhone: state.emailOrPhone,
      tempToken: event.tempToken,
    ));

    final result = await _authRepository.resetPassword(
      tempToken: event.tempToken,
      newPassword: event.newPassword,
    );

    result.fold(
      (failure) {
        emit(ForgotPasswordError(
          message: failure.message,
          currentStep: ForgotPasswordStep.inputNewPassword,
          emailOrPhone: state.emailOrPhone,
          tempToken: event.tempToken,
        ));
      },
      (_) {
        _stopCountdown();
        emit(const ForgotPasswordResetSuccess());
      },
    );
  }

  Future<void> _onResendOtp(
    ForgotPasswordResendOtpEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading(
      currentStep: ForgotPasswordStep.inputOtp,
      emailOrPhone: event.emailOrPhone,
      canResend: false,
    ));

    final result = await _authRepository.sendForgotOtp(event.emailOrPhone);

    result.fold(
      (failure) {
        emit(ForgotPasswordError(
          message: failure.message,
          currentStep: ForgotPasswordStep.inputOtp,
          emailOrPhone: event.emailOrPhone,
          canResend: state.canResend,
          countdownSeconds: state.countdownSeconds,
        ));
      },
      (response) {
        _startCountdown(response.expiresInSeconds);
        emit(ForgotPasswordOtpSent(
          emailOrPhone: event.emailOrPhone,
          countdownSeconds: response.expiresInSeconds,
          canResend: false,
        ));
      },
    );
  }

  void _onCountdownTick(
    ForgotPasswordCountdownTickEvent event,
    Emitter<ForgotPasswordState> emit,
  ) {
    if (state.countdownSeconds <= 1) {
      _stopCountdown();
      if (state is ForgotPasswordOtpSent) {
        emit(ForgotPasswordOtpSent(
          emailOrPhone: state.emailOrPhone,
          countdownSeconds: 0,
          canResend: true,
        ));
      }
    } else {
      if (state is ForgotPasswordOtpSent) {
        emit(ForgotPasswordOtpSent(
          emailOrPhone: state.emailOrPhone,
          countdownSeconds: state.countdownSeconds - 1,
          canResend: state.canResend,
        ));
      }
    }
  }

  void _onResetAll(
    ForgotPasswordResetAllEvent event,
    Emitter<ForgotPasswordState> emit,
  ) {
    _stopCountdown();
    emit(const ForgotPasswordInitial());
  }

  @override
  Future<void> close() {
    _stopCountdown();
    return super.close();
  }
}

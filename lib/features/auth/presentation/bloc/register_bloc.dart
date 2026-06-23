import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const RegisterInitial()) {
    on<RegisterFormSubmitted>(_onRegisterFormSubmitted);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<RegisterReset>(_onRegisterReset);
    on<OtpResendRequested>(_onOtpResendRequested);
  }

  Future<void> _onRegisterFormSubmitted(
    RegisterFormSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterLoading());

    final result = await _authRepository.sendRegisterOtp(
      email: event.email,
      phoneNumber: event.phoneNumber,
      password: event.password,
      fullName: event.fullName,
    );

    result.fold(
      (failure) => emit(RegisterFailure(
        message: failure.message,
        email: event.email,
        phone: event.phoneNumber,
        password: event.password,
        fullName: event.fullName,
      )),
      (_) => emit(OtpSent(email: event.email)),
    );
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(OtpVerifying(email: event.email));

    final result = await _authRepository.completeRegistration(
      email: event.email,
      otpCode: event.otpCode,
    );

    result.fold(
      (failure) => emit(OtpFailure(
        message: failure.message,
        email: event.email,
      )),
      (authResponse) {
        final user = authResponse.user;
        if (user == null || (user.id?.isEmpty ?? true)) {
          emit(OtpFailure(
            message: 'Invalid response: missing user data',
            email: event.email,
          ));
        } else {
          emit(RegisterSuccess(user: user));
        }
      },
    );
  }

  void _onRegisterReset(
    RegisterReset event,
    Emitter<RegisterState> emit,
  ) {
    emit(const RegisterInitial());
  }

  Future<void> _onOtpResendRequested(
    OtpResendRequested event,
    Emitter<RegisterState> emit,
  ) async {
    emit(OtpResending(email: event.email));

    final result = await _authRepository.sendRegisterOtp(
      email: event.email,
      phoneNumber: event.phoneNumber,
      password: event.password,
      fullName: event.fullName,
    );

    result.fold(
      (failure) => emit(RegisterFailure(
        message: failure.message,
        email: event.email,
        phone: event.phoneNumber,
        password: event.password,
        fullName: event.fullName,
      )),
      (_) => emit(OtpSent(email: event.email)),
    );
  }
}

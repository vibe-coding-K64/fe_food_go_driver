import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;
  final LoginUseCase _loginUseCase;

  LoginBloc({
    required AuthRepository authRepository,
    required LoginUseCase loginUseCase,
  })  : _authRepository = authRepository,
        _loginUseCase = loginUseCase,
        super(const LoginInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LoginReset>(_onLoginReset);
    on<CheckSessionRequested>(_onCheckSessionRequested);
    on<LogoutRequested>(_onLogoutRequested);

    add(const CheckSessionRequested());
  }

  Future<void> _onCheckSessionRequested(
    CheckSessionRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const SessionValidating());

    final session = await _authRepository.getStoredSession();
    if (session == null) {
      emit(const SessionInvalid('Không có phiên đăng nhập. Vui lòng đăng nhập.'));
      return;
    }

    if (session.refreshToken.isEmpty) {
      emit(const SessionInvalid('Phiên hết hạn. Vui lòng đăng nhập lại.'));
      return;
    }

    final refreshResult = await _authRepository.refreshToken(session.refreshToken);
    await refreshResult.fold(
      (failure) async {
        emit(SessionInvalid(failure.message));
      },
      (authResponse) async {
        final newToken = authResponse.token;
        if (newToken == null || newToken.isEmpty) {
          emit(const SessionInvalid('Token không hợp lệ. Vui lòng đăng nhập lại.'));
          return;
        }

        final userResult = await _authRepository.getCurrentUser(newToken);
        userResult.fold(
          (failure) {
            emit(SessionInvalid(failure.message));
          },
          (AuthUser user) {
            emit(SessionValid(user));
          },
        );
      },
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    final result = await _loginUseCase(event.email, event.password);

    await result.fold(
      (failure) async => emit(LoginFailure(failure.message)),
      (authResponse) async {
        final user = authResponse.user;
        if (user == null || (user.id?.isEmpty ?? true)) {
          emit(const LoginFailure('Invalid response: missing user data'));
          return;
        }

        emit(LoginSuccess(user));
      },
    );
  }

  void _onLoginReset(LoginReset event, Emitter<LoginState> emit) {
    emit(const LoginInitial());
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LoginState> emit,
  ) async {
    await _authRepository.logout();
    emit(const LoginInitial());
  }
}

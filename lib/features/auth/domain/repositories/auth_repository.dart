import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';
import '../entities/forgot_otp_response.dart';
import '../entities/forgot_reset_response.dart';
import '../entities/forgot_verify_response.dart';
import '../entities/otp_send_response.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login(String email, String password);

  Future<Either<Failure, void>> logout();

  Future<AuthSession?> getStoredSession();

  Future<Either<Failure, AuthResponse>> refreshToken(String refreshToken);

  Future<Either<Failure, AuthUser>> getCurrentUser(String token);


  Future<Either<Failure, OtpSendResponse>> sendRegisterOtp({
    required String email,
    required String phoneNumber,
    required String password,
    required String fullName,
  });

  Future<Either<Failure, AuthResponse>> completeRegistration({
    required String email,
    required String otpCode,
  });

  Future<Either<Failure, ForgotOtpResponse>> sendForgotOtp(String emailOrPhone);

  Future<Either<Failure, ForgotVerifyResponse>> verifyForgotOtp({
    required String emailOrPhone,
    required String otpCode,
  });

  Future<Either<Failure, ForgotResetResponse>> resetPassword({
    required String tempToken,
    required String newPassword,
  });
}

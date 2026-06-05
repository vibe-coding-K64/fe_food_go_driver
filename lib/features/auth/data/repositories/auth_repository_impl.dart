import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/forgot_otp_response.dart';
import '../../domain/entities/forgot_reset_response.dart';
import '../../domain/entities/forgot_verify_response.dart';
import '../../domain/entities/otp_send_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required FlutterSecureStorage secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

  @override
  Future<Either<Failure, AuthResponse>> login(
      String email, String password) async {
    try {
      final response = await _remoteDataSource.login(
        LoginRequest(email: email, password: password),
      );

      debugPrint('[AuthRepositoryImpl] login - success, saving tokens...');
      await _saveTokens(response.token, response.refreshToken ?? '', response.user?.id ?? '');
      debugPrint('[AuthRepositoryImpl] login - tokens saved');
      return Right(response);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Server error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _clearTokens();
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure('Failed to clear stored credentials'));
    }
  }

  @override
  Future<AuthSession?> getStoredSession() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.driverTokenKey);
      final refreshToken = await _secureStorage.read(key: AppConstants.driverRefreshTokenKey);
      final userId = await _secureStorage.read(key: AppConstants.driverIdKey);

      debugPrint('[AuthRepositoryImpl] getStoredSession - token: ${token != null ? "EXISTS(${token.length})" : "NULL"}, refreshToken: ${refreshToken != null ? "EXISTS(${refreshToken.length})" : "NULL"}, userId: ${userId ?? "NULL"}');

      if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
        debugPrint('[AuthRepositoryImpl] getStoredSession - returning null (missing token or userId)');
        return null;
      }

      return AuthSession(
        token: token,
        refreshToken: refreshToken ?? '',
        expiresIn: 0,
        userId: userId,
        email: '',
      );
    } catch (_) {
      debugPrint('[AuthRepositoryImpl] getStoredSession - exception, returning null');
      return null;
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> refreshToken(String refreshToken) async {
    if (refreshToken.isEmpty) {
      debugPrint('[AuthRepositoryImpl] refreshToken - empty refreshToken, returning failure');
      return const Left(AuthFailure('No refresh token available'));
    }
    debugPrint('[AuthRepositoryImpl] refreshToken - calling remoteDataSource.refreshToken');
    try {
      // Get existing userId to preserve it after refresh
      final existingUserId = await _secureStorage.read(key: AppConstants.driverIdKey);
      final response = await _remoteDataSource.refreshToken(refreshToken);
      debugPrint('[AuthRepositoryImpl] refreshToken - success, saving tokens...');
      await _saveTokens(response.token, response.refreshToken ?? '', existingUserId);
      debugPrint('[AuthRepositoryImpl] refreshToken - tokens saved');
      return Right(response);
    } on Failure catch (e) {
      debugPrint('[AuthRepositoryImpl] refreshToken - failure: ${e.message}');
      return Left(e);
    } catch (_) {
      debugPrint('[AuthRepositoryImpl] refreshToken - unexpected exception');
      return const Left(ServerFailure('Failed to refresh token'));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser(String token) async {
    debugPrint('[AuthRepositoryImpl] getCurrentUser - calling remoteDataSource.getCurrentUser');
    try {
      final user = await _remoteDataSource.getCurrentUser(token);
      debugPrint('[AuthRepositoryImpl] getCurrentUser - success');
      return Right(user);
    } on Failure catch (e) {
      debugPrint('[AuthRepositoryImpl] getCurrentUser - failure: ${e.message}');
      return Left(e);
    } catch (_) {
      debugPrint('[AuthRepositoryImpl] getCurrentUser - unexpected exception');
      return const Left(ServerFailure('Failed to get current user'));
    }
  }

  @override
  Future<Either<Failure, void>> registerFcmToken(String token, String fcmToken) async {
    debugPrint('[AuthRepositoryImpl] registerFcmToken - sending FCM token to backend');
    try {
      await _remoteDataSource.registerFcmToken(token, fcmToken);
      debugPrint('[AuthRepositoryImpl] registerFcmToken - success');
      return const Right(null);
    } on Failure catch (e) {
      debugPrint('[AuthRepositoryImpl] registerFcmToken - failure: ${e.message}');
      return Left(e);
    } catch (_) {
      debugPrint('[AuthRepositoryImpl] registerFcmToken - unexpected exception');
      return const Left(ServerFailure('Failed to register FCM token'));
    }
  }

  @override
  Future<Either<Failure, OtpSendResponse>> sendRegisterOtp({
    required String email,
    required String phoneNumber,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _remoteDataSource.sendRegisterOtp(
        RegisterRequest(
          email: email,
          phoneNumber: phoneNumber,
          password: password,
          fullName: fullName,
        ),
      );
      return Right(response);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Server error occurred'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> completeRegistration({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await _remoteDataSource.completeRegistration(
        email: email,
        otpCode: otpCode,
      );

      await _saveTokens(response.token, response.refreshToken ?? '', response.user?.id ?? '');
      return Right(response);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Server error occurred'));
    }
  }

  @override
  Future<Either<Failure, ForgotOtpResponse>> sendForgotOtp(String emailOrPhone) async {
    try {
      final response = await _remoteDataSource.sendForgotOtp(emailOrPhone);
      return Right(response);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Server error occurred'));
    }
  }

  @override
  Future<Either<Failure, ForgotVerifyResponse>> verifyForgotOtp({
    required String emailOrPhone,
    required String otpCode,
  }) async {
    try {
      final response = await _remoteDataSource.verifyForgotOtp(
        emailOrPhone: emailOrPhone,
        otpCode: otpCode,
      );
      return Right(response);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Server error occurred'));
    }
  }

  @override
  Future<Either<Failure, ForgotResetResponse>> resetPassword({
    required String tempToken,
    required String newPassword,
  }) async {
    try {
      final response = await _remoteDataSource.resetPassword(
        tempToken: tempToken,
        newPassword: newPassword,
      );
      return Right(response);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Server error occurred'));
    }
  }

  Future<void> _saveTokens(String? token, String? refreshToken, String? userId) async {
    await _secureStorage.write(key: AppConstants.driverTokenKey, value: token ?? '');
    await _secureStorage.write(key: AppConstants.driverRefreshTokenKey, value: refreshToken ?? '');
    // Only update userId if provided; preserve existing value otherwise
    if (userId != null && userId.isNotEmpty) {
      await _secureStorage.write(key: AppConstants.driverIdKey, value: userId);
    }
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: AppConstants.driverTokenKey);
    await _secureStorage.delete(key: AppConstants.driverRefreshTokenKey);
    await _secureStorage.delete(key: AppConstants.driverIdKey);
  }
}

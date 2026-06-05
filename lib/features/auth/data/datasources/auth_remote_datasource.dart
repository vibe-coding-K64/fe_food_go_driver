import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/auth_user.dart';
import '../models/auth_response.dart';
import '../models/forgot_otp_response.dart';
import '../models/forgot_otp_verify_response.dart';
import '../models/forgot_reset_response.dart';
import '../models/login_request.dart';
import '../models/otp_send_response.dart';
import '../models/register_request.dart';

String _extractMessage(dynamic body) {
  if (body is Map<String, dynamic>) {
    final msg = body['message'] ?? body['error'] ?? body['msg'];
    if (msg != null) return msg.toString();
  }
  if (body is String && body.isNotEmpty) return body;
  return 'Server error occurred';
}

Map<String, dynamic> _parseBody(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'message': body.isNotEmpty ? body : 'Server error occurred'};
  } catch (_) {
    return {'message': body.isNotEmpty ? body : 'Server error occurred'};
  }
}

class AuthRemoteDataSource {
  final http.Client _httpClient;
  final String _baseApiUrl;

  AuthRemoteDataSource({
    http.Client? httpClient,
    String? baseApiUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseApiUrl = baseApiUrl ?? AppConstants.baseApiUrl;

  void _log(String message) {
    debugPrint('[AuthRemoteDataSource] $message');
  }

  Failure _mapHttpResponse(http.Response response, String endpoint) {
    _log('HTTP Error $endpoint - Status: ${response.statusCode} - Body: ${response.body}');
    final parsedBody = _parseBody(response.body);
    final msg = _extractMessage(parsedBody);

    switch (response.statusCode) {
      case 400:
        return ValidationFailure(msg);
      case 401:
        return AuthFailure(msg);
      case 403:
        return AuthFailure(msg);
      case 404:
        return AuthFailure(msg);
      case 409:
        return AuthFailure(msg);
      case 502:
        return ServerFailure('Server đang bảo trì. Vui lòng thử lại sau.');
      case 503:
        return ServerFailure('Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.');
      default:
        return ServerFailure(msg);
    }
  }

  Failure _mapException(Object error, String endpoint) {
    if (error is SocketException) {
      final msg = 'Không thể kết nối server. Kiểm tra kết nối mạng. (${error.address?.host ?? error.runtimeType})';
      _log('SocketException: ${error.message} - Address: ${error.address}');
      return ServerFailure(msg);
    }
    if (error is HandshakeException) {
      _log('HandshakeException: $error');
      return const ServerFailure('Lỗi bảo mật kết nối. Vui lòng cập nhật ứng dụng.');
    }
    if (error is http.ClientException) {
      _log('ClientException: ${error.message}');
      return ServerFailure('Lỗi kết nối: ${error.message}');
    }
    if (error is FormatException) {
      _log('FormatException: $error');
      return const ServerFailure('Dữ liệu phản hồi từ server không hợp lệ.');
    }
    if (error is Failure) {
      return error;
    }
    _log('Unhandled exception: $error (${error.runtimeType})');
    return ServerFailure('Đã xảy ra lỗi không xác định. Vui lòng thử lại sau.');
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final url = '$_baseApiUrl/auth/login';
    _log('POST $url - Body: ${request.toJson()}');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(_parseBody(response.body));
      }
      throw _mapHttpResponse(response, url);
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }

  Future<OtpSendResponseModel> sendRegisterOtp(RegisterRequest request) async {
    final url = '$_baseApiUrl/auth/register-driver/send-otp';
    _log('POST $url - Body: ${request.toJson()}');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OtpSendResponseModel.fromJson(_parseBody(response.body));
      }
      throw _mapHttpResponse(response, url);
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }

  Future<AuthResponse> completeRegistration({
    required String email,
    required String otpCode,
  }) async {
    final url = '$_baseApiUrl/auth/register-driver/complete';
    final body = {'email': email, 'otpCode': otpCode};
    _log('POST $url - Body: $body');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(_parseBody(response.body));
      }
      throw _mapHttpResponse(response, url);
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }

  Future<ForgotOtpResponseModel> sendForgotOtp(String emailOrPhone) async {
    final url = '$_baseApiUrl/auth/send-otp';
    final body = {'emailOrPhone': emailOrPhone};
    _log('POST $url - Body: $body');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ForgotOtpResponseModel.fromJson(_parseBody(response.body));
      }
      throw _mapHttpResponse(response, url);
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }

  Future<ForgotVerifyResponseModel> verifyForgotOtp({
    required String emailOrPhone,
    required String otpCode,
  }) async {
    final url = '$_baseApiUrl/auth/verify-otp';
    final body = {'emailOrPhone': emailOrPhone, 'otpCode': otpCode};
    _log('POST $url - Body: $body');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200) {
        return ForgotVerifyResponseModel.fromJson(_parseBody(response.body));
      }
      throw _mapHttpResponse(response, url);
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }

  Future<ForgotResetResponseModel> resetPassword({
    required String tempToken,
    required String newPassword,
  }) async {
    final url = '$_baseApiUrl/auth/reset-password';
    final body = {'tempToken': tempToken, 'newPassword': newPassword};
    _log('POST $url - Body: {tempToken: ****, newPassword: ****}');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200) {
        return ForgotResetResponseModel.fromJson(_parseBody(response.body));
      }
      throw _mapHttpResponse(response, url);
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }

  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    final url = '$_baseApiUrl/auth/refresh-token';
    final body = {'refreshToken': refreshToken};
    _log('POST $url - Body: {refreshToken: ****}');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(_parseBody(response.body));
      }
      throw _mapHttpResponse(response, url);
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }

  Future<AuthUser> getCurrentUser(String token) async {
    final url = '$_baseApiUrl/auth/me';
    _log('GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200) {
        return AuthUser.fromJson(_parseBody(response.body));
      }
      throw _mapHttpResponse(response, url);
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }

  Future<void> registerFcmToken(String token, String fcmToken) async {
    final url = '$_baseApiUrl/auth/fcm-token';
    final body = {'fcmToken': fcmToken};
    _log('POST $url - Body: {fcmToken: ****}');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      _log('Response $url - Status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw _mapHttpResponse(response, url);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw _mapException(e, url);
    }
  }
}

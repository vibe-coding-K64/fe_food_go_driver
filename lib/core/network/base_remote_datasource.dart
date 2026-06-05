import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/failures.dart';

abstract class BaseRemoteDataSource {
  final http.Client _httpClient;
  final String _baseApiUrl;
  final Future<String> Function() _getToken;
  final FlutterSecureStorage _secureStorage;

  BaseRemoteDataSource({
    http.Client? httpClient,
    String? baseApiUrl,
    required Future<String> Function() getToken,
    required FlutterSecureStorage secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseApiUrl = baseApiUrl ?? AppConstants.baseApiUrl,
        _getToken = getToken,
        _secureStorage = secureStorage;

  void log(String message) {
    debugPrint('[BaseRemoteDataSource] $message');
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> parseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'message': body.isNotEmpty ? body : 'Server error'};
    } catch (_) {
      return {'message': body.isNotEmpty ? body : 'Server error'};
    }
  }

  Failure mapFailure(http.Response response, String endpoint) {
    log('HTTP Error $endpoint - Status: ${response.statusCode}');
    switch (response.statusCode) {
      case 400:
        return ValidationFailure(parseBody(response.body)['message'] ?? 'Bad request');
      case 401:
      case 403:
        return const AuthFailure('Unauthorized');
      case 404:
        return const ServerFailure('Resource not found');
      default:
        return ServerFailure(parseBody(response.body)['message'] ?? 'Server error');
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await _secureStorage.read(key: AppConstants.driverRefreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      log('refreshToken - No refresh token found');
      return {'success': false, 'message': 'No refresh token'};
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseApiUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      log('refreshToken - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = parseBody(response.body);
        final newAccessToken = body['token'] ?? body['accessToken'] ?? body['access_token'];
        final newRefreshToken = body['refreshToken'] ?? body['refresh_token'];

        if (newAccessToken != null) {
          await _secureStorage.write(key: AppConstants.driverTokenKey, value: newAccessToken.toString());
          if (newRefreshToken != null) {
            await _secureStorage.write(key: AppConstants.driverRefreshTokenKey, value: newRefreshToken.toString());
          }
          log('refreshToken - Success');
          return {'success': true};
        }
      }

      log('refreshToken - Failed');
      await clearTokens();
      return {'success': false, 'message': 'Refresh failed'};
    } catch (e) {
      log('refreshToken - Exception: $e');
      await clearTokens();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> clearTokens() async {
    log('clearTokens - Clearing all tokens');
    await Future.wait([
      _secureStorage.delete(key: AppConstants.driverTokenKey),
      _secureStorage.delete(key: AppConstants.driverRefreshTokenKey),
      _secureStorage.delete(key: AppConstants.driverIdKey),
    ]);
  }

  Future<http.Response> requestGet(
    String endpoint, {
    Map<String, String>? queryParams,
    int retryCount = 0,
    int maxRetries = 2,
  }) async {
    var url = '$_baseApiUrl$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      url = '$url?${Uri(queryParameters: queryParams).query}';
    }

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _httpClient.get(
          Uri.parse(url),
          headers: await authHeaders(),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 401 && retryCount == 0) {
          log('requestGet $endpoint - Got 401, attempting token refresh');
          final result = await refreshToken();
          if (result['success'] == true) {
            log('requestGet $endpoint - Refresh success, retrying request');
            return requestGet(endpoint, queryParams: queryParams, retryCount: retryCount + 1);
          }
        }

        return response;
      } on http.ClientException catch (e) {
        log('requestGet $endpoint - ClientException (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) rethrow;
      } on TimeoutException {
        log('requestGet $endpoint - Timeout (attempt ${attempt + 1}/$maxRetries)');
        if (attempt == maxRetries) {
          throw ServerFailure('Request timed out after $maxRetries retries');
        }
      } on ServerFailure {
        rethrow;
      } on AuthFailure {
        rethrow;
      } catch (e) {
        log('requestGet $endpoint - Unexpected exception: $e');
        rethrow;
      }
    }
    throw const ServerFailure('Unknown network error');
  }

  Future<http.Response> requestPost(
    String endpoint, {
    Map<String, dynamic>? body,
    int retryCount = 0,
    int maxRetries = 2,
  }) async {
    http.Response? lastError;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _httpClient.post(
          Uri.parse('$_baseApiUrl$endpoint'),
          headers: await authHeaders(),
          body: body != null ? jsonEncode(body) : null,
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 401 && retryCount == 0) {
          log('requestPost $endpoint - Got 401, attempting token refresh');
          final result = await refreshToken();
          if (result['success'] == true) {
            log('requestPost $endpoint - Refresh success, retrying request');
            return requestPost(endpoint, body: body, retryCount: retryCount + 1);
          }
        }

        return response;
      } on http.ClientException catch (e) {
        lastError = null;
        log('requestPost $endpoint - ClientException (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) rethrow;
      } on TimeoutException {
        log('requestPost $endpoint - Timeout (attempt ${attempt + 1}/$maxRetries)');
        if (attempt == maxRetries) {
          throw ServerFailure('Request timed out after $maxRetries retries');
        }
      } catch (e) {
        if (e is ServerFailure || e is AuthFailure) rethrow;
        log('requestPost $endpoint - Unexpected exception: $e');
        rethrow;
      }
    }
    throw lastError ?? const ServerFailure('Unknown network error');
  }

  Future<http.Response> requestPut(
    String endpoint, {
    Map<String, dynamic>? body,
    int retryCount = 0,
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _httpClient.put(
          Uri.parse('$_baseApiUrl$endpoint'),
          headers: await authHeaders(),
          body: body != null ? jsonEncode(body) : null,
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 401 && retryCount == 0) {
          log('requestPut $endpoint - Got 401, attempting token refresh');
          final result = await refreshToken();
          if (result['success'] == true) {
            log('requestPut $endpoint - Refresh success, retrying request');
            return requestPut(endpoint, body: body, retryCount: retryCount + 1);
          }
        }

        return response;
      } on http.ClientException catch (e) {
        log('requestPut $endpoint - ClientException (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) rethrow;
      } on TimeoutException {
        log('requestPut $endpoint - Timeout (attempt ${attempt + 1}/$maxRetries)');
        if (attempt == maxRetries) {
          throw ServerFailure('Request timed out after $maxRetries retries');
        }
      } on ServerFailure {
        rethrow;
      } on AuthFailure {
        rethrow;
      } catch (e) {
        log('requestPut $endpoint - Unexpected exception: $e');
        rethrow;
      }
    }
    throw const ServerFailure('Unknown network error');
  }

  Future<http.Response> requestDelete(
    String endpoint, {
    int retryCount = 0,
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _httpClient.delete(
          Uri.parse('$_baseApiUrl$endpoint'),
          headers: await authHeaders(),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 401 && retryCount == 0) {
          log('requestDelete $endpoint - Got 401, attempting token refresh');
          final result = await refreshToken();
          if (result['success'] == true) {
            log('requestDelete $endpoint - Refresh success, retrying request');
            return requestDelete(endpoint, retryCount: retryCount + 1);
          }
        }

        return response;
      } on http.ClientException catch (e) {
        log('requestDelete $endpoint - ClientException (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) rethrow;
      } on TimeoutException {
        log('requestDelete $endpoint - Timeout (attempt ${attempt + 1}/$maxRetries)');
        if (attempt == maxRetries) {
          throw ServerFailure('Request timed out after $maxRetries retries');
        }
      } on ServerFailure {
        rethrow;
      } on AuthFailure {
        rethrow;
      } catch (e) {
        log('requestDelete $endpoint - Unexpected exception: $e');
        rethrow;
      }
    }
    throw const ServerFailure('Unknown network error');
  }
}

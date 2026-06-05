import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

enum RefreshResult {
  success,
  failed,
  retrying,
}

class AuthInterceptor {
  final FlutterSecureStorage _secureStorage;
  final Future<({bool success, String? accessToken, String? refreshToken})> Function(String refreshToken) _onRefreshToken;

  bool _isRefreshing = false;
  final List<Completer<RefreshResult>> _pendingCompleters = [];

  AuthInterceptor({
    required FlutterSecureStorage secureStorage,
    required Future<({bool success, String? accessToken, String? refreshToken})> Function(String refreshToken) onRefreshToken,
  })  : _secureStorage = secureStorage,
        _onRefreshToken = onRefreshToken;

  /// Read token directly from SecureStorage on every call to ensure latest value
  Future<Map<String, String>> authHeaders() async {
    final token = await _secureStorage.read(key: AppConstants.driverTokenKey);
    if (token != null && token.isNotEmpty) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  /// Synchronous check if token exists (for non-API operations)
  Future<bool> hasValidToken() async {
    final token = await _secureStorage.read(key: AppConstants.driverTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<RefreshResult> handleUnauthorized() async {
    if (_isRefreshing) {
      return RefreshResult.retrying;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.read(key: AppConstants.driverRefreshTokenKey);
      final existingUserId = await _secureStorage.read(key: AppConstants.driverIdKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[AuthInterceptor] No refresh token, clearing all tokens');
        await _clearTokens();
        return RefreshResult.failed;
      }

      debugPrint('[AuthInterceptor] Attempting token refresh with refreshToken: EXISTS(${refreshToken.length} chars)');
      final result = await _onRefreshToken(refreshToken);

      if (!result.success || result.accessToken == null || result.accessToken!.isEmpty) {
        debugPrint('[AuthInterceptor] Refresh failed');
        await _clearTokens();
        return RefreshResult.failed;
      }

      debugPrint('[AuthInterceptor] Refresh success - new accessToken: EXISTS(${result.accessToken!.length} chars)');
      await _saveTokens(result.accessToken!, result.refreshToken, existingUserId);

      for (final completer in _pendingCompleters) {
        completer.complete(RefreshResult.success);
      }
      _pendingCompleters.clear();

      return RefreshResult.success;
    } catch (e) {
      debugPrint('[AuthInterceptor] Refresh exception: $e');
      await _clearTokens();
      return RefreshResult.failed;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken, String? userId) async {
    await Future.wait([
      _secureStorage.write(key: AppConstants.driverTokenKey, value: accessToken),
      if (refreshToken != null)
        _secureStorage.write(key: AppConstants.driverRefreshTokenKey, value: refreshToken),
      if (userId != null && userId.isNotEmpty)
        _secureStorage.write(key: AppConstants.driverIdKey, value: userId),
    ]);
  }

  Future<void> _clearTokens() async {
    debugPrint('[AuthInterceptor] Tokens cleared!');
    await Future.wait([
      _secureStorage.delete(key: AppConstants.driverTokenKey),
      _secureStorage.delete(key: AppConstants.driverRefreshTokenKey),
      _secureStorage.delete(key: AppConstants.driverIdKey),
    ]);

    for (final completer in _pendingCompleters) {
      completer.completeError(Exception('Token expired'));
    }
    _pendingCompleters.clear();
  }

  Future<RefreshResult> waitForRefresh() async {
    if (!_isRefreshing) return RefreshResult.success;

    final completer = Completer<RefreshResult>();
    _pendingCompleters.add(completer);
    return completer.future;
  }

  Future<void> clearAllTokens() async {
    await _clearTokens();
  }
}

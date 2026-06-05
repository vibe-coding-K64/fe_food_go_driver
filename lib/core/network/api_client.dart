import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_interceptor.dart';
import '../errors/failures.dart';

class ApiClient {
  final http.Client _httpClient;
  final AuthInterceptor _authInterceptor;
  final String _baseApiUrl;

  ApiClient({
    http.Client? httpClient,
    required AuthInterceptor authInterceptor,
    String? baseApiUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _authInterceptor = authInterceptor,
        _baseApiUrl = baseApiUrl ?? '';

  void _log(String message) {
    debugPrint('[ApiClient] $message');
  }

  Failure _mapHttpResponse(http.Response response, String endpoint) {
    _log('HTTP Error $endpoint - Status: ${response.statusCode}');
    final parsedBody = _parseBody(response.body);
    final msg = _extractMessage(parsedBody);

    switch (response.statusCode) {
      case 400:
        return ValidationFailure(msg);
      case 401:
      case 403:
        return AuthFailure(msg);
      case 404:
        return AuthFailure(msg);
      case 409:
        return AuthFailure(msg);
      case 502:
        return const ServerFailure('Server dang bao tri. Vui long thu lai sau.');
      case 503:
        return const ServerFailure('Dich vu tam thoi khong kha dung. Vui long thu lai sau.');
      default:
        return ServerFailure(msg);
    }
  }

  Failure _mapException(Object error, String endpoint) {
    if (error is SocketException) {
      return ServerFailure('Không thể kết nối server. Kiểm tra kết nối mạng.');
    }
    if (error is HandshakeException) {
      return const ServerFailure('Lỗi bảo mật kết nối. Vui lòng cập nhật ứng dụng.');
    }
    if (error is http.ClientException) {
      return ServerFailure('Lỗi kết nối: ${error.message}');
    }
    if (error is FormatException) {
      return const ServerFailure('Dữ liệu phản hồi từ server không hợp lệ.');
    }
    if (error is Failure) {
      return error;
    }
    return const ServerFailure('Đã xảy ra lỗi. Vui lòng thử lại.');
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

  String _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final msg = body['message'] ?? body['error'] ?? body['msg'];
      if (msg != null) return msg.toString();
    }
    if (body is String && body.isNotEmpty) return body;
    return 'Server error occurred';
  }

  String _buildUrl(String endpoint) {
    if (endpoint.startsWith('http')) return endpoint;
    return '$_baseApiUrl$endpoint';
  }

  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    var url = _buildUrl(endpoint);
    if (queryParams != null && queryParams.isNotEmpty) {
      url = '$url?${Uri(queryParameters: queryParams).query}';
    }
    final headers = await _authInterceptor.authHeaders();
    _logRequest('GET', url, headers);
    return _requestWithRefresh(
      () => _httpClient.get(Uri.parse(url), headers: headers),
      endpoint: 'GET $url',
    );
  }

  Future<ApiResponse> post(
    String endpoint, {
    Object? body,
  }) async {
    final url = _buildUrl(endpoint);
    final headers = await _authInterceptor.authHeaders();
    _logRequest('POST', url, headers, body);
    return _requestWithRefresh(
      () => _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: body is Map ? jsonEncode(body) : body as String?,
      ),
      endpoint: 'POST $url',
    );
  }

  Future<ApiResponse> put(
    String endpoint, {
    Object? body,
  }) async {
    final url = _buildUrl(endpoint);
    final headers = await _authInterceptor.authHeaders();
    _logRequest('PUT', url, headers, body);
    return _requestWithRefresh(
      () => _httpClient.put(
        Uri.parse(url),
        headers: headers,
        body: body is Map ? jsonEncode(body) : body as String?,
      ),
      endpoint: 'PUT $url',
    );
  }

  Future<ApiResponse> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    final headers = await _authInterceptor.authHeaders();
    _logRequest('DELETE', url, headers);
    return _requestWithRefresh(
      () => _httpClient.delete(
        Uri.parse(url),
        headers: headers,
      ),
      endpoint: 'DELETE $url',
    );
  }

  void _logRequest(String method, String url, Map<String, String> headers, [Object? body]) {
    final auth = headers['Authorization'] ?? 'NONE';
    final bodyStr = body is Map ? jsonEncode(body) : (body as String? ?? '');
    _log('$method $url');
    _log('  Auth: $auth');
    if (bodyStr.isNotEmpty) {
      _log('  Body: $bodyStr');
    }
  }

  Future<ApiResponse> _requestWithRefresh(
    Future<http.Response> Function() requestFn, {
    required String endpoint,
    int retryCount = 0,
  }) async {
    try {
      final response = await requestFn();

      if (response.statusCode == 401 && retryCount == 0) {
        _log('Got 401 on $endpoint, attempting token refresh...');
        final refreshResult = await _authInterceptor.handleUnauthorized();

        if (refreshResult == RefreshResult.success) {
          _log('Token refreshed, retrying $endpoint...');
          return _requestWithRefresh(requestFn, endpoint: endpoint, retryCount: retryCount + 1);
        } else if (refreshResult == RefreshResult.retrying) {
          _log('Another refresh in progress, waiting...');
          await _authInterceptor.waitForRefresh();
          _log('Refresh wait complete, retrying $endpoint...');
          return _requestWithRefresh(requestFn, endpoint: endpoint, retryCount: retryCount + 1);
        } else {
          _log('Token refresh failed, user must login again');
          return ApiResponse(
            success: false,
            failure: const AuthFailure('Phien dang nhap het han. Vui long dang nhap lai.'),
            statusCode: 401,
          );
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          data: _parseBody(response.body),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        failure: _mapHttpResponse(response, endpoint),
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      return ApiResponse(
        success: false,
        failure: _mapException(e, endpoint),
        statusCode: 0,
      );
    } on HandshakeException catch (e) {
      return ApiResponse(
        success: false,
        failure: _mapException(e, endpoint),
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        failure: _mapException(e, endpoint),
        statusCode: 0,
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final Failure? failure;
  final int statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.failure,
    required this.statusCode,
  });

  bool get isSuccess => success;
  bool get isFailure => !success;
  Map<String, dynamic>? get jsonData => data is Map<String, dynamic> ? data : null;
}

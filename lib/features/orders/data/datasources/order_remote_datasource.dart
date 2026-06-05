import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../models/order_model.dart';

class OrderActionResultModel {
  final String orderId;
  final String? requestId;
  final String status;

  const OrderActionResultModel({
    required this.orderId,
    required this.requestId,
    required this.status,
  });

  factory OrderActionResultModel.fromJson(Map<String, dynamic> json) {
    return OrderActionResultModel(
      orderId: json['orderId']?.toString() ?? '',
      requestId: json['requestId']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }
}

class OrderRemoteDataSource extends BaseRemoteDataSource {
  OrderRemoteDataSource({
    http.Client? httpClient,
    String? baseApiUrl,
    required Future<String> Function() getToken,
    required FlutterSecureStorage secureStorage,
  }) : super(
         httpClient: httpClient,
         baseApiUrl: baseApiUrl,
         getToken: getToken,
         secureStorage: secureStorage,
       );

  Future<List<OrderModel>> _getOrders(String endpoint) async {
    log('GET $endpoint');
    try {
      final response = await requestGet(endpoint);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded is List
            ? decoded
            : (decoded['data'] ?? decoded['content'] ?? []);
        return (list as List)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw mapFailure(response, endpoint);
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch orders');
    }
  }

  Future<List<OrderModel>> getAvailableOrders() async {
    return _getOrders('/drivers/orders/available');
  }

  Future<List<OrderModel>> getDriverActiveOrders() async {
    return _getOrders('/drivers/orders/active');
  }

  Future<OrderModel?> getSingleActiveOrder() async {
    log('GET /drivers/orders/current');
    try {
      final response = await requestGet('/drivers/orders/current');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded == null || decoded == '') return null;
        final orderData = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded)
            : decoded;
        if (orderData == null || orderData == '') return null;
        return OrderModel.fromJson(orderData as Map<String, dynamic>);
      }
      if (response.statusCode == 404) return null;
      throw mapFailure(response, '/drivers/orders/current');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch current order');
    }
  }

  Future<List<OrderModel>> getRecentOrders(
    String driverId, {
    int limit = 10,
  }) async {
    return _getOrders('/drivers/orders/history?limit=$limit');
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    log('GET /drivers/orders/$orderId');
    try {
      final response = await requestGet('/drivers/orders/$orderId');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final orderData = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded)
            : decoded;
        if (orderData == null || orderData == '') return null;
        return OrderModel.fromJson(orderData as Map<String, dynamic>);
      }
      if (response.statusCode == 404) return null;
      throw mapFailure(response, '/drivers/orders/$orderId');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch order detail');
    }
  }

  Future<OrderModel?> acceptOrderApi(String driverId, String orderId) async {
    log('POST /drivers/orders/$orderId/accept');
    try {
      final response = await requestPost(
        '/drivers/orders/$orderId/accept',
        body: {'driverId': driverId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] ?? decoded : decoded;
        return data is Map<String, dynamic> ? OrderModel.fromJson(data) : null;
      }
      if (response.statusCode == 204) return null;
      throw mapFailure(response, '/drivers/orders/$orderId/accept');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to accept order');
    }
  }

  Future<OrderModel?> updateOrderStatusApi(
    String driverId,
    String orderId,
    int status,
  ) async {
    log('PUT /drivers/orders/$orderId/status - status=$status');
    try {
      final response = await requestPut(
        '/drivers/orders/$orderId/status',
        body: {'status': status},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] ?? decoded : decoded;
        return data is Map<String, dynamic> ? OrderModel.fromJson(data) : null;
      }
      if (response.statusCode == 204) return null;
      throw mapFailure(response, '/drivers/orders/$orderId/status');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to update order status');
    }
  }

  Future<dynamic> respondOrderApi(
    String orderId,
    String action,
    String requestId,
  ) async {
    log(
      'POST /drivers/orders/$orderId/respond - action=$action, requestId=$requestId',
    );
    try {
      final response = await requestPost(
        '/drivers/orders/$orderId/respond',
        body: {'action': action, 'requestId': requestId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] ?? decoded : decoded;
        if (data is Map<String, dynamic>) {
          if (action.toLowerCase() == 'accept') {
            return OrderModel.fromJson(data);
          }
          return OrderActionResultModel.fromJson(data);
        }
        return null;
      }
      if (response.statusCode == 204) return null;
      throw mapFailure(response, '/drivers/orders/$orderId/respond');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to respond to order');
    }
  }
}

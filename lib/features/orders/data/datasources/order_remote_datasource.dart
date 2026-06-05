import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../models/order_model.dart';

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
        return list
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

  Future<void> acceptOrderApi(String driverId, String orderId) async {
    log('POST /drivers/orders/$orderId/accept');
    try {
      final response = await requestPost(
        '/drivers/orders/$orderId/accept',
        body: {'driverId': driverId},
      );

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw mapFailure(response, '/drivers/orders/$orderId/accept');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to accept order');
    }
  }

  Future<void> updateOrderStatusApi(
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

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw mapFailure(response, '/drivers/orders/$orderId/status');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to update order status');
    }
  }

  Future<void> respondOrderApi(String orderId, String action) async {
    log('POST /drivers/orders/$orderId/respond - action=$action');
    try {
      final response = await requestPost(
        '/drivers/orders/$orderId/respond',
        body: {'action': action},
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw mapFailure(response, '/drivers/orders/$orderId/respond');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to respond to order');
    }
  }
}

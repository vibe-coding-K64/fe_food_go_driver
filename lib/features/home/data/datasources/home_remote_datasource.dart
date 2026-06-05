import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/base_remote_datasource.dart';
import '../../../orders/data/models/order_model.dart';

class HomeRemoteDataSource extends BaseRemoteDataSource {
  HomeRemoteDataSource({
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

  Future<Map<String, dynamic>> getDriverStats() async {
    log('GET /drivers/stats');
    try {
      final response = await requestGet('/drivers/stats');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded as Map<String, dynamic>;
      }
      return {
        'ordersToday': 0,
        'earningsToday': 0.0,
        'balance': 0.0,
      };
    } catch (e) {
      log('Exception: $e');
      return {
        'ordersToday': 0,
        'earningsToday': 0.0,
        'balance': 0.0,
      };
    }
  }

  Future<List<OrderModel>> getRecentOrders({int limit = 10}) async {
    log('GET /drivers/orders/history?limit=$limit');
    try {
      final response = await requestGet('/drivers/orders/history', queryParams: {'limit': limit.toString()});

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['content'] ?? [])
            : (decoded is List ? decoded : []);
        if (data is List) {
          return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      log('Exception: $e');
      return [];
    }
  }

  Future<OrderModel?> getCurrentOrder() async {
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
      return null;
    } catch (e) {
      log('Exception: $e');
      return null;
    }
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/base_remote_datasource.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../driver/domain/entities/driver_location.dart';

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
        final data = decoded is Map<String, dynamic> ? decoded['data'] ?? decoded : decoded;
        if (data is Map<String, dynamic>) {
          // Map StatsDTO backend -> frontend format
          return {
            'totalOrders': data['totalTrips'] ?? data['total_trips'] ?? 0,
            'totalTrips': data['totalTrips'] ?? data['total_trips'] ?? 0,
            'ordersToday': data['todayTrips'] ?? data['today_trips'] ?? 0,
            'earningsToday': (data['todayEarnings'] ?? data['today_earnings'] ?? 0.0).toDouble(),
            'balance': (data['balance'] ?? 0.0).toDouble(),
            'rating': (data['averageRating'] ?? data['average_rating'] ?? 0.0).toDouble(),
          };
        }
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

  Future<List<OrderModel>> getAvailableOrders() async {
    log('GET /drivers/orders/available');
    try {
      final response = await requestGet('/drivers/orders/available');

      log('[getAvailableOrders] status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data;
        if (decoded is Map<String, dynamic>) {
          final rawData = decoded['data'];
          if (rawData is List) {
            data = rawData;
          } else {
            log('[getAvailableOrders] data is not a list, rawData=$rawData');
            return [];
          }
        } else if (decoded is List) {
          data = decoded;
        } else {
          log('[getAvailableOrders] decoded is neither Map nor List');
          return [];
        }
        log('[getAvailableOrders] parsed ${data.length} orders');
        return data
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      log('[getAvailableOrders] non-200 status: ${response.statusCode}');
      return [];
    } catch (e) {
      log('[getAvailableOrders] Exception: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getActiveOrders() async {
    log('GET /drivers/orders/active');
    try {
      final response = await requestGet('/drivers/orders/active');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data;
        if (decoded is Map<String, dynamic>) {
          final rawData = decoded['data'];
          if (rawData is List) {
            data = rawData;
          } else {
            return [];
          }
        } else if (decoded is List) {
          data = decoded;
        } else {
          return [];
        }
        return data
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
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

  Future<DriverLocation?> getDriverLocation(String driverId) async {
    log('GET /drivers/$driverId/profile (for location)');
    try {
      final response = await requestGet('/drivers/$driverId/profile');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded)
            : decoded;
        if (data is! Map<String, dynamic>) return null;

        final lat = _toDouble(data['lat']);
        final lng = _toDouble(data['lng']);
        if (lat == null || lng == null) return null;

        return DriverLocation(
          driverId: driverId,
          lat: lat,
          lng: lng,
          heading: _toDouble(data['heading']) ?? 0,
          speed: _toDouble(data['speed']) ?? 0,
          updatedAt: DateTime.now(),
          isActive: data['isActive'] == true || data['isActive'] == 'true',
        );
      }
      return null;
    } catch (e) {
      log('Exception: $e');
      return null;
    }
  }

  Future<void> declineAvailableOrder(String orderId, String driverId) async {
    log('POST /drivers/orders/$orderId/decline');
    try {
      final response = await requestPost(
        '/drivers/orders/$orderId/decline',
        body: {'driverId': driverId},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        log('[declineAvailableOrder] non-2xx status: ${response.statusCode}');
      }
    } catch (e) {
      log('[declineAvailableOrder] Exception: $e');
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../../domain/entities/driver_notification.dart';

class NotificationRemoteDataSource extends BaseRemoteDataSource {
  NotificationRemoteDataSource({
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

  Future<List<DriverNotification>> getNotifications({int limit = 50}) async {
    log('GET /notifications?limit=$limit');
    try {
      final response = await requestGet('/notifications', queryParams: {'limit': limit.toString()});

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['content'] ?? [])
            : (decoded is List ? decoded : []);
        return (data as List)
            .map((e) => DriverNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      log('Exception: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    log('PUT /notifications/$notificationId/read');
    try {
      final response = await requestPut(
        '/notifications/$notificationId/read',
        body: {},
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        log('markAsRead failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Exception: $e');
    }
  }

  Future<void> markAllAsRead() async {
    log('PUT /notifications/read-all');
    try {
      final response = await requestPut(
        '/notifications/read-all',
        body: {},
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        log('markAllAsRead failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Exception: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    log('DELETE /notifications/$notificationId');
    try {
      final response = await requestDelete('/notifications/$notificationId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        log('deleteNotification failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Exception: $e');
    }
  }
}

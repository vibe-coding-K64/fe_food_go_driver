import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../models/driver_profile_model.dart';

class DriverRemoteDataSource extends BaseRemoteDataSource {
  DriverRemoteDataSource({
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

  Future<DriverProfileModel> getDriverProfileApi(String driverId) async {
    log('GET /drivers/$driverId/profile');
    try {
      final response = await requestGet('/drivers/$driverId/profile');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return DriverProfileModel.fromJson(decoded as Map<String, dynamic>);
      }
      throw mapFailure(response, '/drivers/$driverId/profile');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch driver profile');
    }
  }

  Future<Map<String, dynamic>> getDriverStatsApi(String driverId) async {
    log('GET /drivers/$driverId/stats');
    try {
      final response = await requestGet('/drivers/$driverId/stats');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded as Map<String, dynamic>;
      }
      throw mapFailure(response, '/drivers/$driverId/stats');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch driver stats');
    }
  }

  Future<void> updateStatusApi({
    required bool isActive,
    double? lat,
    double? lng,
  }) async {
    log('PUT /drivers/status - isActive=$isActive, lat=$lat, lng=$lng');
    try {
      final body = <String, dynamic>{'isActive': isActive};
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;

      final response = await requestPut('/drivers/status', body: body);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw mapFailure(response, '/drivers/status');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to update driver status');
    }
  }

  Future<void> updateLocationApi(double lat, double lng, {double? heading, double? speed}) async {
    log('POST /drivers/location - lat=$lat, lng=$lng, heading=$heading, speed=$speed');
    try {
      final response = await requestPost('/drivers/location', body: {
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
      });

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw mapFailure(response, '/drivers/location');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to update location');
    }
  }
}

import 'dart:io';

import '../../domain/entities/driver_profile.dart';
import '../../domain/repositories/driver_repository.dart';
import '../datasources/driver_remote_datasource.dart';

class DriverRepositoryImpl implements DriverRepository {
  final DriverRemoteDataSource _remoteDataSource;

  DriverRepositoryImpl(this._remoteDataSource);

  @override
  Future<DriverProfile?> getDriverProfile(String driverId) async {
    try {
      return await _remoteDataSource.getDriverProfileApi(driverId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<DriverProfile?> watchDriverProfile(String driverId) async* {
    while (true) {
      try {
        final profile = await _remoteDataSource.getDriverProfileApi(driverId);
        yield profile;
      } catch (_) {
        yield null;
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  @override
  Future<void> updateDriverStatus(bool isActive, {double? lat, double? lng}) async {
    await _remoteDataSource.updateStatusApi(isActive: isActive, lat: lat, lng: lng);
  }

  @override
  Future<void> updateDriverLocation(double lat, double lng, {double? heading, double? speed}) async {
    await _remoteDataSource.updateLocationApi(lat, lng, heading: heading, speed: speed);
  }

  @override
  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    try {
      return await _remoteDataSource.getDriverStatsApi(driverId);
    } catch (_) {
      return {
        'ordersToday': 0,
        'earningsToday': 0.0,
        'balance': 0.0,
      };
    }
  }

  @override
  Future<DriverProfile?> updateDriverProfile({
    String? fullName,
    String? phoneNumber,
    String? vehiclePlate,
    String? vehicleType,
    String? driverLicense,
    String? photoUrl,
  }) async {
    return await _remoteDataSource.updateDriverProfileApi(
      fullName: fullName,
      phoneNumber: phoneNumber,
      vehiclePlate: vehiclePlate,
      vehicleType: vehicleType,
      driverLicense: driverLicense,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<String> uploadDriverAvatar(String filePath) async {
    return await _remoteDataSource.uploadDriverAvatarApi(File(filePath));
  }
}

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
      final profile = await getDriverProfile(driverId);
      yield profile;
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
}

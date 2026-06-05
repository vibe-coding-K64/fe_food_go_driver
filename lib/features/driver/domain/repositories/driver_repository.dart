import '../entities/driver_profile.dart';

abstract class DriverRepository {
  Future<DriverProfile?> getDriverProfile(String driverId);

  Stream<DriverProfile?> watchDriverProfile(String driverId);

  Future<void> updateDriverStatus(bool isActive, {double? lat, double? lng});

  Future<void> updateDriverLocation(double lat, double lng, {double? heading, double? speed});

  Future<Map<String, dynamic>> getDriverStats(String driverId);
}

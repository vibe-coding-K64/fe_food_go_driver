import '../entities/driver_profile.dart';

abstract class DriverRepository {
  Future<DriverProfile?> getDriverProfile(String driverId);

  Stream<DriverProfile?> watchDriverProfile(String driverId);

  Future<void> updateDriverStatus(bool isActive, {double? lat, double? lng});

  Future<void> updateDriverLocation(double lat, double lng, {double? heading, double? speed});

  Future<Map<String, dynamic>> getDriverStats(String driverId);

  Future<DriverProfile?> updateDriverProfile({
    String? fullName,
    String? phoneNumber,
    String? vehiclePlate,
    String? vehicleType,
    String? driverLicense,
    String? photoUrl,
  });

  Future<String> uploadDriverAvatar(String filePath);
}

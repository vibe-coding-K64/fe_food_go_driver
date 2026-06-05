import '../../domain/entities/driver_profile.dart';

class DriverProfileModel extends DriverProfile {
  const DriverProfileModel({
    required super.id,
    super.photoUrl,
    required super.fullName,
    required super.phoneNumber,
    required super.vehiclePlate,
    required super.vehicleType,
    super.driverLicense,
    super.isActive,
    super.isAvailable,
    super.rating,
    super.totalTrips,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? json['photo_url']?.toString(),
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone_number']?.toString() ?? '',
      vehiclePlate: json['vehiclePlate']?.toString() ?? json['vehicle_plate']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? json['vehicle_type']?.toString() ?? 'motorcycle',
      driverLicense: json['driverLicense']?.toString() ?? json['driver_license']?.toString(),
      isActive: json['isActive'] ?? json['is_active'] ?? false,
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalTrips: json['totalTrips'] ?? json['total_trips'] ?? json['totalTripsCompleted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoUrl': photoUrl,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'vehiclePlate': vehiclePlate,
      'vehicleType': vehicleType,
      'driverLicense': driverLicense,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'rating': rating,
      'totalTrips': totalTrips,
    };
  }
}

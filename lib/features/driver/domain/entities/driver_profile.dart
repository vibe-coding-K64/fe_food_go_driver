import 'package:equatable/equatable.dart';

class DriverProfile extends Equatable {
  final String id;
  final String? photoUrl;
  final String fullName;
  final String phoneNumber;
  final String vehiclePlate;
  final String vehicleType;
  final String? driverLicense;
  final bool isActive;
  final bool isAvailable;
  final double rating;
  final int totalTrips;

  const DriverProfile({
    required this.id,
    this.photoUrl,
    required this.fullName,
    required this.phoneNumber,
    required this.vehiclePlate,
    required this.vehicleType,
    this.driverLicense,
    this.isActive = false,
    this.isAvailable = false,
    this.rating = 0.0,
    this.totalTrips = 0,
  });

  @override
  List<Object?> get props => [
        id,
        photoUrl,
        fullName,
        phoneNumber,
        vehiclePlate,
        vehicleType,
        driverLicense,
        isActive,
        isAvailable,
        rating,
        totalTrips,
      ];
}

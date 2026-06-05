import 'package:equatable/equatable.dart';

class DriverLocation extends Equatable {
  final String driverId;
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final DateTime updatedAt;
  final bool isActive;

  const DriverLocation({
    required this.driverId,
    required this.lat,
    required this.lng,
    this.heading = 0,
    this.speed = 0,
    required this.updatedAt,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [driverId, lat, lng, heading, speed, updatedAt, isActive];
}

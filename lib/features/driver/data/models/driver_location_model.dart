import '../../domain/entities/driver_location.dart';

class DriverLocationModel extends DriverLocation {
  const DriverLocationModel({
    required super.driverId,
    required super.lat,
    required super.lng,
    super.heading,
    super.speed,
    required super.updatedAt,
    super.isActive,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseUpdatedAt() {
      final val = json['updatedAt'];
      if (val == null) return DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      final str = val.toString();
      final parsed = int.tryParse(str);
      if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
      try {
        return DateTime.parse(str);
      } catch (_) {
        return DateTime.now();
      }
    }

    return DriverLocationModel(
      driverId: json['driverId']?.toString() ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      heading: (json['heading'] ?? 0.0).toDouble(),
      speed: (json['speed'] ?? 0.0).toDouble(),
      updatedAt: parseUpdatedAt(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

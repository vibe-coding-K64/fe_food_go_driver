import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/errors/failures.dart';

class LocationService {
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[LocationService] isLocationServiceEnabled error: $e');
      return false;
    }
  }

  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('[LocationService] checkPermission error: $e');
      return LocationPermission.denied;
    }
  }

  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('[LocationService] requestPermission error: $e');
      return LocationPermission.denied;
    }
  }

  Future<(Position?, Failure?)> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (null, const LocationServiceDisabledFailure());
      }

      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return (null, const LocationPermissionDeniedFailure());
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return (null, const LocationPermissionDeniedFailure());
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (position, null);
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error: $e');
      return (null, LocationServiceUnavailableFailure(e.toString()));
    }
  }

  Future<(Position?, Failure?)> getLastKnownOrCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (null, const LocationServiceDisabledFailure());
      }

      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return (null, const LocationPermissionDeniedFailure());
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return (null, const LocationPermissionDeniedFailure());
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return (lastKnown, null);
      }

      return await getCurrentPosition();
    } catch (e) {
      debugPrint('[LocationService] getLastKnownOrCurrentPosition error: $e');
      return (null, LocationServiceUnavailableFailure(e.toString()));
    }
  }
}

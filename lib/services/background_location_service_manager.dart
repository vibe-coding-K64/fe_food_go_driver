import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../features/driver/domain/repositories/driver_repository.dart';
import 'location_service.dart';

class BackgroundLocationServiceManager {
  static const _channel = EventChannel('com.example.fe_food_go_driver/background_location');
  static const _methodChannel = MethodChannel('com.example.fe_food_go_driver/background_location_control');

  static final BackgroundLocationServiceManager _instance = BackgroundLocationServiceManager._internal();
  factory BackgroundLocationServiceManager() => _instance;
  BackgroundLocationServiceManager._internal();

  StreamSubscription? _locationSubscription;
  DriverRepository? _driverRepository;
  bool _isServiceRunning = false;

  void initialize({required DriverRepository driverRepository}) {
    _driverRepository = driverRepository;
  }

  Future<void> startService() async {
    if (_isServiceRunning) return;

    try {
      await _methodChannel.invokeMethod('startForegroundService');
      _isServiceRunning = true;

      _locationSubscription = _channel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final lat = (event['lat'] as num?)?.toDouble();
            final lng = (event['lng'] as num?)?.toDouble();
            final heading = (event['heading'] as num?)?.toDouble() ?? 0;
            final speed = (event['speed'] as num?)?.toDouble() ?? 0;

            if (lat != null && lng != null) {
              _sendLocationToBackend(lat, lng, heading.toDouble(), speed.toDouble());
            }
          }
        },
        onError: (e) {
          debugPrint('[BgLocationMgr] Stream error: $e');
        },
      );

      debugPrint('[BgLocationMgr] Service started');
    } catch (e) {
      debugPrint('[BgLocationMgr] Failed to start service: $e');
    }
  }

  Future<void> stopService() async {
    if (!_isServiceRunning) return;

    try {
      await _methodChannel.invokeMethod('stopForegroundService');
      _locationSubscription?.cancel();
      _locationSubscription = null;
      _isServiceRunning = false;
      debugPrint('[BgLocationMgr] Service stopped');
    } catch (e) {
      debugPrint('[BgLocationMgr] Failed to stop service: $e');
    }
  }

  bool get isRunning => _isServiceRunning;

  Future<void> _sendLocationToBackend(
    double lat,
    double lng,
    double heading,
    double speed,
  ) async {
    if (_driverRepository == null) return;
    try {
      await _driverRepository!.updateDriverLocation(
        lat,
        lng,
        heading: heading,
        speed: speed,
      );
    } catch (e) {
      debugPrint('[BgLocationMgr] Failed to send location: $e');
    }
  }

  void dispose() {
    stopService();
    _driverRepository = null;
  }
}

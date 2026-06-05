import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driver/domain/entities/driver_location.dart';
import '../../../orders/domain/entities/order.dart';
import '../../data/repositories/home_repository_impl.dart';

class OrderMapScreen extends StatefulWidget {
  final Order order;

  const OrderMapScreen({super.key, required this.order});

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  final MapController _mapController = MapController();
  int _currentRoute = 0;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  LatLng? _storeLocation;
  LatLng? _deliveryLocation;
  final LatLng _defaultCenter = const LatLng(10.762622, 106.660172);

  DriverLocation? _driverLocation;
  String? _driverId;

  // --- Turn-by-turn navigation state ---
  FlutterTts? _tts;
  bool _isNavigating = false;
  bool _isMuted = false;
  List<_RouteStep> _routeSteps = [];
  int _currentStepIndex = 0;
  double? _totalDistanceMeters;
  double? _remainingDistanceMeters;
  int? _remainingSeconds;
  String? _currentInstruction;

  // Auto-recenter
  bool _autoRecenter = false;

  @override
  void initState() {
    super.initState();
    _storeLocation = widget.order.storeLat != null && widget.order.storeLng != null
        ? LatLng(widget.order.storeLat!, widget.order.storeLng!)
        : null;
    _deliveryLocation =
        widget.order.deliveryLat != null && widget.order.deliveryLng != null
            ? LatLng(widget.order.deliveryLat!, widget.order.deliveryLng!)
            : null;

    // Đang lấy hàng -> điểm đến là cửa hàng; đang giao -> điểm đến là người nhận
    _currentRoute = widget.order.isPickingUp ? 0 : 1;

    _driverId = widget.order.driverId;
    if (_driverId != null) {
      _subscribeDriverLocation();
    }

    _initTts();
    _resolveStoreLocationAndFetchRoute();
  }

  void _resolveStoreLocationAndFetchRoute() {
    if (_storeLocation != null && _deliveryLocation != null) {
      _fetchRoute();
    } else if (_storeLocation == null && widget.order.storeAddress != null) {
      _geocodeStoreLocation();
    } else if (_storeLocation == null && widget.order.storeId != null) {
      _geocodeStoreLocation();
    }
  }

  Future<void> _geocodeStoreLocation() async {
    // 1. Thử Firestore trước
    final storeId = widget.order.storeId;
    if (storeId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();
        final data = doc.data();
        if (data != null) {
          final lat = _toDouble(data['lat']);
          final lng = _toDouble(data['lng']);
          if (lat != null && lng != null && mounted) {
            setState(() => _storeLocation = LatLng(lat, lng));
            if (_deliveryLocation != null) _fetchRoute();
            return;
          }
        }
      } catch (e) {
        debugPrint('[OrderMapScreen] Firestore store lookup error: $e');
      }
    }

    // 2. Fallback: geocode từ address
    final address = widget.order.storeAddress;
    if (address == null || address.isEmpty) return;

    try {
      final query = Uri.encodeComponent('$address, Vietnam');
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'FoodGoDriver/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final lat = double.tryParse(results[0]['lat'].toString());
          final lon = double.tryParse(results[0]['lon'].toString());
          if (lat != null && lon != null && mounted) {
            setState(() {
              _storeLocation = LatLng(lat, lon);
            });
            if (_deliveryLocation != null) {
              _fetchRoute();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[OrderMapScreen] Geocode error: $e');
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts!.setLanguage('vi-VN');
    await _tts!.setSpeechRate(0.52);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
  }

  void _subscribeDriverLocation() {
    final homeRepo = GetIt.I<HomeRepository>();
    homeRepo.watchDriverLocation(_driverId!).listen((location) {
      if (mounted) {
        setState(() => _driverLocation = location);
        if (location != null) {
          if (_isNavigating) {
            _updateNavigationProgress(location.lat, location.lng);
          }
          if (_autoRecenter) {
            _mapController.move(
              LatLng(location.lat, location.lng),
              _mapController.camera.zoom,
            );
          }
        }
      }
    });
  }

  Future<void> _fetchRoute() async {
    if (_storeLocation == null || _deliveryLocation == null) {
      debugPrint('[OrderMapScreen] _fetchRoute skipped: store=${_storeLocation}, delivery=${_deliveryLocation}');
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      final isNavigatingToStore = _currentRoute == 0;
      final origin = isNavigatingToStore ? _deliveryLocation! : _storeLocation!;
      final dest = isNavigatingToStore ? _storeLocation! : _deliveryLocation!;

      debugPrint('[OrderMapScreen] Fetching route: origin=(${origin.latitude},${origin.longitude}) dest=(${dest.latitude},${dest.longitude})');

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=polyline&steps=true',
      );

      debugPrint('[OrderMapScreen] OSRM URI: $uri');

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[OrderMapScreen] OSRM response code: ${decoded['code']}');
        if (decoded['code'] == 'Ok') {
          final geometry = decoded['routes'][0]['geometry'] as String;
          final points = _decodePolyline(geometry);

          final legs = decoded['routes'][0]['legs'] as List;
          final steps = <_RouteStep>[];
          for (final leg in legs) {
            final legSteps = leg['steps'] as List;
            for (final step in legSteps) {
              final maneuver = step['maneuver'] as Map<String, dynamic>;
              final location = maneuver['location'] as List;
              steps.add(_RouteStep(
                instruction: _cleanInstruction(
                    step['name'] as String? ?? '', step['maneuver'] as Map<String, dynamic>),
                maneuverType: maneuver['type'] as String? ?? 'turn',
                maneuverModifier: maneuver['modifier'] as String?,
                distance: (step['distance'] as num?)?.toDouble() ?? 0,
                duration: (step['duration'] as num?)?.toDouble() ?? 0,
                lat: (location[1] as num).toDouble(),
                lng: (location[0] as num).toDouble(),
                wayName: step['name'] as String? ?? '',
              ));
            }
          }

          final totalDist = (decoded['routes'][0]['distance'] as num?)?.toDouble() ?? 0;
          final totalDur = (decoded['routes'][0]['duration'] as num?)?.toDouble() ?? 0;

          setState(() {
            _routePoints = points;
            _routeSteps = steps;
            _totalDistanceMeters = totalDist;
            _remainingDistanceMeters = totalDist;
            _remainingSeconds = totalDur.toInt();
            _currentStepIndex = 0;
            _currentInstruction = steps.isNotEmpty ? steps[0].instruction : null;
            _isLoadingRoute = false;
          });

          _fitBounds();
          if (steps.isNotEmpty && !_isMuted) {
            final prefix = _currentRoute == 0 ? 'Hướng tới cửa hàng. ' : 'Hướng tới địa chỉ giao hàng. ';
            _speak(prefix + steps[0].instruction);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('[OrderMapScreen] Route fetch error: $e');
    }

    setState(() => _isLoadingRoute = false);
  }

  String _cleanInstruction(String wayName, Map<String, dynamic> maneuver) {
    final type = maneuver['type'] as String? ?? '';
    final modifier = maneuver['modifier'] as String? ?? '';
    final instruction = maneuver['instruction'] as String?;

    if (instruction != null && instruction.isNotEmpty) return instruction;

    String turn = '';
    switch (type) {
      case 'depart':
        turn = 'Khởi hành';
        break;
      case 'arrive':
        turn = 'Bạn đã đến nơi';
        break;
      case 'turn':
        turn = _viModifier(modifier);
        break;
      case 'merge':
        turn = 'Đi vào ${_viModifier(modifier)}';
        break;
      case 'ramp':
        turn = 'Đi vào đường ${_viModifier(modifier)}';
        break;
      case 'fork':
        turn = 'Chọn ${_viModifier(modifier)}';
        break;
      case 'roundabout':
        turn = 'Đi vòng xuyến';
        break;
      case 'rotary':
        turn = 'Đi qua vòng xuyến';
        break;
      case 'continue':
        turn = 'Tiếp tục đi thẳng';
        break;
      case 'new name':
        turn = 'Tiếp tục';
        break;
      case 'end of road':
        turn = 'Cuối đường, rẽ ${_viModifier(modifier)}';
        break;
      case 'waypoint reached':
        turn = 'Đã đến điểm';
        break;
      case 'invalid':
        turn = '';
        break;
      default:
        turn = _viModifier(modifier);
    }

    if (wayName.isNotEmpty && !wayName.contains('Unnamed') && !wayName.contains('unnamed')) {
      turn += ' trên $wayName';
    }

    return turn.trim();
  }

  String _viModifier(String? mod) {
    switch (mod) {
      case 'right':
        return 'Rẽ phải';
      case 'left':
        return 'Rẽ trái';
      case 'slight right':
        return 'Nghiêng phải';
      case 'slight left':
        return 'Nghiêng trái';
      case 'sharp right':
        return 'Rẽ gắt phải';
      case 'sharp left':
        return 'Rẽ gắt trái';
      case 'straight':
        return 'Đi thẳng';
      case 'uturn':
        return 'Quay đầu';
      default:
        return mod ?? '';
    }
  }

  void _updateNavigationProgress(double driverLat, double driverLng) {
    if (_routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) return;

    final step = _routeSteps[_currentStepIndex];
    final distToStep = _haversineDistance(driverLat, driverLng, step.lat, step.lng);

    double remaining = 0;
    for (int i = _currentStepIndex; i < _routeSteps.length; i++) {
      remaining += _routeSteps[i].distance;
    }
    final updatedRemaining = _haversineDistance(
        driverLat, driverLng, _routeSteps.last.lat, _routeSteps.last.lng);

    setState(() {
      _remainingDistanceMeters = updatedRemaining;
    });

    if (distToStep < 30) {
      final nextIndex = _currentStepIndex + 1;
      if (nextIndex < _routeSteps.length) {
        setState(() {
          _currentStepIndex = nextIndex;
          _currentInstruction = _routeSteps[nextIndex].instruction;
        });
        if (!_isMuted) {
          _speak(_routeSteps[nextIndex].instruction);
        }
      }
    }
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * 3.141592653589793 / 180;

  double _sin(double x) {
    x = x - (2 * 3.141592653589793 * (x / (2 * 3.141592653589793)).floor());
    double result = x;
    double term = x;
    for (int i = 1; i < 15; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _cos(double x) => _sin(x + 1.5707963267948966);

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0;
  }

  double _atan(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i < 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty || _tts == null) return;
    await _tts!.speak(text);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final poly = encoded;
    final len = poly.length;
    final list = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < len) {
      var b = poly.codeUnitAt(index++) - 63;
      var dlat = (b & 0x1f) << 1;
      if ((b & 0x20) != 0) dlat = ~dlat + 1;
      lat += dlat;

      b = poly.codeUnitAt(index++) - 63;
      var dlng = (b & 0x1f) << 1;
      if ((b & 0x20) != 0) dlng = ~dlng + 1;
      lng += dlng;

      list.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return list;
  }

  void _fitBounds() {
    if (_storeLocation == null || _deliveryLocation == null) return;

    final bounds = LatLngBounds(_storeLocation!, _deliveryLocation!);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  void _startNavigation() {
    setState(() => _isNavigating = true);
    if (_routeSteps.isNotEmpty) {
      _speak('Bắt đầu chỉ đường. ${_routeSteps[0].instruction}');
    }
  }

  void _stopNavigation() {
    setState(() => _isNavigating = false);
    _tts?.stop();
  }

  void _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      await _tts?.stop();
    } else {
      if (_currentInstruction != null) {
        _speak(_currentInstruction!);
      }
    }
  }

  Future<void> _openExternalNavigation(LatLng destination) async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {}

    final destLat = destination.latitude.toStringAsFixed(6);
    final destLng = destination.longitude.toStringAsFixed(6);

    final oriLat = position != null
        ? position.latitude.toStringAsFixed(6)
        : _driverLocation?.lat.toStringAsFixed(6) ?? '10.7769';
    final oriLng = position != null
        ? position.longitude.toStringAsFixed(6)
        : _driverLocation?.lng.toStringAsFixed(6) ?? '106.7009';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${oriLat},${oriLng}'
      '&destination=${destLat},${destLng}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _toggleRoute() {
    setState(() {
      _currentRoute = _currentRoute == 0 ? 1 : 0;
      _isNavigating = false;
      _currentStepIndex = 0;
      _routeSteps = [];
    });
    _fetchRoute();
  }

  IconData _maneuverIcon(String type, String? modifier) {
    switch (type) {
      case 'depart':
        return Icons.trip_origin;
      case 'arrive':
        return Icons.flag;
      case 'turn':
        if (modifier == 'right') return Icons.turn_right;
        if (modifier == 'left') return Icons.turn_left;
        if (modifier == 'sharp right') return Icons.turn_sharp_right;
        if (modifier == 'sharp left') return Icons.turn_sharp_left;
        if (modifier == 'slight right') return Icons.turn_slight_right;
        if (modifier == 'slight left') return Icons.turn_slight_left;
        if (modifier == 'uturn') return Icons.u_turn_left;
        return Icons.turn_right;
      case 'merge':
        return Icons.merge;
      case 'ramp':
        return Icons.ramp_right;
      case 'fork':
        return Icons.fork_right;
      case 'roundabout':
      case 'rotary':
        return Icons.rounded_corner;
      case 'continue':
      case 'new name':
        return Icons.straight;
      case 'end of road':
        return Icons.turn_right;
      default:
        return Icons.navigation;
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_driverLocation != null) {
      markers.add(
        Marker(
          point: LatLng(_driverLocation!.lat, _driverLocation!.lng),
          width: 44,
          height: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tài xế',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.local_shipping, color: AppColors.primaryLight, size: 24),
            ],
          ),
        ),
      );
    }

    if (_storeLocation != null) {
      markers.add(
        Marker(
          point: _storeLocation!,
          width: 44,
          height: 52,
          child: GestureDetector(
            onTap: () => _showDirectionSheet(true),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Cửa hàng',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.location_on, color: AppColors.warning, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    if (_deliveryLocation != null) {
      markers.add(
        Marker(
          point: _deliveryLocation!,
          width: 44,
          height: 52,
          child: GestureDetector(
            onTap: () => _showDirectionSheet(false),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Giao hàng',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.location_on, color: AppColors.success, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showDirectionSheet(bool isStore) {
    final l10n = AppLocalizations.of(context)!;
    final destination = isStore ? _storeLocation : _deliveryLocation;
    final title = isStore ? widget.order.storeName : widget.order.deliveryAddress;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isStore ? 'Cửa hàng' : 'Địa chỉ giao hàng',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 56, height: 56,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (destination != null) _openExternalNavigation(destination);
                    },
                    icon: const Icon(Icons.open_in_new, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: isStore ? AppColors.warning : AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    tooltip: 'Mở bản đồ',
                  ),
                ),
                SizedBox(
                  width: 56, height: 56,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (destination != null) {
                        setState(() {
                          _currentRoute = isStore ? 0 : 1;
                          _isNavigating = false;
                          _currentStepIndex = 0;
                        });
                        _fetchRoute().then((_) => _startNavigation());
                      }
                    },
                    icon: const Icon(Icons.navigation, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    tooltip: l10n.navigate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts?.stop();
    _tts = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasStore = _storeLocation != null;
    final hasDelivery = _deliveryLocation != null;
    final hasBoth = hasStore && hasDelivery;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.map),
        actions: [
          if (hasBoth)
            TextButton.icon(
              onPressed: _toggleRoute,
              icon: const Icon(Icons.swap_horiz, size: 20),
              label: Text(
                _currentRoute == 0 ? '→ Cửa hàng' : '→ Giao hàng',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _storeLocation ?? _deliveryLocation ?? _defaultCenter,
              initialZoom: 15,
              onMapReady: () {
                if (hasBoth) _fetchRoute();
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _autoRecenter = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fe_food_go_driver',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.primaryLight,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers().toList()),
            ],
          ),

          if (_isLoadingRoute)
            Positioned(
              top: 16, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text('Đang tải tuyến đường...',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            right: 16,
            bottom: _isNavigating ? 220 : 180,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'auto_recenter',
                  onPressed: () {
                    setState(() => _autoRecenter = !_autoRecenter);
                    if (_autoRecenter && _driverLocation != null) {
                      _mapController.move(
                        LatLng(_driverLocation!.lat, _driverLocation!.lng),
                        _mapController.camera.zoom,
                      );
                    }
                  },
                  backgroundColor: _autoRecenter ? AppColors.primaryLight : null,
                  child: Icon(
                    _autoRecenter ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _autoRecenter ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fit_bounds',
                  onPressed: () {
                    setState(() => _autoRecenter = false);
                    _fitBounds();
                  },
                  child: const Icon(Icons.fit_screen),
                ),
              ],
            ),
          ),

          if (_isNavigating && _currentInstruction != null)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _buildTurnByTurnPanel(l10n),
            ),

          if (!_isNavigating && !_isLoadingRoute && _routeSteps.isNotEmpty)
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: _buildRouteInfoCard(l10n),
            ),
        ],
      ),
    );
  }

  Widget _buildTurnByTurnPanel(AppLocalizations l10n) {
    final step = _currentStepIndex < _routeSteps.length
        ? _routeSteps[_currentStepIndex]
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    step != null
                        ? _maneuverIcon(step.maneuverType, step.maneuverModifier)
                        : Icons.navigation,
                    color: AppColors.primaryLight,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentInstruction ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (step != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDistance(step.distance),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.straighten,
                  _formatDistance(_remainingDistanceMeters ?? 0),
                  'Còn lại',
                ),
                _buildStatItem(
                  Icons.timer_outlined,
                  _formatDuration(_remainingSeconds ?? 0),
                  'Thời gian',
                ),
                _buildStatItem(
                  Icons.arrow_forward,
                  '${_currentStepIndex + 1}/${_routeSteps.length}',
                  'Chặng',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20, 0, 20, 12 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleMute,
                    icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, size: 18),
                    label: Text(_isMuted ? 'Bật tiếng' : 'Tắt tiếng'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final dest = _currentRoute == 0 ? _deliveryLocation : _storeLocation;
                      if (dest != null) _openExternalNavigation(dest);
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Mở bản đồ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _stopNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  child: const Text('Dừng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryLight, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRouteInfoCard(AppLocalizations l10n) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_storeLocation != null && _deliveryLocation != null) ...[
              Row(
                children: [
                  _buildRouteStep(
                    Icons.store, 'Cửa hàng', widget.order.storeName,
                    AppColors.warning, true,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 2, color: Colors.grey[300])),
                  const SizedBox(width: 8),
                  _buildRouteStep(
                    Icons.home, 'Giao hàng', widget.order.deliveryAddress,
                    AppColors.success, false,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_totalDistanceMeters != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_formatDistance(_totalDistanceMeters!)} • ~${_formatDuration(_remainingSeconds ?? 0)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startNavigation,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Bắt đầu chỉ đường'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _storeLocation != null
                        ? () => _openExternalNavigation(_storeLocation!)
                        : null,
                    icon: const Icon(Icons.store, size: 18),
                    label: Text(l10n.openMaps, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deliveryLocation != null
                        ? () => _openExternalNavigation(_deliveryLocation!)
                        : null,
                    icon: const Icon(Icons.home, size: 18),
                    label: Text(l10n.openMaps, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStep(
    IconData icon, String label, String? value, Color color, bool isFirst,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text(
                  value ?? '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _formatDuration(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return '${h}h ${m}m';
    }
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '$m phút $s giây' : '$m phút';
    }
    return '$seconds giây';
  }
}

class _RouteStep {
  final String instruction;
  final String maneuverType;
  final String? maneuverModifier;
  final double distance;
  final double duration;
  final double lat;
  final double lng;
  final String wayName;

  _RouteStep({
    required this.instruction,
    required this.maneuverType,
    required this.maneuverModifier,
    required this.distance,
    required this.duration,
    required this.lat,
    required this.lng,
    required this.wayName,
  });
}

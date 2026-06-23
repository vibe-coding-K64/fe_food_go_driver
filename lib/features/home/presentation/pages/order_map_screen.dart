import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_mapbox_navigation_plus/flutter_mapbox_navigation_plus.dart';
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

class _OrderMapScreenState extends State<OrderMapScreen> with WidgetsBindingObserver {
  MapBoxNavigationViewController? _controller;

  int _currentRoute = 0;
  LatLng? _storeLocation;
  LatLng? _deliveryLocation;
  final LatLng _defaultCenter = const LatLng(10.762622, 106.660172);

  DriverLocation? _driverLocation;
  String? _driverId;

  bool _isNavigating = false;
  bool _isMuted = false;
  bool _isLoadingRoute = false;
  bool _routeBuilt = false;
  bool _isBuildingRoute = false;
  bool _isDisposed = false;

  double? _totalDistanceMeters;
  double? _remainingDistanceMeters;
  int? _remainingSeconds;
  String? _currentInstruction;
  bool _arrived = false;

  FlutterTts? _tts;
  StreamSubscription<DriverLocation?>? _driverLocationSub;

  WayPoint? _originWayPoint;
  WayPoint? _destinationWayPoint;

  bool _isMapReady = false;

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

    _currentRoute = widget.order.isPickingUp ? 0 : 1;

    _driverId = widget.order.driverId;
    if (_driverId != null) {
      _subscribeDriverLocation();
    }

    _initTts();
    _resolveStoreLocation();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isMapReady && hasBoth) {
        _rebuildRouteIfNeeded();
      }
    }
  }

  bool get hasBoth => _storeLocation != null && _deliveryLocation != null;

  void _rebuildRouteIfNeeded() {
    if (_isBuildingRoute) return;
    if (_controller != null && _originWayPoint != null && _destinationWayPoint != null) {
      _buildRoute();
    }
  }

  MapBoxOptions _buildNavigationOptions(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return MapBoxOptions(
      initialLatitude: _storeLocation?.latitude ?? _deliveryLocation?.latitude ?? _defaultCenter.latitude,
      initialLongitude: _storeLocation?.longitude ?? _deliveryLocation?.longitude ?? _defaultCenter.longitude,
      zoom: 15.0,
      bearing: 0.0,
      tilt: 0.0,
      enableRefresh: true,
      alternatives: false,
      voiceInstructionsEnabled: !_isMuted,
      bannerInstructionsEnabled: true,
      allowsUTurnAtWayPoints: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: false,
      language: 'vi',
      animateBuildRoute: true,
      enableOnMapTapCallback: false,
      longPressDestinationEnabled: false,
      isOptimized: false,
      mapStyleUrlDay: null,
      mapStyleUrlNight: null,
      padding: EdgeInsets.only(
        top: topPadding + 56 + 16,
        left: 16,
        bottom: 300,
        right: 16,
      ),
      showEndOfRouteFeedback: false,
      showReportFeedbackButton: false,
    );
  }

  void _initTts() async {
    _tts = FlutterTts();
    await _tts!.setLanguage('vi-VN');
    await _tts!.setSpeechRate(0.52);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
  }

  void _subscribeDriverLocation() {
    final homeRepo = GetIt.I<HomeRepository>();
    _driverLocationSub = homeRepo.watchDriverLocation(_driverId!).listen((location) {
      if (!mounted) return;

      final wasNull = _driverLocation == null;
      setState(() => _driverLocation = location);

      // Rebuild route khi nhan duoc vi tri driver lan dau
      // (truoc do phai dung vi tri store/delivery tam thoi)
      if (wasNull && location != null && hasBoth && _isMapReady) {
        _updateWayPointsInternal('Vị trí hiện tại');
        _buildRoute();
      }
    });
  }

  void _resolveStoreLocation() {
    if (_storeLocation != null && _deliveryLocation != null) {
      _updateWayPointsInternal('Vị trí hiện tại');
      _buildRoute();
    } else if (widget.order.storeAddress != null && widget.order.storeAddress!.isNotEmpty) {
      _geocodeStoreLocation();
    }
  }

  Future<void> _geocodeStoreLocation() async {
    final address = widget.order.storeAddress;
    if (address == null || address.isEmpty) return;

    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent('$address, Vietnam')}&format=json&limit=1');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'FoodGoDriver/1.0');
      final response = await request.close();
      final body = await response.transform(const SystemEncoding().decoder).join();

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(body) as List<dynamic>;
        if (results.isNotEmpty && mounted) {
          final lat = double.tryParse(results[0]['lat'].toString());
          final lon = double.tryParse(results[0]['lon'].toString());
          if (lat != null && lon != null) {
            setState(() => _storeLocation = LatLng(lat, lon));
            if (_deliveryLocation != null) {
              _updateWayPointsInternal('Vị trí hiện tại');
              _buildRoute();
            }
          }
        }
      }
      client.close();
    } catch (e) {
      debugPrint('[OrderMapScreen] Geocode error: $e');
    }
  }

  void _updateWayPointsInternal(String currentLocationName) {
    if (_storeLocation == null || _deliveryLocation == null) return;

    final destName = _currentRoute == 0 ? widget.order.storeName : widget.order.deliveryAddress;

    double originLat;
    double originLng;

    if (_driverLocation != null) {
      originLat = _driverLocation!.lat;
      originLng = _driverLocation!.lng;
    } else {
      originLat = _currentRoute == 0 ? _deliveryLocation!.latitude : _storeLocation!.latitude;
      originLng = _currentRoute == 0 ? _deliveryLocation!.longitude : _storeLocation!.longitude;
    }

    _originWayPoint = WayPoint(
      name: currentLocationName,
      latitude: originLat,
      longitude: originLng,
    );
    _destinationWayPoint = WayPoint(
      name: destName,
      latitude: _currentRoute == 0 ? _storeLocation!.latitude : _deliveryLocation!.latitude,
      longitude: _currentRoute == 0 ? _storeLocation!.longitude : _deliveryLocation!.longitude,
    );
  }

  void _buildRoute() async {
    if (_originWayPoint == null || _destinationWayPoint == null) return;
    if (_isBuildingRoute) return;
    _isBuildingRoute = true;

    setState(() => _isLoadingRoute = true);

    debugPrint('[OrderMapScreen] Building route with Mapbox');

    try {
      await _controller?.buildRoute(
        wayPoints: [_originWayPoint!, _destinationWayPoint!],
        options: MapBoxOptions(
          mode: MapBoxNavigationMode.drivingWithTraffic,
          language: 'vi',
          units: VoiceUnits.metric,
          enableRefresh: true,
        ),
      );
    } catch (e) {
      debugPrint('[OrderMapScreen] Build route error: $e');
      setState(() => _isLoadingRoute = false);
    } finally {
      _isBuildingRoute = false;
    }
  }

  void _startNavigation(AppLocalizations l10n) {
    _controller?.startNavigation();
    setState(() => _isNavigating = true);
    if (!_isMuted) {
      _speak(l10n.startNavigation);
    }
  }

  void _stopNavigation() {
    _controller?.finishNavigation();
    setState(() => _isNavigating = false);
    _tts?.stop();
  }

  void _toggleRoute(AppLocalizations l10n) {
    setState(() {
      _currentRoute = _currentRoute == 0 ? 1 : 0;
      _isNavigating = false;
      _routeBuilt = false;
      _arrived = false;
      _remainingDistanceMeters = null;
      _remainingSeconds = null;
      _currentInstruction = null;
    });
    _updateWayPointsInternal(l10n.currentLocation);
    _buildRoute();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      _tts?.stop();
    }
  }

  Future<void> _openExternalNavigation(LatLng destination) async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {}

    final destLat = destination.latitude.toString();
    final destLng = destination.longitude.toString();
    final oriLat = position?.latitude.toString() ?? _driverLocation?.lat.toString() ?? '10.7769';
    final oriLng = position?.longitude.toString() ?? _driverLocation?.lng.toString() ?? '106.7009';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${Uri.encodeComponent(oriLat)},${Uri.encodeComponent(oriLng)}'
      '&destination=${Uri.encodeComponent(destLat)},${Uri.encodeComponent(destLng)}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty || _tts == null) return;
    await _tts!.speak(text);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _driverLocationSub?.cancel();
    _tts?.stop();

    if (_controller != null) {
      _controller!.finishNavigation();
      _controller = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.map),
        actions: [
          if (hasBoth)
            TextButton.icon(
              onPressed: () => _toggleRoute(l10n),
              icon: const Icon(Icons.swap_horiz, size: 20),
              label: Text(
                _currentRoute == 0 ? l10n.routeToStore : l10n.routeToDelivery,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          if (_isNavigating)
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
              tooltip: _isMuted ? l10n.enableSound : l10n.disableSound,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return MapBoxNavigationView(
                      options: _buildNavigationOptions(context),
                      onRouteEvent: (e) => _onRouteEvent(e, l10n),
                      onCreated: (MapBoxNavigationViewController controller) async {
                        if (!mounted || _controller != null) return;
                        _controller = controller;
                        await _controller!.initialize();
                        _isMapReady = true;
                        if (hasBoth && mounted) {
                          _buildRoute();
                        }
                      },
                    );
                  },
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.calculatingRoute,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (!_isNavigating && _routeBuilt && _remainingDistanceMeters != null)
                  Positioned(
                    left: 16, right: 16, bottom: 16,
                    child: _buildRouteInfoCard(l10n),
                  ),

                if (_isNavigating && _remainingDistanceMeters != null)
                  Positioned(
                    left: 16, right: 16, bottom: 16,
                    child: _buildNavigationPanel(l10n),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !_isNavigating && _routeBuilt
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'start_nav',
                  onPressed: () => _startNavigation(l10n),
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.navigation, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'open_external',
                  onPressed: () {
                    final dest = _currentRoute == 0 ? _storeLocation : _deliveryLocation;
                    if (dest != null) _openExternalNavigation(dest);
                  },
                  child: const Icon(Icons.open_in_new),
                ),
              ],
            )
          : null,
    );
  }

  void _onRouteEvent(RouteEvent e, AppLocalizations l10n) async {
    debugPrint('[OrderMapScreen] Route event: ${e.eventType}');
    if (_isDisposed) return;

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        _arrived = progressEvent.arrived ?? false;

        try {
          final distRem = await _controller!.distanceRemaining;
          final durRem = await _controller!.durationRemaining;

          setState(() {
            _remainingDistanceMeters = distRem;
            _remainingSeconds = durRem.toInt();
            _currentInstruction = progressEvent.currentStepInstruction;
          });

          if (progressEvent.currentStepInstruction != null &&
              progressEvent.currentStepInstruction!.isNotEmpty &&
              !_isMuted) {
            _speak(progressEvent.currentStepInstruction!);
          }
        } catch (_) {}
        break;

      case MapBoxEvent.route_building:
        setState(() => _isLoadingRoute = true);
        break;

      case MapBoxEvent.route_built:
        try {
          final distTotal = await _controller!.distanceRemaining;
          final durTotal = await _controller!.durationRemaining;
          setState(() {
            _isLoadingRoute = false;
            _routeBuilt = true;
            _totalDistanceMeters = distTotal;
            _remainingDistanceMeters = distTotal;
            _remainingSeconds = durTotal.toInt();
          });

          if (!_isMuted) {
            final prefix = _currentRoute == 0 ? l10n.navigatingToStore : l10n.navigatingToDelivery;
            _speak('$prefix Khoảng cách ${_formatDistance(_totalDistanceMeters ?? 0, l10n)}, thời gian ${_formatDuration(_remainingSeconds ?? 0, l10n)}.');
          }
        } catch (_) {}
        break;

      case MapBoxEvent.route_build_failed:
        setState(() {
          _isLoadingRoute = false;
          _routeBuilt = false;
        });
        break;

      case MapBoxEvent.navigation_running:
        setState(() => _isNavigating = true);
        break;

      case MapBoxEvent.on_arrival:
        _speak(l10n.youHaveArrived);
        setState(() {
          _isNavigating = false;
          _arrived = true;
        });
        break;

      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        _controller?.finishNavigation();
        setState(() {
          _isNavigating = false;
          _routeBuilt = false;
        });
        break;

      default:
        break;
    }
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
                    Icons.store, l10n.navigateToStore, widget.order.storeName,
                    AppColors.warning, true,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 2, color: Colors.grey[300])),
                  const SizedBox(width: 8),
                  _buildRouteStep(
                    Icons.home, l10n.navigateToDelivery, widget.order.deliveryAddress,
                    AppColors.success, false,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_totalDistanceMeters != null && _remainingSeconds != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_formatDistance(_totalDistanceMeters!, l10n)} ~ ${_formatDuration(_remainingSeconds!, l10n)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startNavigation(l10n),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: Text(l10n.startNavigationButton),
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

  Widget _buildNavigationPanel(AppLocalizations l10n) {
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
                    _arrived ? Icons.flag : Icons.navigation,
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
                        _arrived ? l10n.arrived : (_currentInstruction ?? l10n.onTheWay),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentRoute == 0 ? l10n.navigatingToStoreDirection : l10n.navigatingToDeliveryDirection,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
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
                  _formatDistance(_remainingDistanceMeters ?? 0, l10n),
                  l10n.remaining,
                ),
                _buildStatItem(
                  Icons.timer_outlined,
                  _formatDuration(_remainingSeconds ?? 0, l10n),
                  l10n.duration,
                ),
                _buildStatItem(
                  Icons.local_shipping,
                  _arrived ? l10n.hasArrived : l10n.isOnTheWay,
                  l10n.status,
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
                    label: Text(_isMuted ? l10n.enableSound : l10n.disableSound),
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
                      final dest = _currentRoute == 0 ? _storeLocation : _deliveryLocation;
                      if (dest != null) _openExternalNavigation(dest);
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.openMap),
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
                  child: Text(l10n.stop),
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

  String _formatDistance(double meters, AppLocalizations l10n) {
    if (meters >= 1000) {
      return l10n.distanceKm((meters / 1000).toStringAsFixed(1));
    }
    return l10n.m(meters.toInt().toString());
  }

  String _formatDuration(int seconds, AppLocalizations l10n) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return '${h}h ${m}m';
    }
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      return l10n.minutesShort(m);
    }
    return l10n.secondsShort(seconds);
  }
}

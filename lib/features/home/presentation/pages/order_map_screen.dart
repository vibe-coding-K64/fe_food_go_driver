import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  LatLng _defaultCenter = const LatLng(10.762622, 106.660172);

  DriverLocation? _driverLocation;
  String? _driverId;

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

    _driverId = widget.order.driverId;
    if (_driverId != null) {
      _subscribeDriverLocation();
    }

    if (_storeLocation != null && _deliveryLocation != null) {
      _fetchRoute();
    }
  }

  void _subscribeDriverLocation() {
    final homeRepo = GetIt.I<HomeRepository>();
    homeRepo.watchDriverLocation(_driverId!).listen((location) {
      if (mounted) {
        setState(() => _driverLocation = location);
      }
    });
  }


  Future<void> _fetchRoute() async {
    if (_storeLocation == null || _deliveryLocation == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final origin = _currentRoute == 0 ? _storeLocation! : _deliveryLocation!;
      final dest = _currentRoute == 0 ? _deliveryLocation! : _storeLocation!;

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=polyline',
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['code'] == 'Ok') {
          final geometry = decoded['routes'][0]['geometry'] as String;
          final points = _decodePolyline(geometry);

          setState(() {
            _routePoints = points;
            _isLoadingRoute = false;
          });

          _fitBounds();
          return;
        }
      }
    } catch (e) {
      debugPrint('[OrderMapScreen] Route fetch error: $e');
    }

    setState(() => _isLoadingRoute = false);
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
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  Future<void> _openNavigation(LatLng destination) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=osrm_car'
      '&route=${destination.latitude},${destination.longitude}#map=16/${destination.latitude}/${destination.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _toggleRoute() {
    setState(() => _currentRoute = _currentRoute == 0 ? 1 : 0);
    _fetchRoute();
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tài xế',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.local_shipping, color: AppColors.primaryLight, size: 28),
            ],
          ),
        ),
      );
    }

    if (_storeLocation != null) {
      markers.add(
        Marker(
          point: _storeLocation!,
          width: 40,
          height: 48,
          child: GestureDetector(
            onTap: () => _showDirectionSheet(true),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Cửa hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.location_on, color: AppColors.warning, size: 28),
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
          width: 40,
          height: 48,
          child: GestureDetector(
            onTap: () => _showDirectionSheet(false),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Giao hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.location_on, color: AppColors.success, size: 28),
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
          20,
          20,
          20,
          20 + MediaQuery.of(context).padding.bottom,
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
              width: 40,
              height: 4,
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
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (destination != null) _openNavigation(destination);
                },
                icon: const Icon(Icons.navigation),
                label: Text(l10n.navigate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStore ? AppColors.warning : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              initialZoom: 14,
              onMapReady: () {
                if (hasBoth) _fetchRoute();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
              top: 16,
              left: 0,
              right: 0,
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
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang tải tuyến đường...',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
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
                  onPressed: _fitBounds,
                  child: const Icon(Icons.fit_screen),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildRouteInfoCard(l10n),
          ),
        ],
      ),
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
                    Icons.store,
                    'Cửa hàng',
                    widget.order.storeName,
                    AppColors.warning,
                    true,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildRouteStep(
                    Icons.home,
                    'Giao hàng',
                    widget.order.deliveryAddress,
                    AppColors.success,
                    false,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _storeLocation != null
                        ? () => _openNavigation(_storeLocation!)
                        : null,
                    icon: const Icon(Icons.store, size: 18),
                    label: Text(l10n.openMaps, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deliveryLocation != null
                        ? () => _openNavigation(_deliveryLocation!)
                        : null,
                    icon: const Icon(Icons.home, size: 18),
                    label: Text(l10n.openMaps, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
    IconData icon,
    String label,
    String? value,
    Color color,
    bool isFirst,
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
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  value ?? '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

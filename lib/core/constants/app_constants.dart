class AppConstants {
  AppConstants._();

  static const String appName = 'Food Go Driver';

  // SharedPreferences keys
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'app_locale';
  static const String driverTokenKey = 'driver_token';
  static const String driverRefreshTokenKey = 'driver_refresh_token';
  static const String driverIdKey = 'driver_id';

  // API Base URL
  static const String baseApiUrl = 'https://be-foodgo.canluaz.io.vn/api';
  // static const String baseApiUrl = 'http://localhost:8086/api';

  // Mapbox API Key - get from https://mapbox.com
  // Replace with your actual Mapbox public token (pk.xxx)
  static const String mapboxApiKey = 'YOUR_MAPBOX_PUBLIC_TOKEN';

  // API Endpoints
  static const String driverStatusEndpoint = '/drivers/status';
  static const String driverLocationEndpoint = '/drivers/location';

  // Location settings
  static const int locationUpdateIntervalMs = 10000;
  static const int locationDistanceFilterMeters = 10;
  static const int autoOfflineThresholdSeconds = 60;
  static const int offlineCheckIntervalSeconds = 30;

  // Order status (must match backend DeliveryOrderStatus.java)
  static const int orderStatusPending = 0;      // Chờ xác nhận
  static const int orderStatusWaitingDriver = 1; // Đã nhận đơn, chưa lấy hàng
  static const int orderStatusDelivering = 2;   // Đang giao (đã lấy hàng)
  static const int orderStatusDelivered = 3;   // Hoàn thành
  static const int orderStatusCancelled = 4;   // Đã hủy

  // Driver availability status
  static const int driverAvailableWaiting =
      1; // Online / Chờ đơn (isActive=true, isAvailable=true)
  static const int driverBusyDelivering =
      2; // Nhận đơn / Đang giao (isActive=true, isAvailable=false)
}

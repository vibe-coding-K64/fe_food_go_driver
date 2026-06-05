import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  FCMService();

  static const String _orderChannelId = 'driver_order_alerts';
  static const String _orderChannelName = 'Driver Order Alerts';
  static const String _orderChannelDescription =
      'Alerts for incoming driver order requests';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
        _orderChannelId,
        _orderChannelName,
        description: _orderChannelDescription,
        importance: Importance.max,
        playSound: true,
      );

  bool _isInitialized = false;

  Future<void> initializeLocalNotifications() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_orderChannel);

    _isInitialized = true;
    debugPrint('[FCMService] Local notifications initialized');
  }

  Future<void> showForegroundOrderAlert({
    required String orderId,
    String? title,
    String? body,
  }) async {
    await initializeLocalNotifications();

    final safeTitle =
        title == null || title.trim().isEmpty ? 'Có đơn hàng mới!' : title;
    final safeBody =
        body == null || body.trim().isEmpty
            ? 'Mở ứng dụng để xem và nhận đơn #$orderId'
            : body;

    await _localNotifications.show(
      id: orderId.hashCode,
      title: safeTitle,
      body: safeBody,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _orderChannelId,
          _orderChannelName,
          channelDescription: _orderChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'new_order',
        ),
      ),
      payload: orderId,
    );
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint(
        '[FCMService] getToken - token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}',
      );
      return token;
    } catch (e) {
      debugPrint('[FCMService] getToken error: $e');
      return null;
    }
  }

  Future<void> onTokenRefresh(void Function(String token) onToken) async {
    _messaging.onTokenRefresh.listen((token) {
      debugPrint(
        '[FCMService] onTokenRefresh - new token: ${token.substring(0, 20)}...',
      );
      onToken(token);
    });
  }

  Future<NotificationSettings> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '[FCMService] requestPermission - status: ${settings.authorizationStatus}',
      );
      return settings;
    } catch (e) {
      debugPrint('[FCMService] requestPermission error: $e');
      return NotificationSettings(
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.notSupported,
        authorizationStatus: AuthorizationStatus.notDetermined,
        badge: AppleNotificationSetting.notSupported,
        carPlay: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.notSupported,
        notificationCenter: AppleNotificationSetting.notSupported,
        showPreviews: AppleShowPreviewSetting.always,
        timeSensitive: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.notSupported,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCMService] subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCMService] subscribeToTopic($topic) error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCMService] unsubscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCMService] unsubscribeFromTopic($topic) error: $e');
    }
  }

  void setForegroundMessageHandler(
    Future<void> Function(RemoteMessage message) handler,
  ) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  void setBackgroundMessageHandler(
    Future<void> Function(RemoteMessage message) handler,
  ) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }
}
